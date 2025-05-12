//
//  KeyManager.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 5/9/25.
//

import Foundation
import Security


/// A manager class responsible for securely handling the encryption key in the Keychain, including retrieving, storing, generating, and validating the encryption key.
class KeyManager {

    /// Keychain query to store and retrieve the encryption key
    static let encryptionKeyKey = "encryptionKeyKeyy"

    
    /// Retrieves the encryption key securely from the Keychain. If the key does not exist, it generates a new key and stores it in the Keychain.
    /// - Returns: The encryption key as a `String`, or `nil` if an error occurs.
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

    /// Generates a new encryption key securely.
    /// - Returns: A Base64-encoded string representation of the new encryption key.
    static func generateEncryptionKey() -> String {
        var key = Data(count: 32)
        _ = key.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
            _ = SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        // Convert the key to a Base64-encoded string (this should result in a 44-character string)
        return key.base64EncodedString()
    }


    /// Stores the given encryption key in the Keychain. If the key already exists, it updates the existing key.
    /// - Parameter key: The encryption key to be stored in the Keychain.
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
    
    
    /// Validates the encryption key to ensure it meets the required length for AES encryption (32 bytes).
    /// - Parameter key: The encryption key to be validated.
    /// - Returns: The decoded `Data` if the key is valid, or `nil` if the key is invalid.
    static func validateEncryptionKey(_ key: String) -> Data? {
        guard let keyData = Data(base64Encoded: key), keyData.count == 32 else {
            print("Invalid key length. Key must be 32 bytes for AES.")
            return nil
        }
        return keyData
    }

}
