//
//  CreditManager.swift
//  CL.AI
//
//  Created by Yasir Shah on 04/07/2026.
//

import Foundation
import Observation

enum CreditFeature {
    case chat
    case bugFixer
    case smartTool
    case course
}

@MainActor
@Observable
final class CreditManager {

    static let shared = CreditManager()

    static let freeChatPromptLimit = 3

    var onRequirePro: (() -> Void)?

    private enum StorageKey {
        static let chatPromptCount = "claux.credits.chatPromptCount"
        static let smartToolFreeUsed = "claux.credits.smartToolFreeUsed"
    }

    private init() {}

    var isPro: Bool {
        PurchaseManager.shared.hasActiveSubscription
    }

    var chatPromptCount: Int {
        get { UserDefaults.standard.integer(forKey: StorageKey.chatPromptCount) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.chatPromptCount) }
    }

    var hasUsedSmartToolFreeGeneration: Bool {
        get { UserDefaults.standard.bool(forKey: StorageKey.smartToolFreeUsed) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.smartToolFreeUsed) }
    }

    var remainingFreeChatPrompts: Int {
        max(0, Self.freeChatPromptLimit - chatPromptCount)
    }

    func canAccess(_ feature: CreditFeature) -> Bool {
        if isPro { return true }

        switch feature {
        case .chat:
            return chatPromptCount < Self.freeChatPromptLimit
        case .bugFixer:
            return false
        case .smartTool:
            return !hasUsedSmartToolFreeGeneration
        case .course:
            return true
        }
    }

    func proRequiredMessage(for feature: CreditFeature) -> String {
        switch feature {
        case .chat:
            return "You've used your 3 free prompts. Upgrade to PRO to continue chatting."
        case .bugFixer:
            return "Bug Fixer is a PRO feature. Upgrade to unlock it."
        case .smartTool:
            return "You've used your free AI tool generation. Upgrade to PRO for unlimited access."
        case .course:
            return ""
        }
    }

    @discardableResult
    func requireAccess(to feature: CreditFeature) -> Bool {
        guard canAccess(feature) else {
            onRequirePro?()
            return false
        }
        return true
    }

    func recordChatPrompt() {
        guard !isPro else { return }
        chatPromptCount += 1
    }

    func recordSmartToolGeneration() {
        guard !isPro else { return }
        hasUsedSmartToolFreeGeneration = true
    }
}
