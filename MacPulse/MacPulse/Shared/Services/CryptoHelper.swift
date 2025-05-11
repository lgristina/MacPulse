//
//  CryptoHelper.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 5/7/25.
//

import Foundation
import CryptoKit
import CryptoKit

class CryptoHelper {
    static func encrypt(_ string: String, with keyString: String) throws -> String {
        // Retrieve the encryption key securely from Keychain
        guard let encryptionKey = KeyManager.getEncryptionKey() else {
            throw NSError(domain: "CryptoHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve encryption key"])
        }

        // Decode the Base64 key from the provided string
        guard let keyData = Data(base64Encoded: keyString) else {
            throw NSError(domain: "CryptoHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid key"])
        }

        LogManager.shared.log(.dataPersistence, level: .low, "🔑 Key decoded successfully: \(keyData)")
        
        let symmetricKey = SymmetricKey(data: keyData)

        // Convert the string to Data
        let dataToEncrypt = Data(string.utf8)
        LogManager.shared.log(.dataPersistence, level: .low, "📄 String converted to data: \(dataToEncrypt.count) bytes")
        
        // Encrypt data
        LogManager.shared.log(.dataPersistence, level: .low, "🔐 Starting encryption...")
        let sealedBox = try AES.GCM.seal(dataToEncrypt, using: symmetricKey)
        if let combined = sealedBox.combined {
            LogManager.shared.log(.dataPersistence, level: .medium, "🔐 Encryption successful.")
            return combined.base64EncodedString()
        } else {
            LogManager.shared.log(.dataPersistence, level: .high, "⚠️ Encryption failed, combined data is nil.")
            return ""
        }
    }


    static func decrypt(_ string: String, with key: SymmetricKey) -> String? {
        guard let data = Data(base64Encoded: string),
              let sealedBox = try? AES.GCM.SealedBox(combined: data),
              let decryptedData = try? AES.GCM.open(sealedBox, using: key) else {
            return nil
        }
        return String(data: decryptedData, encoding: .utf8)
    }
}

