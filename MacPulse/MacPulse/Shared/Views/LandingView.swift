//
//  LandingView.swift
//  MacPulse
//
//  Created by Austin Frank on 4/22/25.
//

import SwiftUI

struct LandingView: View {
    @Binding var hasStarted: Bool
    @EnvironmentObject var syncService: MCConnectionManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("MacPulse")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)

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
            
            #if os(iOS)
            if let peer = syncService.availablePeers.first {
                VStack(spacing: 12) {
                    Text("Discovered Peer:")
                        .font(.headline)

                    Text(peer.displayName)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)

                    Button(action: {
                        syncService.browser.invitePeer(peer, to: syncService.session, withContext: nil, timeout: 20)
                        hasStarted = true
                    }) {
                        Text("Connect")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
            } else {
                Text("No peers found yet")
                    .italic()
                    .foregroundColor(.gray)
            }
            #endif

            Button(action: {
                #if os(iOS)
                syncService.sendInviteToPeer()
                #endif
                hasStarted = true
            }) {
                #if os(macOS)
                Text("Start Monitoring")
                #endif
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .animation(.easeInOut, value: syncService.availablePeers)
        .onAppear {
            #if os(macOS)
            syncService.startAdvertising()
            #elseif os(iOS)
            syncService.startBrowsing()
            #endif
        }
        .onDisappear() {
            #if os(iOS)
            syncService.stopBrowsing()
            #endif
        }
    }
}
