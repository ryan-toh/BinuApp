//
//  BroadcastService.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import MultipeerConnectivity
import CoreLocation

final class BroadcastService: NSObject {
    private let serviceType = "help-request"
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var item: Item!

    func startBroadcasting(item: Item) {
        self.item = item

        let peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID,
                            securityIdentity: nil,
                            encryptionPreference: .required)
        session.delegate = self

        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["item": item.rawValue],
            serviceType: serviceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()

        print("🔊 Advertising as: \(item.rawValue)")
    }

    func stopBroadcasting() {
        advertiser.stopAdvertisingPeer()
        session.disconnect()
        advertiser = nil
        session = nil
        item = nil
        print("🔇 Stopped advertising")
    }

    func sendLocation(_ location: CLLocationCoordinate2D) {
        guard !session.connectedPeers.isEmpty else {
            print("⚠️ No connected peers to send location")
            return
        }
        let payload = "\(location.latitude),\(location.longitude)"
        guard let data = payload.data(using: .utf8) else { return }
        do {
            try session.send(data,
                             toPeers: session.connectedPeers,
                             with: .reliable)
            print("📍 Sent location: \(payload)")
        } catch {
            print("🚨 Failed to send location: \(error)")
        }
    }
}

extension BroadcastService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        print("❌ Advertiser failed: \(error.localizedDescription)")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("🎯 Received connection request from \(peerID.displayName), accepting…")
        invitationHandler(true, session)
    }
}

extension BroadcastService: MCSessionDelegate {
    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        print("🔄 Session state with \(peerID.displayName).")
    }

    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            print("📬 Received data: \(message)")
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
