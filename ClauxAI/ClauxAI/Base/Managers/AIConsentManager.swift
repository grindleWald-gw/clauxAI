//
//  AIConsentManager.swift
//  CL.AI
//
//  Created by Yasir Shah on 04/07/2026.
//

import Foundation
import Observation

enum AIConsentManager {
    private static let key = "CL.AI.HasAgreedAIConsent"

    static var hasAgreed: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func setAgreed() {
        UserDefaults.standard.set(true, forKey: key)
    }
}

struct AIConsentRequest: Identifiable {
    let id = UUID()
}

@MainActor
@Observable
final class AIConsentPresenter {

    static let shared = AIConsentPresenter()

    var activeRequest: AIConsentRequest?

    private var pendingAction: (() -> Void)?

    private init() {}

    func runAfterConsentIfNeeded(_ action: @escaping () -> Void) {
        if AIConsentManager.hasAgreed {
            action()
            return
        }

        pendingAction = action
        activeRequest = AIConsentRequest()
    }

    func agreeAndContinue() {
        AIConsentManager.setAgreed()

        let action = pendingAction
        pendingAction = nil
        activeRequest = nil
        action?()
    }

    func cancelPresentation() {
        pendingAction = nil
        activeRequest = nil
    }
}
