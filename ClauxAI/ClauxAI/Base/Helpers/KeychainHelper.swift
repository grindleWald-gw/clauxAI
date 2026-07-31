//
//  KeychainHelper.swift
//  CL.AI
//
//  Created by Yasir Shah on 04/07/2026.
//


import Foundation
import Security

enum KeychainHelper {

    // MARK: - Save Int
    static func setInt(_ value: Int, forKey key: String) {
        let data = withUnsafeBytes(of: value) { Data($0) }
        save(data: data, forKey: key)
    }

    // MARK: - Get Int
    static func getInt(forKey key: String) -> Int? {
        guard let data = readData(forKey: key) else { return nil }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }

    // MARK: - Save Data
    static func save(data: Data, forKey key: String) {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        // Delete existing value if present
        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)

        if status != errSecSuccess {
            assertionFailure("Keychain save failed: \(status)")
        }
    }

    // MARK: - Read Data
    static func readData(forKey key: String) -> Data? {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    // MARK: - Delete
    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
