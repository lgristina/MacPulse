//
//  MetricContainerTests.swift
//  MacPulseTests
//


import XCTest
@testable import MacPulse

class MetricContainerTests: XCTestCase {

    // Test successful initialization of MetricContainer
    func testInitializationSuccess() {
        // We are testing the successful initialization of the MetricContainer
        // and ensuring that no errors are thrown during this process.
        
        XCTAssertNoThrow(try MetricContainer(), "MetricContainer should initialize without throwing an error.")
    }

    // Test the backup store URL
    func testBackupStoreURL() {
        // We are testing the calculation of the backup store URL to ensure it's correct.
        
        let url = MetricContainer.backupStoreURL
        XCTAssertTrue(url.absoluteString.contains("BackupMetricContainer.sqlite"), "Backup store URL should end with BackupMetricContainer.sqlite")
    }
   
}

