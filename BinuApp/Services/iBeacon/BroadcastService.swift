//
//  BroadcastService.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import SwiftUI
import Combine
import Foundation
import CoreBluetooth
import CoreLocation

class BroadcastService: NSObject, ObservableObject {
    private let peripheralManager: CBPeripheralManager
//    private let peripheralManager: PeripheralManaging // for testing purposes
    private var service: CBMutableService!
    private var characteristic: CBMutableCharacteristic!

    @Published var isBroadcasting = false
    private var currentCoordinates: CLLocationCoordinate2D?

    override init() {
        peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)
        super.init()
        peripheralManager.delegate = self
    }
    
    // for testing purposes
//    init(peripheralManager: PeripheralManaging = CBPeripheralManager(delegate: nil, queue: nil)) {
//        self.peripheralManager = peripheralManager
//        super.init()
//        self.peripheralManager.delegate = self
//    }
//    

    func startBroadcasting(item: Item, coordinates: CLLocationCoordinate2D) {
        guard peripheralManager.state == .poweredOn else { return }

        // Identify broadcast to receiver
        let serviceUUID = CBUUID(string: "A0F0FFA0-1B9F-4E8F-BB8D-6F9A8E7D5C4A")
        
        // Broadcast Category
        let characteristicUUID = CBUUID(string: "B0F0FFB0-1B9F-4E8F-BB8D-6F9A8E7D5C4A")

        // Setup Service and Characteristic
        characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .write],
            value: nil,
            permissions: [.readable, .writeable]
        )

        service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        peripheralManager.add(service)

        currentCoordinates = coordinates

        // Advertise item as localName, and static service UUID
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: String(item.rawValue),
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
        ])

        isBroadcasting = true
    }

    func stopBroadcasting() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        isBroadcasting = false
    }

    // TODO: Fix this as BroadcastView depends on it
    func sendLocation(_ location: CLLocationCoordinate2D) {
    }
}

// MARK: CBPeripheralManagerDelegate
extension BroadcastService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // TODO: Update UI after Bluetooth off
    }

    // Send the Broadcaster's location
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == characteristic.uuid,
              let coordinates = currentCoordinates else {
            peripheral.respond(to: request, withResult: .unlikelyError)
            return
        }

        // Encode coordinates as two doubles (16 bytes)
        var data = Data()
        data.append(withUnsafeBytes(of: coordinates.latitude) { Data($0) })
        data.append(withUnsafeBytes(of: coordinates.longitude) { Data($0) })

        request.value = data
        peripheral.respond(to: request, withResult: .success)
    }
    
    // Will get Receiver's location
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == characteristic.uuid,
               let data = request.value, data.count == 16 {
                let lat = data.subdata(in: 0..<8).withUnsafeBytes { $0.load(as: Double.self) }
                let lon = data.subdata(in: 8..<16).withUnsafeBytes { $0.load(as: Double.self) }
                let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                // Handle received location here
            }
            peripheral.respond(to: request, withResult: .success)
        }
    }
}
