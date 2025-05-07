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
    var onRequestCpuHistory: (() -> Void)?
    
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
    }
    
    deinit {
        stopAdvertising()
        stopBrowsing()
        LogManager.shared.logConnectionStatus("MCConnectionManager deinitialized.", level: .high)
    }
    
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        LogManager.shared.logConnectionStatus("Started advertising.", level: .medium)
        print(availablePeers)
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        LogManager.shared.logConnectionStatus("Stopped advertising.", level: .medium)
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
        LogManager.shared.logConnectionStatus("Started browsing.", level: .medium)
        print(availablePeers)
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
        availablePeers.removeAll()
        LogManager.shared.logConnectionStatus("Stopped browsing and cleared available peers.", level: .medium)
    }
    
    func sendInviteToPeer() {
        guard let selectedPeer = selectedPeer else {

            LogManager.shared.logConnectionStatus("No peer selected to invite.", level: .low)
            return
        }
        
        // Send invitation to the selected peer
        LogManager.shared.logConnectionStatus("Inviting peer: \(selectedPeer.displayName)", level: .medium)
        browser.invitePeer(selectedPeer, to: self.session, withContext: nil, timeout: 200)
    }
    
    func send(_ payload: MetricPayload) {
        guard !session.connectedPeers.isEmpty else {
            LogManager.shared.logConnectionStatus("No peers are connected.", level: .low)
            return
        }
        do {
            if paired {
                //print("Sending data: \(payload)")
                let data = try JSONEncoder().encode(payload)
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                LogManager.shared.log(.syncTransmission, level: .high, "Sent data: \(payload)")
            }
        } catch {
            LogManager.shared.log(.syncTransmission, level: .high, "Error sending data: \(error.localizedDescription)")
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
                    LogManager.shared.logConnectionStatus("Found a peer: \(peerID.displayName)", level: .medium)
                }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let index = availablePeers.firstIndex(of: peerID) else { return }
        DispatchQueue.main.async {
            self.availablePeers.remove(at: index)
            LogManager.shared.logConnectionStatus("Lost peer: \(peerID.displayName)", level: .medium)
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
            LogManager.shared.logConnectionStatus("Accepted invitation from \(peerID.displayName).", level: .medium)
        }
    }
}

extension MCConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            DispatchQueue.main.async {
                LogManager.shared.logConnectionStatus("Not connected to peer: \(peerID.displayName).", level: .medium)
                self.paired = false
                self.isAvailableToPlay = true
            }
        case .connected:
            DispatchQueue.main.async {
                LogManager.shared.logConnectionStatus("Connected to peer: \(peerID.displayName).", level: .medium)
                self.paired = true
                self.isAvailableToPlay = false
            }
        case .connecting:
            DispatchQueue.main.async {
                LogManager.shared.logConnectionStatus("Connecting to peer: \(peerID.displayName).", level: .medium)
            }
        default:
            DispatchQueue.main.async {
                LogManager.shared.logConnectionStatus("Default state for peer: \(peerID.displayName) with state: \(state).", level: .medium)
                self.paired = false
                self.isAvailableToPlay = true
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard session.connectedPeers.contains(peerID) else {
            LogManager.shared.logConnectionStatus("❌ Peer not connected. Not processing data from \(peerID.displayName).", level: .low)
            return
        }
        
        do {
            let payload = try JSONDecoder().decode(MetricPayload.self, from: data)
            LogManager.shared.log(.syncTransmission, level: .high, "Received data from \(peerID.displayName): \(payload)")

            DispatchQueue.main.async {
                switch payload {
                case .sendSystemMetrics:
                    LogManager.shared.logConnectionStatus("Received .sendSystemMetrics from peer: \(peerID.displayName)", level: .medium)
                    RemoteSystemMonitor.shared.startSendingMetrics(type: 0)
                case .sendProcessMetrics:
                    LogManager.shared.logConnectionStatus("Received .sendProcessMetrics from peer: \(peerID.displayName)", level: .medium)
                    RemoteSystemMonitor.shared.startSendingMetrics(type: 1)
                case .sendCpuHistory:
                    LogManager.shared.logConnectionStatus("Received .sendCpuHistory from peer: \(peerID.displayName)", level: .medium)
                    self.onRequestCpuHistory?()
                case .stopSending(let typeToStop):
                    LogManager.shared.logConnectionStatus("Received .stopSending with type: \(typeToStop) from peer: \(peerID.displayName)", level: .medium)
                    RemoteSystemMonitor.shared.stopSendingMetrics(type: typeToStop)
                case .system, .process:
                    self.onReceiveMetric?(payload)
                case .cpuUsageHistory(let history):
                    self.onReceiveMetric?(.cpuUsageHistory(history))
                case .logs(_):
                    LogManager.shared.logConnectionStatus("Logs message received from \(peerID.displayName).", level: .medium)
                }
            }
            
        } catch {
            LogManager.shared.logConnectionStatus("❌ Failed to decode payload from \(peerID.displayName): \(error.localizedDescription)", level: .low)
            if let string = String(data: data, encoding: .utf8) {
                LogManager.shared.logConnectionStatus("🔎 Raw JSON string from \(peerID.displayName): \(string)", level: .low)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        LogManager.shared.logConnectionStatus("📜 Received certificate from \(peerID.displayName).", level: .medium)
        certificateHandler(true)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        if let error = error {
            LogManager.shared.logConnectionStatus("❌ Error receiving resource \(resourceName) from \(peerID): \(error.localizedDescription)", level: .low)
        } else {
            LogManager.shared.logConnectionStatus("✅ Finished receiving resource \(resourceName) from \(peerID)", level: .medium)

        }
    }
}
