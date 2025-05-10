//
//  KeyManagerTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 5/9/25.
//

import XCTest
@testable import MacPulse

final class KeyManagerTests: XCTestCase {

    class MockKeychain {
        static var storedKey: String?
        static var errorStatus: OSStatus = errSecSuccess

        static func mockSecItemCopyMatching(_ query: CFDictionary, _ item: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus {
            if errorStatus == errSecSuccess, let storedKey = storedKey {
                let data = storedKey.data(using: .utf8)!
                item.pointee = data as CFTypeRef
                return errSecSuccess
            }
            item.pointee = nil
            return errorStatus
        }

        static func mockSecItemAdd(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus {
            if errorStatus == errSecSuccess {
                if let queryDict = query as? [CFString: Any], let keyData = queryDict[kSecValueData] as? Data,
                   let keyString = String(data: keyData, encoding: .utf8) {
                    storedKey = keyString
                }
                return errSecSuccess
            }
            return errorStatus
        }

        static func mockSecItemUpdate(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus {
            if let queryDict = query as? [CFString: Any], let attributesDict = attributesToUpdate as? [CFString: Any],
               let keyData = attributesDict[kSecValueData] as? Data,
               let keyString = String(data: keyData, encoding: .utf8) {
                storedKey = keyString
                return errSecSuccess
            }
            return errorStatus
        }
    }

    private var mockKeychain: MockKeychain!


    override func tearDown() {
        super.tearDown()
        mockKeychain = nil
    }
    
    func testGetEncryptionKey_WhenKeyNotFound_GeneratesAndStoresNewKey() {
        // Arrange
        KeyManagerTests.MockKeychain.storedKey = nil
        KeyManagerTests.MockKeychain.errorStatus = errSecItemNotFound

        let newKey = KeyManager.getEncryptionKey()

        // Act
        let result = KeyManager.getEncryptionKey()

        // Assert
        XCTAssertNotNil(newKey, "Expected a new encryption key to be generated when no key is found.")
        XCTAssertEqual(result, newKey, "Expected the generated key to be returned on subsequent calls.")
    }

    
    // Test to verify key generation length
    func testEncryptionKeyGenerationLength() {
        let generatedKey = KeyManager.generateEncryptionKey()
        
        // The Base64 encoding of 32 bytes should result in a string of length 44
        XCTAssertEqual(generatedKey.count, 44)
    }
    

    // Test that the encryption key can be retrieved from Keychain
    func testGetEncryptionKey_WhenKeyExists_RetrievesKey() {
        // Mock or set the Keychain to contain an existing key for this test
        let expectedKey = "existingKey"
        KeyManager.storeEncryptionKey(expectedKey)

        let retrievedKey = KeyManager.getEncryptionKey()
        XCTAssertEqual(retrievedKey, expectedKey)
    }

    // Test that the encryption key is updated when a new key is generated
    func testStoreEncryptionKey_UpdatesKey() {
        let oldKey = "oldKey"
        KeyManager.storeEncryptionKey(oldKey)

        let newKey = "newEncryptionKey"
        KeyManager.storeEncryptionKey(newKey)

        let retrievedKey = KeyManager.getEncryptionKey()
        XCTAssertEqual(retrievedKey, newKey)
    }
}
