//
//  Untitled.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import CoreLocation
import Combine
import MultipeerConnectivity

final class ReceiverViewModel: ObservableObject {
    @Published var foundRequests: [(peer: MCPeerID, item: Item)] = []
    @Published var connectedPeers: [MCPeerID] = []
    private let service = ReceiverService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        service.$foundRequests
            .receive(on: DispatchQueue.main)
            .assign(to: &$foundRequests)

        service.$connectedPeers
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectedPeers)
    }

    func startBrowsing() {
        service.startBrowsing()
    }

    func stopBrowsing() {
        service.stopBrowsing()
    }

    func connect(to peer: MCPeerID) {
        service.connect(to: peer)
    }

    func sendLocation(_ location: CLLocationCoordinate2D) {
        service.sendLocation(location)
    }
}
