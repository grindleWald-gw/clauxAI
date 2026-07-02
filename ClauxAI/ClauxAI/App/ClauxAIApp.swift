//
//  ClauxAIApp.swift
//  ClauxAI
//
//  Created by Yasir Shah on 13/05/2026.
//

import SwiftUI
@main
struct ClauxAIApp: App {
    init () {
        printAllFonts()

        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty {
            APIConfiguration.apiKey = key
        }
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            APIConfiguration.openAIAPIKey = key
        }
        APIConfiguration.bootstrap()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 1150, minHeight: 790)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
