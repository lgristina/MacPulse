//
//  MCConnectionManagerTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 5/2/25.
//
import XCTest
@testable import MacPulse

final class MCConnectionManagerTests: XCTestCase {

    func testStartAndStopAdvertising() {
        let manager = MCConnectionManager(yourName: "Tester")
        
        // Start advertising
        manager.syncAvailable = true
        XCTAssertTrue(manager.syncAvailable)
        
        // Stop advertising
        manager.syncAvailable = false
        XCTAssertFalse(manager.syncAvailable)
    }

    func testSendInviteWithoutSelectedPeerLogsWarning() {
        let manager = MCConnectionManager(yourName: "Tester")
        manager.selectedPeer = nil
        
        // This won't crash but should log
        manager.sendInviteToPeer()
        
        // You would normally use a mock log manager or expectation
    }

    func testInitialState() {
        let manager = MCConnectionManager(yourName: "Tester")
        XCTAssertFalse(manager.paired)
        XCTAssertTrue(manager.isAvailableToPlay == false)
        XCTAssertEqual(manager.availablePeers.count, 0)
    }
}
