import MultipeerConnectivity

// MARK: - Multipeer Connectivity Service Type Extension
extension String {
    /// Service name used for identifying MacPulse sync sessions across devices.
    static var serviceName = "MacPulse-sync"
}

// MARK: - MCConnectionManager Class
/// Manages MultipeerConnectivity sessions, peer discovery, invitations, and data exchange.
class MCConnectionManager: NSObject, ObservableObject {
    
    /// The MultipeerConnectivity service type used to discover nearby devices.
    let serviceType = String.serviceName

    /// The local peer ID representing this device.
    var session: MCSession
    var myPeerId: MCPeerID

    /// Advertises this device's availability to nearby peers.
    var advertiser: MCNearbyServiceAdvertiser

    /// Browses for nearby advertising peers.
    var browser: MCNearbyServiceBrowser

    /// Callback for receiving metrics (system, process, etc.) from the remote peer.
    var onReceiveMetric: ((MetricPayload) -> Void)?

    /// Callback when a request for CPU history is received.
    var onRequestCpuHistory: (() -> Void)?
    
    /// List of discovered peers.
    @Published var availablePeers = [MCPeerID]()

    /// The peer currently selected for sending invitations.
    @Published var selectedPeer: MCPeerID?

    /// Indicates if an invitation has been received from a peer.
    @Published var receivedInvite: Bool = false

    /// The peer from whom an invitation was received.
    @Published var receivedInviteFrom: MCPeerID?

    /// The stored handler for responding to an incoming invitation.
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?

    /// Flag indicating whether the device is available to start a new session.
    @Published var isAvailableToPlay = false

    /// Indicates if the current session is paired with a remote device.
    @Published var paired: Bool = false
    
    /// Role indicator (true if macOS / sender, false if iOS / receiver).
    #if os(macOS)
    let isSender = true
    #else
    let isSender = false
    #endif
    
    /// Toggles advertising availability.
    var syncAvailable: Bool = false {
        didSet {
            if syncAvailable {
                startAdvertising()
            } else {
                stopAdvertising()
            }
        }
    }

    /// Initializes the connection manager with a custom peer name.
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
    
    /// Deinitializes and stops advertising/browsing.
    deinit {
        #if os(macOS)
        stopAdvertising()
        #else
        stopBrowsing()
        #endif
        LogManager.shared.logConnectionStatus("MCConnectionManager deinitialized.", level: .high)
    }

    // MARK: - Advertising
    
    /// Begins advertising this peer to others.
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        LogManager.shared.logConnectionStatus("Started advertising.", level: .medium)
    }
    
    /// Stops advertising this peer to others.
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        LogManager.shared.logConnectionStatus("Stopped advertising.", level: .medium)
    }

    // MARK: - Browsing
    
    /// Starts searching for available peers.
    func startBrowsing() {
        browser.startBrowsingForPeers()
        LogManager.shared.logConnectionStatus("Started browsing.", level: .medium)
    }
    
    /// Stops browsing and clears the list of available peers.
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
        availablePeers.removeAll()
        LogManager.shared.logConnectionStatus("Stopped browsing and cleared available peers.", level: .medium)
    }

    // MARK: - Invitations
    
    /// Sends an invitation to the currently selected peer.
    func sendInviteToPeer() {
        guard let selectedPeer = selectedPeer else {
            LogManager.shared.logConnectionStatus("No peer selected to invite.", level: .low)
            return
        }
        
        LogManager.shared.logConnectionStatus("Inviting peer: \(selectedPeer.displayName)", level: .medium)
        browser.invitePeer(selectedPeer, to: self.session, withContext: nil, timeout: 200)
    }

    // MARK: - Data Sending
    
    /// Sends a metric payload to all connected peers.
    func send(_ payload: MetricPayload) {
        guard !session.connectedPeers.isEmpty else {
            LogManager.shared.logConnectionStatus("No peers are connected.", level: .low)
            return
        }
        do {
            if paired {
                let data = try JSONEncoder().encode(payload)
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            }
        } catch {
            LogManager.shared.log(.syncTransmission, level: .high, "Error sending data: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MCConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            if !self.availablePeers.contains(peerID) {
                self.availablePeers.append(peerID)
                LogManager.shared.log(.syncTransmission, level: .medium, "Found peer: \(peerID.displayName)")
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

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MCConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.receivedInvite = true
            self.receivedInviteFrom = peerID
            self.invitationHandler = invitationHandler
            invitationHandler(true, self.session)
            LogManager.shared.logConnectionStatus("Accepted invitation from \(peerID.displayName).", level: .medium)
        }
    }
}

// MARK: - MCSessionDelegate
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
                    RemoteSystemMonitor.shared.startSendingMetrics(type: 0)
                case .sendProcessMetrics:
                    RemoteSystemMonitor.shared.startSendingMetrics(type: 1)
                case .sendCpuHistory:
                    self.onRequestCpuHistory?()
                case .stopSending(let typeToStop):
                    RemoteSystemMonitor.shared.stopSendingMetrics(type: typeToStop)
                case .system, .process:
                    self.onReceiveMetric?(payload)
                case .cpuUsageHistory(let history):
                    self.onReceiveMetric?(.cpuUsageHistory(history))
                case .logs(_):
                    break
                }
            }
        } catch {
            LogManager.shared.logConnectionStatus("❌ Failed to decode payload from \(peerID.displayName): \(error.localizedDescription)", level: .low)
            if let string = String(data: data, encoding: .utf8) {
                LogManager.shared.logConnectionStatus("🔎 Raw JSON string from \(peerID.displayName): \(string)", level: .low)
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

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
