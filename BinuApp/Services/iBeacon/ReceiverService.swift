//
//  ReceiverService.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import MultipeerConnectivity
import CoreLocation

final class ReceiverService: NSObject, ObservableObject {
    private let serviceType = "help-request"
    private var session: MCSession!
    private var browser: MCNearbyServiceBrowser?

    @Published var connectedPeers = [MCPeerID]()
    @Published var foundRequests: [(peer: MCPeerID, item: Item)] = []

    override init() {
        super.init()
        let peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID,
                            securityIdentity: nil,
                            encryptionPreference: .required)
        session.delegate = self
    }

    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: session.myPeerID,
                                         serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("Started browsing for peers")
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        session.disconnect()
        print("Stopped browsing")
    }

    func connect(to peer: MCPeerID) {
        print("Inviting peer: \(peer.displayName)")
        browser?.invitePeer(peer,
                            to: session,
                            withContext: nil,
                            timeout: 30)
    }

    func sendLocation(_ location: CLLocationCoordinate2D) {
        guard !session.connectedPeers.isEmpty else {
            print("No connected peers to send location")
            return
        }
        let payload = "\(location.latitude),\(location.longitude)"
        guard let data = payload.data(using: .utf8) else { return }
        do {
            try session.send(data,
                             toPeers: session.connectedPeers,
                             with: .reliable)
            print("Sent location: \(payload)")
        } catch {
            print("Failed to send location: \(error)")
        }
    }
}

extension ReceiverService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        print("Browsing failed: \(error.localizedDescription)")
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        guard let raw = info?["item"],
              let item = Item(rawValue: raw) else { return }
        DispatchQueue.main.async {
            if !self.foundRequests.contains(where: { $0.peer == peerID }) {
                self.foundRequests.append((peerID, item))
                print("Added request: \(item.rawValue) from \(peerID.displayName)")
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.foundRequests.removeAll { $0.peer == peerID }
        }
    }
}

extension ReceiverService: MCSessionDelegate {
    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        print("Session state with \(peerID.displayName).")
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.foundRequests.removeAll { $0.peer == peerID }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
            default: break
            }
        }
    }

    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            print("Received data from \(peerID.displayName): \(message)")
            NotificationCenter.default.post(name: .didReceiveCoordinates, object: message)
        }
    }

    // Required stubs
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {}
}

