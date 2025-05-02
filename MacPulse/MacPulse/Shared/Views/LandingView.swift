//
//  LandingView.swift
//  MacPulse
//
//  Created by Austin Frank on 4/22/25.
//

import SwiftUI

/// The initial screen presented to users on both macOS and iOS.
/// - macOS: Displays a welcome message and "Start Monitoring" button.
/// - iOS: Scans for and displays available macOS peers to connect to via MultipeerConnectivity.
struct LandingView: View {
    /// Tracks whether the user has started the app experience.
    @Binding var hasStarted: Bool
    
    /// The shared multipeer connectivity service for browsing/advertising peers.
    @EnvironmentObject var syncService: MCConnectionManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // MARK: - App Icon
            Image("MacPulse")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)

            // MARK: - Title Text
            #if os(macOS)
            Text("Welcome to MacPulse")
                .font(.title)
                .padding()
            #elseif os(iOS)
            Text("Monitor a Mac from your iPhone or iPad")
                .font(.title2)
                .padding()
            #endif

            Spacer()

            // MARK: - iOS: Peer Discovery
            #if os(iOS)
            if syncService.availablePeers.isEmpty {
                Text("No peers found yet")
                    .italic()
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 12) {
                    Text("Discovered Peers:")
                        .font(.headline)

                    ForEach(syncService.availablePeers, id: \.displayName) { peer in
                        Button(action: {
                            // Send invite to selected peer and mark app as started
                            syncService.browser.invitePeer(peer, to: syncService.session, withContext: nil, timeout: 20)
                            hasStarted = true
                            syncService.sendInviteToPeer()
                        }) {
                            Text(peer.displayName)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            #endif

            // MARK: - macOS: Start Button
            #if os(macOS)
            Button(action: {
                hasStarted = true
            }) {
                Text("Start Monitoring")
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            #endif
        }

        // MARK: - Lifecycle & Animations
        .animation(.easeInOut, value: syncService.availablePeers)
        .onAppear {
            #if os(macOS)
            syncService.startAdvertising()
            #elseif os(iOS)
            syncService.startBrowsing()
            #endif
        }
        .onDisappear {
            #if os(iOS)
            syncService.stopBrowsing()
            #endif
        }
    }
}
