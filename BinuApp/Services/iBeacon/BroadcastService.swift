//
//  BroadcastService.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import Foundation
import CoreBluetooth
import CoreLocation

class BroadcastService: NSObject, ObservableObject {
    private let peripheralManager: CBPeripheralManager
    private var service: CBMutableService!
    private var characteristic: CBMutableCharacteristic!

    @Published var isBroadcasting = false
    private var currentCoordinates: CLLocationCoordinate2D?

    override init() {
        peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)
        super.init()
        peripheralManager.delegate = self
    }

    func startBroadcasting(item: Item, coordinates: CLLocationCoordinate2D) {
        guard peripheralManager.state == .poweredOn else { return }

        let serviceUUID = CBUUID(string: "A0F0FFA0-1B9F-4E8F-BB8D-6F9A8E7D5C4A")
        let characteristicUUID = CBUUID(string: "B0F0FFB0-1B9F-4E8F-BB8D-6F9A8E7D5C4A")

        // Setup Service and Characteristic
        characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: .read,
            value: nil,
            permissions: .readable
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
}
