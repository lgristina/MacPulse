//
//  DataManagerTests.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 4/19/25.
//

import XCTest
import SwiftData
import CoreData
@testable import MacPulse
import CryptoKit

@MainActor
final class DataManagerTests: XCTestCase {
    
    var dataManager: DataManager!
    var container: ModelContainer!
    var context: ModelContext!
    var mockLogManager: MockLogManager!
        
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let schema = Schema([CustomProcessInfo.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        
        dataManager = DataManager(testingContext: context)
    }
    
    // Mocked CryptoHelper for testing
    class MockCryptoHelper: CryptoHelper {
        static var shouldDecryptFail = false
        
        class func decrypt(_ data: String, with key: String) -> String? {
            if shouldDecryptFail {
                return nil  // Simulate a decryption failure
            }
            return "Decrypted: \(data)"  // Return a simulated decrypted string
        }
    }
    
    // Create a mock class or helper for testing purposes
    class MockLogManager: LogManager {
        var loggedMessages: [String] = []
        
        func log(_ level: LogVerbosityLevel, message: String) {
            // Capture the log message instead of writing it to the console
            loggedMessages.append("\(level): \(message)")
        }
        
        func containsLog(_ searchTerm: String) -> Bool {
            return loggedMessages.contains { $0.contains(searchTerm) }
        }
    }


    override func tearDownWithError() throws {
        dataManager = nil
        container = nil
        context = nil
        try super.tearDownWithError()
    }

    func testSaveProcessMetrics() {
        let process = CustomProcessInfo(id: 1, timestamp: Date(), cpuUsage: 10.0, memoryUsage: 100.0, shortProcessName: "Test", fullProcessName: "TestProcess")

        // Assuming symmetricKey is already defined and is a valid SymmetricKey
        let symmetricKey: SymmetricKey = SymmetricKey(size: .bits256)
        let keyData = symmetricKey.withUnsafeBytes { Data($0) }
        let keyString = keyData.base64EncodedString()

        do {
            // Encrypt the process name
            let encryptedProcessName = try CryptoHelper.encrypt(process.fullProcessName, with: keyString)

            // Create a new process with the encrypted name
            let encryptedProcess = CustomProcessInfo(id: process.id, timestamp: process.timestamp, cpuUsage: process.cpuUsage, memoryUsage: process.memoryUsage, shortProcessName: process.shortProcessName, fullProcessName: encryptedProcessName)

            // Assert that the process name is encrypted (not the same as original)
            XCTAssertNotEqual(process.fullProcessName, encryptedProcessName, "Process name was not encrypted correctly.")
        } catch {
            XCTFail("Encryption failed: \(error)")
        }
    }
   
}
