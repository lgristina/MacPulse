//
//  MCConnectionManager.swift
//  MacPulse
//
//  Created by Austin Frank on 4/17/25.
//

import MultipeerConnectivity

extension String {
    static var serviceName = "MacPulse-sync"
}

class MCConnectionManager: NSObject, ObservableObject {
    let serviceType = String.serviceName
    var session: MCSession
    var myPeerId: MCPeerID
    var advertiser: MCNearbyServiceAdvertiser
    var browser: MCNearbyServiceBrowser
    var onReceiveMetric: ((MetricPayload) -> Void)?
    
    @Published var availablePeers = [MCPeerID]()
    @Published var selectedPeer: MCPeerID?  // Store the selected peer

    @Published var receivedInvite: Bool = false
    @Published var receivedInviteFrom: MCPeerID?
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var isAvailableToPlay = false
    @Published var paired: Bool = false
    
    #if os(macOS)
    let isSender = true
    #else
    let isSender = false
    #endif
    
    var syncAvailable: Bool = false {
        didSet {
            if syncAvailable {
                startAdvertising()
            }
            else {
                stopAdvertising()
            }
        }
    }
    
    init(yourName: String) {
        self.myPeerId = MCPeerID(displayName: yourName)
        self.session = MCSession(peer: myPeerId)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        super.init()
        
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
//
//        if isSender {
//            startAdvertising()
//        } else {
//            startBrowsing()
//        }
    }
    
    deinit {
        stopAdvertising()
        stopBrowsing()
    }
    
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        print("Advertising!")
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        print("STOPPED ADVERTISING!")
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
        print("Browsing!")
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
        availablePeers.removeAll()
        print("STOPPED BROWSING!")
    }
    
    func sendInviteToPeer() {
           guard let selectedPeer = selectedPeer else {
               print("No peer selected to invite.")
               return
           }
           
           // Send invitation to the selected peer
           print("📨 Inviting peer: \(selectedPeer.displayName)")
           browser.invitePeer(selectedPeer, to: self.session, withContext: nil, timeout: 200)
       }
    
    func send(_ payload: MetricPayload) {
        guard !session.connectedPeers.isEmpty else {
            print("No peers are connected.")
            return
        }
        do {
            if paired {
                //print("Sending data: \(payload)")
                let data = try JSONEncoder().encode(payload)
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            }
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
}

extension MCConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            if !self.availablePeers.contains(peerID) {
                self.availablePeers.append(peerID)

                // Store the first available peer found
                if self.selectedPeer == nil {
                    self.selectedPeer = peerID
                    print("📍 Found a peer: \(peerID.displayName)")
                }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let index = availablePeers.firstIndex(of: peerID) else { return }
        DispatchQueue.main.async {
            self.availablePeers.remove(at: index)
            print("PEER LOST!")
        }
    }
}



extension MCConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.receivedInvite = true
            self.receivedInviteFrom = peerID
            self.invitationHandler = invitationHandler
            
            invitationHandler(true, self.session)  // Accept the invitation after the delay
            print("ACCEPTED INVITE!")
        }
    }
}


extension MCConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case.notConnected:
            DispatchQueue.main.async {
                print("NOT CONNECTED!")
                self.paired = false
                self.isAvailableToPlay = true
            }
        case.connected:
            DispatchQueue.main.async {
                print("CONNECTED!")
                self.paired = true
                self.isAvailableToPlay = false
            }
        case.connecting:
            DispatchQueue.main.async {
                print("CONNECTING!!")
            }
        default:
            DispatchQueue.main.async {
                print("DEFAULT! \(state)")
                self.paired = false
                self.isAvailableToPlay = true
            }
        }
    }
    func getCurrentSystemMetric() -> SystemMetric {
        // Collect and return the system metric you want to send
        return SystemMetric(timestamp: Date(), cpuUsage: 40, memoryUsage: 3000, diskActivity: 250) // example
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard session.connectedPeers.contains(peerID) else {
            print("❌ Peer not connected. Not sending metric.")
            return
        }
        if let payload = try? JSONDecoder().decode(MetricPayload.self, from: data) {
            print("📩 Received payload: \(payload)")

            DispatchQueue.main.async {
                
                switch payload {
                case .sendSystemMetrics:
                    print("📡 Received .sendSystemMetrics from peer: \(peerID.displayName)")

//                    // Optionally send back a single metric immediately
//                    do {
//                        let currentMetric = self.getCurrentSystemMetric()
//                        let response = MetricPayload.system(currentMetric)
//                        let encoded = try JSONEncoder().encode(response)
//                        try session.send(encoded, toPeers: [peerID], with: .reliable)
//                        print("✅ Sent initial system metric in response to .startMetrics.")
//                    } catch {
//                        print("❌ Failed to send initial system metric: \(error)")
//                    }

                    // 🔥 Start continuous metric sending
                    RemoteSystemMonitor.shared.startSendingMetrics(type: 0)
                case .sendProcessMetrics:
                    print("📡 Received .sendProcessMetrics from peer: \(peerID.displayName)")
                    RemoteSystemMonitor.shared.startSendingMetrics(type: 1)
                case .stopSending(let typeToStop):
                    print("📡 Received .stopSending with type: \(typeToStop) from peer: \(peerID.displayName)")
                    RemoteSystemMonitor.shared.stopSendingMetrics(type: typeToStop)  // Stop metrics based on type
                case .system:
                    self.onReceiveMetric?(payload)
                case .process:
                    self.onReceiveMetric?(payload)
                default:
                    break
                }

                print("RECEIVING METRIC!")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        print("📜 Received certificate from \(peerID.displayName)")
        certificateHandler(true)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        if let error = error {
                print("❌ Error receiving resource \(resourceName) from \(peerID): \(error)")
            } else {
                print("✅ Finished receiving resource \(resourceName) from \(peerID)")
            }
    }
    
    
}
