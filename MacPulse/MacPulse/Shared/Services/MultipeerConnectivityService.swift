//import Foundation
//import MultipeerConnectivity
//
//class MultipeerConnectivityService: NSObject, ObservableObject {
//    private let serviceType = "macpulse-sync"
//        #if os(iOS)
//        private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
//        #else
//        private let myPeerID = MCPeerID(displayName: Host.current().localizedName ?? "macpulse-mac")
//        #endif
//        private let session: MCSession
//
//        #if os(iOS)
//        private var browser: MCNearbyServiceBrowser?
//        #elseif os(macOS)
//        private var advertiser: MCNearbyServiceAdvertiser?
//        #endif
//
//        @Published var connectedPeers: [MCPeerID] = []
//        var onReceive: ((Data) -> Void)?
//
//        override init() {
//            self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
//            super.init()
//            self.session.delegate = self
//
//            #if os(iOS)
//            browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
//            browser?.delegate = self
//            browser?.startBrowsingForPeers()
//            #elseif os(macOS)
//            advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
//            advertiser?.delegate = self
//            advertiser?.startAdvertisingPeer()
//            #endif
//        }
//
//    func send(_ data: Data) {
//        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
//    }
//}
//
//extension MultipeerConnectivityService: MCSessionDelegate {
//    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//        DispatchQueue.main.async {
//            self.connectedPeers = session.connectedPeers
//        }
//    }
//
//    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        DispatchQueue.main.async {
//            self.onReceive?(data)
//        }
//    }
//
//    // The rest are required but unused
//    func session(_: MCSession, didReceive: InputStream, withName: String, fromPeer: MCPeerID) {}
//    func session(_: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
//    func session(_: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
//}
//
//#if os(iOS)
//extension MultipeerConnectivityService: MCNearbyServiceBrowserDelegate {
//    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
//        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
//    }
//
//    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
//}
//#endif
//
//#if os(macOS)
//extension MultipeerConnectivityService: MCNearbyServiceAdvertiserDelegate {
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
//                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//        invitationHandler(true, session)
//    }
//}
//#endif
