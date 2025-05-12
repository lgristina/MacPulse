//
//  KeychainHelper.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 5/7/25.
//

import Foundation
import Security
import CryptoKit

/// A helper struct to interact with the iOS/macOS Keychain for securely storing and retrieving sensitive data.
struct KeychainHelper {
    
    /// The service identifier for the Keychain items.
    static let service = "com.yourcompany.macpulse"
    
    /// Loads a key from the Keychain.
    /// - Parameter key: The name of the key to load.
    /// - Returns: The key data if successful, or nil if the key is not found or an error occurs.
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

        // Check if the key was successfully loaded
        guard status == errSecSuccess else {
            LogManager.shared.log(.dataPersistence, level: .low, "Failed to load key '\(key)' with status: \(status)")
            return nil
        }
        
        LogManager.shared.log(.dataPersistence, level: .high, "Successfully loaded key '\(key)' from Keychain.")
        
        // Return the data if successfully loaded
        return dataTypeRef as? Data
    }

    /// Saves a symmetric encryption key to the Keychain.
    /// - Parameters:
    ///   - key: The `SymmetricKey` to save.
    ///   - keyName: The name of the key under which it will be stored in the Keychain.
    static func saveKey(_ key: SymmetricKey, forKey keyName: String) {
        // Convert SymmetricKey to Data
        let keyData = key.withUnsafeBytes { Data($0) }

        // Delete any existing key with the same name
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyName,
            kSecAttrService as String: service
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        LogManager.shared.log(.dataPersistence, level: .medium, "Deleted existing key (if any) for '\(keyName)'.")

        // Add the new key to the Keychain
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyName,
            kSecAttrService as String: service,
            kSecValueData as String: keyData
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if status != errSecSuccess {
            LogManager.shared.log(.dataPersistence, level: .low, "Failed to save key '\(keyName)' with status: \(status)")
        } else {
            LogManager.shared.log(.dataPersistence, level: .high, "Successfully saved key '\(keyName)' to Keychain.")
        }
    }
}
