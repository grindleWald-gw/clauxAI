//
//  DatabaseManager.swift
//  CL.AI
//
//  Created by Yasir Shah on 04/07/2026.
//

import FirebaseDatabase
import SwiftUI
import Combine

enum RemoteDatabaseKey {
    static let anthropic = "clauxAnthropicKey"
    static let gemini = "geminiKey"
}

final class DatabaseManager: ObservableObject {

    static let shared = DatabaseManager()

    private let database = Database.database().reference()

    @Published private(set) var anthropicKey: String = ""
    @Published private(set) var geminiKey: String = ""

    private init() {}

    func loadAPIKeys() async {
        async let anthropic = fetchString(forKey: RemoteDatabaseKey.anthropic)
        async let gemini = fetchString(forKey: RemoteDatabaseKey.gemini)

        let fetchedAnthropicKey = await anthropic
        let fetchedGeminiKey = await gemini

        await MainActor.run {
            if let fetchedAnthropicKey {
                anthropicKey = fetchedAnthropicKey
            }
            if let fetchedGeminiKey {
                geminiKey = fetchedGeminiKey
            }
            applyKeysToClients()
        }
    }

    func ensureAPIKeysLoaded() async {
        if !ClaudeAPIClient.shared.apiKey.isEmpty { return }
        await loadAPIKeys()
    }

    private func applyKeysToClients() {
        if ClaudeAPIClient.shared.apiKey.isEmpty, !anthropicKey.isEmpty {
            ClaudeAPIClient.shared.apiKey = anthropicKey
        }

        if ClaudeAPIClient.shared.gptApiKey.isEmpty, !geminiKey.isEmpty {
            ClaudeAPIClient.shared.gptApiKey = geminiKey
        }

        if APIConfiguration.openAIAPIKey.isEmpty, !geminiKey.isEmpty {
            APIConfiguration.openAIAPIKey = geminiKey
        }
    }

    private func fetchString(forKey key: String) async -> String? {
        await withCheckedContinuation { continuation in
            database.child(key).observeSingleEvent(of: .value) { snapshot in
                if let value = snapshot.value as? String, !value.isEmpty {
                    continuation.resume(returning: value)
                } else {
                    print("Remote key not found: \(key)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
