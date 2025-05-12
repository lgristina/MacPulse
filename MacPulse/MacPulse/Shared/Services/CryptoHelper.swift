//
//  CryptoHelper.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 5/7/25.
//

import Foundation
import CryptoKit

/// A helper class that provides encryption and decryption functionality
/// using the AES-GCM algorithm and a symmetric key.
class CryptoHelper {
    
    /// Encrypts a given string using AES-GCM encryption and a provided key.
    /// - Parameters:
    ///   - string: The string to encrypt.
    ///   - keyString: The Base64-encoded encryption key used to encrypt the string.
    /// - Throws: Throws an error if encryption fails, such as when the key is invalid or encryption fails.
    /// - Returns: The Base64-encoded encrypted string.
    static func encrypt(_ string: String, with keyString: String) throws -> String {
        // Retrieve the encryption key securely from Keychain
        guard let encryptionKey = KeyManager.getEncryptionKey() else {
            throw NSError(domain: "CryptoHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve encryption key"])
        }

        // Decode the Base64 key from the provided string
        guard let keyData = Data(base64Encoded: keyString) else {
            throw NSError(domain: "CryptoHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid key"])
        }

        // Log key decoding status
        LogManager.shared.log(.dataPersistence, level: .low, "🔑 Key decoded successfully: \(keyData)")

        // Convert the decoded key to a SymmetricKey for AES-GCM encryption
        let symmetricKey = SymmetricKey(data: keyData)

        // Convert the string to Data to be encrypted
        let dataToEncrypt = Data(string.utf8)
        LogManager.shared.log(.dataPersistence, level: .low, "📄 String converted to data: \(dataToEncrypt.count) bytes")
        
        // Encrypt data using AES-GCM
        LogManager.shared.log(.dataPersistence, level: .low, "🔐 Starting encryption...")
        let sealedBox = try AES.GCM.seal(dataToEncrypt, using: symmetricKey)
        
        // Combine the encrypted data and return the Base64-encoded result
        if let combined = sealedBox.combined {
            LogManager.shared.log(.dataPersistence, level: .medium, "🔐 Encryption successful.")
            return combined.base64EncodedString()
        } else {
            LogManager.shared.log(.dataPersistence, level: .high, "⚠️ Encryption failed, combined data is nil.")
            return ""
        }
    }

    /// Decrypts a given encrypted string using AES-GCM decryption and a provided symmetric key.
    /// - Parameters:
    ///   - string: The Base64-encoded encrypted string to decrypt.
    ///   - key: The symmetric key used for decryption.
    /// - Returns: The decrypted string if successful, or nil if decryption fails.
    static func decrypt(_ string: String, with key: SymmetricKey) -> String? {
        // Convert the Base64-encoded encrypted string to Data
        guard let data = Data(base64Encoded: string),
              let sealedBox = try? AES.GCM.SealedBox(combined: data),
              let decryptedData = try? AES.GCM.open(sealedBox, using: key) else {
            return nil
        }
        
        // Convert decrypted data back to string
        return String(data: decryptedData, encoding: .utf8)
    }
}
