//
//  ReviewPromptManager.swift
//  CL.AI
//

import Foundation
import Observation

/// Drives the App Store rating/review prompt per policy:
/// - After the first successful chat message or Smart Tool generation.
/// - On every 3rd app launch.
@MainActor
@Observable
final class ReviewPromptManager {

    static let shared = ReviewPromptManager()

    /// Wired once by RootView.onAppear to SwiftUI's `@Environment(\.requestReview)` action —
    /// StoreKit's review action only works from a View's environment, not from this manager.
    var requestReview: (() -> Void)?

    private enum StorageKey {
        static let launchCount = "claux.review.launchCount"
        static let hasPromptedForFirstUse = "claux.review.hasPromptedForFirstUse"
    }

    private init() {}

    private var launchCount: Int {
        get { UserDefaults.standard.integer(forKey: StorageKey.launchCount) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.launchCount) }
    }

    private var hasPromptedForFirstUse: Bool {
        get { UserDefaults.standard.bool(forKey: StorageKey.hasPromptedForFirstUse) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.hasPromptedForFirstUse) }
    }

    /// Call once per process launch (from `CL.AIApp.init`), before `requestReview` is wired.
    func recordAppLaunch() {
        launchCount += 1
    }

    /// Call once `requestReview` is wired and a window is on screen (from `RootView.onAppear`).
    /// Fires on the 3rd, 6th, 9th... launch.
    func maybeRequestReviewForLaunch() {
        guard launchCount > 0, launchCount % 3 == 0 else { return }
        requestReview?()
    }

    /// Call after the first successful chat message or Smart Tool generation completes.
    /// Only ever fires once, regardless of how many times it's called afterward.
    func recordFirstSuccessfulUse() {
        guard !hasPromptedForFirstUse else { return }
        hasPromptedForFirstUse = true
        requestReview?()
    }
}
