//
//  CryptoHelper.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 5/7/25.
//

import Foundation
import CryptoKit
class CryptoHelper {

    static func encrypt(_ string: String, with key: SymmetricKey) -> String {
        let data = string.data(using: .utf8)!
        let sealedBox = try! AES.GCM.seal(data, using: key)
        return sealedBox.combined!.base64EncodedString()
    }

    static func decrypt(_ string: String, with key: SymmetricKey) -> String? {
        guard let data = Data(base64Encoded: string),
              let sealedBox = try? AES.GCM.SealedBox(combined: data) else {
            return nil
        }
        let decryptedData = try! AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)
    }
}

