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
    
    func testDecryptFailure() {
        // Simulate a decryption failure
        MockCryptoHelper.shouldDecryptFail = true
        
        let encryptedData = "EncryptedData"
        let key = "TestKey"
        
        // Assert that decryption fails
        let decryptedData = MockCryptoHelper.decrypt(encryptedData, with: key)
        
        XCTAssertNil(decryptedData, "Decryption should fail when the mock is set to fail.")
    }
    
    func testEncryptedDataSaved() {
        let process = CustomProcessInfo(id: 1, timestamp: Date(), cpuUsage: 10.0, memoryUsage: 100.0, shortProcessName: "Test", fullProcessName: "TestProcess")
        
        let symmetricKey: SymmetricKey = SymmetricKey(size: .bits256)
        let keyData = symmetricKey.withUnsafeBytes { Data($0) }
        let keyString = keyData.base64EncodedString()
        
        do {
            // Encrypt the process name
            let encryptedProcessName = try CryptoHelper.encrypt(process.fullProcessName, with: keyString)
            
            // Create a new process with the encrypted name
            let encryptedProcess = CustomProcessInfo(id: process.id, timestamp: process.timestamp, cpuUsage: process.cpuUsage, memoryUsage: process.memoryUsage, shortProcessName: process.shortProcessName, fullProcessName: encryptedProcessName)
            
            // Save to the context (this simulates saving to SwiftData or CoreData storage)
            context.insert(encryptedProcess)  // Add the process to the context
            
            // Commit changes to the context
            try context.save()
            
            // Create a fetch descriptor for CustomProcessInfo
            let fetchDescriptor = FetchDescriptor<CustomProcessInfo>()
            
            // Fetch the saved process from the context based on its id
            let savedProcesses = try context.fetch(fetchDescriptor)
            
            // Find the saved process by matching the id
            if let savedProcess = savedProcesses.first(where: { $0.id == process.id }) {
                // Ensure the fullProcessName is different from the original (i.e., it was encrypted)
                XCTAssertNotEqual(savedProcess.fullProcessName, process.fullProcessName, "Process name was not encrypted correctly.")
            } else {
                XCTFail("Process was not saved correctly.")
            }
            
        } catch {
            XCTFail("Error during encryption, saving or fetching process: \(error)")
        }
    }

    func testPruningOldData() {
        // Simulate data saving and pruning logic
        let process = CustomProcessInfo(id: 1, timestamp: Date().addingTimeInterval(-3600), cpuUsage: 10.0, memoryUsage: 100.0, shortProcessName: "OldProcess", fullProcessName: "OldProcessName")
        
        // Insert the process into the context
        context.insert(process)
        
        do {
            // Save the process into the database
            try context.save()
            
            // Call pruneOldProcessMetrics to remove processes older than 1 minute
            try dataManager.pruneOldProcessMetrics()
            
            // After pruning time has passed, check if it was pruned
            let fetchDescriptor = FetchDescriptor<CustomProcessInfo>()
            let allProcesses = try context.fetch(fetchDescriptor)
            
            // Ensure the old data was pruned (not in the fetched results)
            XCTAssertFalse(allProcesses.contains { $0.id == process.id }, "Old data was not pruned correctly.")
        } catch {
            XCTFail("Error during saving, pruning, or fetching process: \(error)")
        }
    }
    
    
    // Test that the pruning timer triggers correctly
    func testPruningTimer() {
        let expectation = self.expectation(description: "Timer should fire and prune metrics")
        
        // Start pruning timer
        dataManager.startPruningTimer()
        
        // Wait for the timer to trigger
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    override func tearDown() {
        dataManager.pruningTimer?.invalidate()
        super.tearDown()
    }

    
}
