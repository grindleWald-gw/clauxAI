//
//  CL.AIApp.swift
//  CL.AI
//
//  Created by Yasir Shah on 13/05/2026.
//

import SwiftUI
import FirebaseCore

@main
struct CLAIApp: App {
    init () {
        printAllFonts()
        FirebaseApp.configure()
        ReviewPromptManager.shared.recordAppLaunch()

        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty {
            APIConfiguration.apiKey = key
        }
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            APIConfiguration.openAIAPIKey = key
        }
    }

    var body: some Scene {
        WindowGroup {
            AppLaunchView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}
