//
//  MacPulseAppTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 5/9/25.
//

import XCTest
@testable import MacPulse
import SwiftUI

class MacPulseAppTests: XCTestCase {
    
    // MARK: - Test Get Peer Name
    
    func testGetPeerName_ForMacOS_ReturnsCorrectName() {
        // Simulate macOS environment
        #if os(macOS)
        let peerName = getPeerName()
        XCTAssertEqual(peerName, Host.current().localizedName ?? "MacPulse", "Peer name should be the Mac's localized name")
        #endif
    }
    
    func testGetPeerName_ForIOS_ReturnsDeviceName() {
        // Simulate iOS environment
        #if os(iOS)
        let peerName = getPeerName()
        XCTAssertEqual(peerName, UIDevice.current.name, "Peer name should be the device's name")
        #endif
    }
    
    func testGetPeerName_ForOtherOS_ReturnsDefaultName() {
        // Simulate non-macOS and non-iOS environment
        #if !(os(iOS) || os(macOS))
        let peerName = getPeerName()
        XCTAssertEqual(peerName, "MacPulse", "Peer name should be 'MacPulse' for other OS")
        #endif
    }
    
    
    // MARK: - Test Model Container Initialization
    
    func testModelContainerInitialization() {
        // Given: Initialize the app or simulate the sharedModelContainer directly
        let modelContainer = try? MacPulseApp().sharedModelContainer
        
        // When: Check if the model container is successfully initialized
        XCTAssertNotNil(modelContainer, "ModelContainer should be successfully initialized.")
    }
}
