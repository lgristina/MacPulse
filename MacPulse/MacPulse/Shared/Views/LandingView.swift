//
//  LandingView.swift
//  MacPulse
//
//  Created by Austin Frank on 4/22/25.
//

import SwiftUI

// MARK: - Landing View

// Entry screen shown before monitoring starts.
// On macOS, it allows the user to start monitoring directly.
// On iOS, it displays discovered peers for connection.
struct LandingView: View {
    @Binding var hasStarted: Bool
    @EnvironmentObject var syncService: MCConnectionManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App logo
            Image("MacPulse")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)

            // Title text varies by platform
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

            // iOS-specific: list of available Mac peers to connect to
#if os(iOS)
            if syncService.availablePeers.isEmpty {
                Text("No peers found yet")
                    .italic()
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 12) {
                    Text("Discovered Peers:")
                        .font(.headline)

                    // List of discovered peers shown as tappable buttons
                    ForEach(syncService.availablePeers, id: \.displayName) { peer in
                        Button(action: {
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

            // macOS-specific: button to start monitoring
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
        // Animate UI changes when peer list updates
        .animation(.easeInOut, value: syncService.availablePeers)

        // Start advertising or browsing when view appears
        .onAppear {
#if os(macOS)
            syncService.startAdvertising()
#elseif os(iOS)
            syncService.startBrowsing()
#endif
        }

        // Stop browsing when leaving the view (iOS only)
        .onDisappear {
#if os(iOS)
            syncService.stopBrowsing()
#endif
        }
    }
}
