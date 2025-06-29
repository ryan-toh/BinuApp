//
//  BroadcastViewModel.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import Foundation
import CoreLocation
import Combine
import CoreBluetooth

final class BroadcastViewModel: ObservableObject {
    @Published var isBroadcasting = false
    @Published var selectedItem: Item = Item.allCases.first!
    private let service = BroadcastService()

    func startBroadcasting() {
        service.startBroadcasting(item: selectedItem, coordinates: CLLocationCoordinate2D(latitude: 1.1318, longitude: 10.344))
        isBroadcasting = true
    }

    func stopBroadcasting() {
        service.stopBroadcasting()
        isBroadcasting = false
    }

    func sendLocation(_ location: CLLocationCoordinate2D) {
        service.sendLocation(location)
    }
}
