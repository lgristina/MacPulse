//
//  KeyManager.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 5/9/25.
//

import Foundation
import Security

class KeyManager {

    // Keychain query to store and retrieve the encryption key
    static let encryptionKeyKey = "encryptionKey"

    // Method to retrieve the encryption key securely from the Keychain
    static func getEncryptionKey() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: encryptionKeyKey,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let data = item as? Data, let key = String(data: data, encoding: .utf8) {
            return key
        } else if status == errSecItemNotFound {
            let newKey = generateEncryptionKey()
            storeEncryptionKey(newKey)
            return newKey
        } else {
            print("Error retrieving encryption key: \(status)")
            return nil
        }
    }


    // Method to generate a new encryption key securely
    static func generateEncryptionKey() -> String {
        var key = Data(count: 32)
        _ = key.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
            _ = SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        // Convert the key to a Base64-encoded string (this should result in a 44-character string)
        return key.base64EncodedString()
    }



    // Method to store the encryption key in the Keychain
    static func storeEncryptionKey(_ key: String) {
        let keyData = key.data(using: .utf8)!

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: encryptionKeyKey,
            kSecValueData: keyData
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            print("Encryption key stored successfully.")
        } else if status == errSecDuplicateItem {
            // If the key already exists, update it
            let updateQuery: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: encryptionKeyKey
            ]
            let attributesToUpdate: [CFString: Any] = [
                kSecValueData: keyData
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus == errSecSuccess {
                print("Encryption key updated successfully.")
            } else {
                print("Error updating encryption key: \(updateStatus)")
            }
        } else {
            print("Error storing encryption key: \(status)")
        }
    }
}
