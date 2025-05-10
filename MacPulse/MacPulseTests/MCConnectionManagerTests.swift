//
//  MCConnectionManagerTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 5/2/25.
//
import XCTest
@testable import MacPulse
import MultipeerConnectivity

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
    
    func testStartAndStopBrowsing() {
        let manager = MCConnectionManager(yourName: "Tester")

        // Start browsing
        manager.startBrowsing()

        // Create an expectation to wait for the discovery of a peer
        let expectation = self.expectation(description: "Peer discovered")

        // Simulate a peer being discovered after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Manually simulate the delegate method being called when a peer is discovered
            let mockPeerID = MCPeerID(displayName: "MockPeer")
            manager.session.delegate?.session(manager.session, peer: mockPeerID, didChange: .connected)

            // Check that at least one peer is discovered
            XCTAssertGreaterThan(manager.availablePeers.count, 0, "Should have available peers after browsing.")

            // Fulfill the expectation to continue the test
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 2.0, handler: nil)

        // Stop browsing
        manager.stopBrowsing()

        // Ensure no peers are available after stopping browsing
        XCTAssertEqual(manager.availablePeers.count, 0, "Should have no available peers after stopping browsing.")
    }


    func testReceivedPeerInvitation() {
        let manager = MCConnectionManager(yourName: "Tester")
        
        let mockPeerID = MCPeerID(displayName: "Peer1")
        
        // Simulate receiving an invitation
        manager.advertiser.delegate?.advertiser(manager.advertiser, didReceiveInvitationFromPeer: mockPeerID, withContext: nil, invitationHandler: { accepted, session in
            XCTAssertTrue(accepted)
            XCTAssertNotNil(session)
        })
    }


    func testReceiveDataFromPeer() {
        let manager = MCConnectionManager(yourName: "Tester")
        
        let mockPeer = MCPeerID(displayName: "Peer1")
        let mockPayload = MetricPayload.sendSystemMetrics
        let mockData = try! JSONEncoder().encode(mockPayload)
        
        manager.session(manager.session, didReceive: mockData, fromPeer: mockPeer)
        
        // Assert the payload is processed as expected
        // You could use an expectation to verify the data is passed to the `onReceiveMetric` closure
    }

    func testPairedStatusAfterConnection() {
        let manager = MCConnectionManager(yourName: "Tester")
        
        // Create an expectation to wait for the connection to complete
        let expectation = self.expectation(description: "Connection established")
        
        // Simulate the connection process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Manually trigger the delegate method to simulate connection
            let mockPeerID = MCPeerID(displayName: "MockPeer")
            manager.session.delegate?.session(manager.session, peer: mockPeerID, didChange: .connected)
            
            // Wait for the paired status to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertTrue(manager.paired, "Manager should be paired after a successful connection.")
                expectation.fulfill()  // Fulfill expectation when assertion passes
            }
        }
        
        // Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testInvitationAcceptanceAndRejection() {
        let manager = MCConnectionManager(yourName: "Tester")
        let mockPeer = MCPeerID(displayName: "Peer1")
        
        let expectation = self.expectation(description: "InvitationHandler called")
        
        manager.invitationHandler = { accepted, session in
            XCTAssertTrue(accepted)
            XCTAssertNotNil(session)
            expectation.fulfill()
        }
        
        manager.advertiser.delegate?.advertiser(manager.advertiser, didReceiveInvitationFromPeer: mockPeer, withContext: nil, invitationHandler: { accepted, session in
            XCTAssertTrue(accepted)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 1)
    }
    
}
