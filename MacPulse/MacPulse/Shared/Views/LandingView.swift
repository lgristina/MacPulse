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
