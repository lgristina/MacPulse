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
        guard let keyData = Data(base64Encoded: keyString) else {
            throw NSError(domain: "CryptoHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid key"])
        }

        let symmetricKey = SymmetricKey(data: keyData)
        
        // Convert the string to Data
        let dataToEncrypt = Data(string.utf8)
        
        // Encrypt data
        let sealedBox = try AES.GCM.seal(dataToEncrypt, using: symmetricKey)
        
        // `.combined` is guaranteed to be non-nil when using `AES.GCM.seal`, so this fallback is for extra safety
        return sealedBox.combined?.base64EncodedString() ?? ""

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

