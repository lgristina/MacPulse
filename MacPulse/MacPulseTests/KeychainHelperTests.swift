//
//  KeychainHelperTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 5/7/25.
//
import XCTest
import CryptoKit
@testable import MacPulse

final class KeychainHelperTests: XCTestCase {

    let testKeyName = "test.encryption.key"

    override func setUpWithError() throws {
        // Make sure any old key is removed before tests
        deleteKeyIfExists()
    }

    override func tearDownWithError() throws {
        // Clean up after tests
        deleteKeyIfExists()
    }

    func deleteKeyIfExists() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: testKeyName,
            kSecAttrService as String: KeychainHelper.service
        ]
        SecItemDelete(query as CFDictionary)
    }

    func testSaveAndLoadSymmetricKey() throws {
        let originalKey = SymmetricKey(size: .bits256)
        KeychainHelper.saveKey(originalKey, forKey: testKeyName)

        guard let loadedData = KeychainHelper.loadKey(testKeyName) else {
            XCTFail("Failed to load key from Keychain")
            return
        }

        let loadedKey = SymmetricKey(data: loadedData)
        XCTAssertEqual(originalKey, loadedKey, "Loaded key does not match saved key")
    }

    func testLoadNonexistentKeyReturnsNil() throws {
        let result = KeychainHelper.loadKey("nonexistent.key")
        XCTAssertNil(result, "Expected nil for nonexistent key")
    }

    func testOverwriteKey() throws {
        let key1 = SymmetricKey(size: .bits256)
        KeychainHelper.saveKey(key1, forKey: testKeyName)

        let key2 = SymmetricKey(size: .bits256)
        KeychainHelper.saveKey(key2, forKey: testKeyName)

        guard let loadedData = KeychainHelper.loadKey(testKeyName) else {
            XCTFail("Failed to load overwritten key")
            return
        }

        let loadedKey = SymmetricKey(data: loadedData)
        XCTAssertEqual(key2, loadedKey, "Loaded key does not match last saved key")
    }
}
