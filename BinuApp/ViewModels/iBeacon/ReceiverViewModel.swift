//
//  ReceiverViewModel.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import Foundation
import CoreLocation
import Combine

// Legacy from v1
import MultipeerConnectivity

class ReceiverViewModel: ObservableObject {
    // Legacy from v1
    @Published var foundRequests: [(peer: MCPeerID, item: Item)] = []
    @Published var connectedPeers: [MCPeerID] = []
    
    // v3
    private let receiverService = ReceiverService()
    private var cancellables = Set<AnyCancellable>()
    @Published var broadcasterLocation: CLLocationCoordinate2D?
    @Published var discoveredItem: Item?
    @Published var notificationReceived: Bool = false
    
    init() {
        receiverService.$receivedBroadcast
            .compactMap { $0?.coordinates }
            .assign(to: &$broadcasterLocation)

        receiverService.$discoveredItem
            .assign(to: &$discoveredItem)
    }

    func sendLocation(_ location: CLLocationCoordinate2D) {
        receiverService.sendLocation(location)
    }
    
    // Legacy from v1
    func startBrowsing() {
//        service.startBrowsing()
    }

    // Legacy from v1
    func stopBrowsing() {
//        service.stopBrowsing()
    }

    // Legacy from v1
    func connect(to peer: MCPeerID) {
//        service.connect(to: peer)
    }
}
