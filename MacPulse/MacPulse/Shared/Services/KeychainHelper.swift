//
//  KeychainHelper.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 5/7/25.
//

import Foundation
import Security
import CryptoKit

struct KeychainHelper {
    static let service = "com.yourcompany.macpulse"

    static func loadKey(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess else {
            print("Failed to load key with status: \(status)")
            return nil
        }

        return dataTypeRef as? Data
    }

    static func saveKey(_ key: SymmetricKey, forKey keyName: String) {
        let keyData = key.withUnsafeBytes { Data($0) }

        // First delete if it exists
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyName,
            kSecAttrService as String: service
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Then add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyName,
            kSecAttrService as String: service,
            kSecValueData as String: keyData
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status != errSecSuccess {
            print("Failed to save key with status: \(status)")
        }
    }
}
