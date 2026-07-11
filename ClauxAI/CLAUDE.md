# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

ClauxAI is a **macOS** SwiftUI app (uses AppKit, StoreKit, `.windowStyle(.hiddenTitleBar)` — not iOS despite the app name). It's an AI assistant app wrapping Anthropic's Claude API, with a chat home screen, a bug-fixer tool, a suite of "Smart Tools" (legal letter writer, NDA generator, contract reviewer, tax helper, etc.), and a "Learn with Claux" tutoring feature. There is a single Xcode target (`ClauxAI`, product type `.application`) and no test target.

## Build & run

Build/run only via Xcode (`ClauxAI.xcodeproj`, scheme `ClauxAI`) or `xcodebuild`:

```bash
xcodebuild -project ClauxAI.xcodeproj -scheme ClauxAI -configuration Debug build
```

There is no test target in this project — do not try to invoke `xcodebuild test`.

Dependencies are managed via Swift Package Manager (Xcode-integrated, no `Package.swift` at the repo root) — currently just `firebase-ios-sdk` (Analytics, AppCheck, Core, Crashlytics, RemoteConfig, Database).

Deployment target: macOS 14.6 (project) / 15.7 (one build config) — check `MACOSX_DEPLOYMENT_TARGET` in `project.pbxproj` before relying on newer API availability.

## API keys

Anthropic/OpenAI keys are **not** hardcoded. Resolution order:
1. `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` env vars (set in the Xcode scheme) — read once at launch in `ClauxAIApp.init()`.
2. Firebase Realtime Database (`clauxAnthropicKey`, `geminiKey` — see `RemoteDatabaseKey` in `DatabaseManager.swift`), fetched lazily via `DatabaseManager.shared.ensureAPIKeysLoaded()` / `loadAPIKeys()` and applied through `APIConfiguration.bootstrap()`.

The "OpenAI" client is in practice fed the Firebase `geminiKey` for dual-mode responses — don't assume the key name matches the provider it's routed to.

## Architecture

**Navigation** is a hand-rolled enum-driven state machine, not `NavigationStack`. `RootView` owns `@State private var screen: AppScreen` (`Core/Screens/RootView/Model/AppScreen.swift`) and switches over it in a big `@ViewBuilder` to pick the detail view; the left `SidebarView` sets a separate `SidebarDestination` and calls back into `RootView.handleSidebarSelection`. Sub-screens (e.g. every Smart Tool) take an `onBack: () -> Void` closure that resets `screen` back to `.smartTools`/`.home` rather than using a navigation stack or coordinator object.

**API layer** — three-file stack under `Base/Constants/`:
- `ClaudeAPI.swift` — low-level `ClaudeAPIClient`, a fairly complete Anthropic `/v1/messages` wrapper (sync, streaming via SSE, batches, model listing). Generic/reusable, not Claux-specific.
- `OpenAIAPI.swift` — equivalent low-level client for OpenAI chat completions (used only for "dual mode", i.e. showing a Claude response and a GPT response side by side).
- `ClauxAPIService.swift` — the app-facing layer (`@MainActor` singleton `ClauxAPIService.shared`). Maps each feature (chat, bug fixer, each Smart Tool, Learn tutor) to a system prompt (`APIConstants.swift` → `ClauxToolPrompts`) and a typed `*Input` struct, then calls down into `ClaudeAPIClient`/`OpenAIAPIClient`. **When adding a new AI-backed feature, add it here**: a `ClauxFeature` case, a system prompt in `ClauxToolPrompts`, an `*Input` struct, and a `generate*`/`send*` method — follow the existing Smart Tool methods as the template.

**Managers** (`Base/Managers/`, mostly `@MainActor @Observable` singletons via `.shared`):
- `DatabaseManager` — Firebase Realtime Database key fetching (see API keys above).
- `PurchaseManager` — StoreKit 2 subscriptions (`ProductsCore`: weekly/monthly/yearly/lifetime), entitlement refresh, transaction listening. `CreditManager.isPro` reads `PurchaseManager.shared.hasActiveSubscription`.
- `CreditManager` — free-tier gating (3 free chat prompts, one free Smart Tool generation, Bug Fixer is PRO-only). `requireAccess(to:)` is the gate check; screens call it before dispatching a request and fire `onRequirePro` (wired to show `PremiumView`) on denial.
- `AIConsentManager`/`AIConsentPresenter` — one-time AI-usage consent gate. Wrap any new user-initiated AI call in `AIConsentPresenter.shared.runAfterConsentIfNeeded { ... }` before checking credits/dispatching, matching the pattern in `RootView.handleSidebarSelection`/`HomeView`'s `onSubmit`.

**Screens** live under `Core/Screens/<Feature>/`, generally split into `Model/` and `View/` subfolders (not universally — some simpler tools are a single file). The dozen Smart Tools under `SmartToolsScreens/View/ToolsRow{One,Two,Three}/` all follow the same shape: a form of labeled fields → "Generate" button → result sheet, calling one `ClauxAPIService` method and gating on `CreditManager`/`AIConsentPresenter` first.

**Styling**: no asset-catalog colors for the core palette — `Color+Ext.swift` defines the app palette as hex literals (`Color.appMainbg`, `.appOrange`, `.appStroke`, etc.) plus a `Color(hex:)` initializer. Fonts are bundled SF Pro Display `.otf` files (`Base/Resources/Fonts/`) exposed via `Font+Ext.swift`. Reuse these rather than introducing new ad hoc colors/fonts or asset-catalog colors for UI chrome.
