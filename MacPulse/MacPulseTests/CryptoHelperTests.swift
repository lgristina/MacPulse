//
//  CryptoHelperTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 5/9/25.
//

import XCTest
import CryptoKit
@testable import MacPulse

final class CryptoHelperTests: XCTestCase {

    func testEncryptDecrypt_success() throws {
        let originalString = "Test string for encryption"
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data(Array($0)) }
        let base64Key = keyData.base64EncodedString()

        let encrypted = try CryptoHelper.encrypt(originalString, with: base64Key)
        let decrypted = CryptoHelper.decrypt(encrypted, with: key)

        XCTAssertEqual(decrypted, originalString, "Decrypted string should match original string")
    }

    func testEncrypt_withInvalidKey_throwsError() {
        let invalidKey = "not-a-valid-base64!"

        XCTAssertThrowsError(try CryptoHelper.encrypt("Hello", with: invalidKey)) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "CryptoHelper")
            XCTAssertEqual(nsError.code, -1)
        }
    }

    func testDecrypt_withWrongKey_returnsNil() throws {
        let originalString = "Secret Message"
        let correctKey = SymmetricKey(size: .bits256)
        let wrongKey = SymmetricKey(size: .bits256)
        let base64Key = Data(correctKey.withUnsafeBytes { Array($0) }).base64EncodedString()

        let encrypted = try CryptoHelper.encrypt(originalString, with: base64Key)
        let decrypted = CryptoHelper.decrypt(encrypted, with: wrongKey)

        XCTAssertNil(decrypted, "Decryption with wrong key should return nil")
    }

    func testDecrypt_withMalformedInput_returnsNil() {
        let key = SymmetricKey(size: .bits256)
        let malformedString = "this_is_not_base64"

        let result = CryptoHelper.decrypt(malformedString, with: key)
        XCTAssertNil(result, "Malformed input should result in nil decryption")
    }
}
