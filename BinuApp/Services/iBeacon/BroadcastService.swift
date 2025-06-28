//
//  BroadcastService.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import CoreBluetooth
import CoreLocation

class BroadcastService: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager!
    private var connectedPeripheral: CBPeripheral?
    private var locationCharacteristic: CBMutableCharacteristic?
    private var broadcastData: BroadcastData?
    
    private let serviceUUID = CBUUID(string: "ABCD")
    private let locationCharacteristicUUID = CBUUID(string: "1234")
    
    var onReceiverLocationUpdate: ((CLLocationCoordinate2D?) -> Void)?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // added on 0629 for debugging
    func startBroadcasting(item: Item) {
    }
    
    func stopBroadcasting() {
    }
    
    func sendLocation(_ location: CLLocationCoordinate2D) {
    }
    // end here
    
    func startAdvertising(broadcastData: BroadcastData) {
        self.broadcastData = broadcastData
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        locationCharacteristic = CBMutableCharacteristic(
            type: locationCharacteristicUUID,
            properties: .write,
            value: nil,
            permissions: .writeable
        )
        
        service.characteristics = [locationCharacteristic!]
        peripheralManager.add(service)
        
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "Broadcast-\(broadcastData.item.description)"
        ]
        peripheralManager.startAdvertising(advertisementData)
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn, let data = broadcastData {
            startAdvertising(broadcastData: data)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == locationCharacteristicUUID,
               let value = request.value {
                
                let location = decodeLocation(data: value)
                onReceiverLocationUpdate?(location)
                
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }
    
    private func decodeLocation(data: Data) -> CLLocationCoordinate2D? {
        guard data.count == 16 else { return nil }
        let lat = data.subdata(in: 0..<8).withUnsafeBytes { $0.load(as: Double.self) }
        let lon = data.subdata(in: 8..<16).withUnsafeBytes { $0.load(as: Double.self) }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        // commented out on 0629 for debugging
        //peripheralManager.cancelConnection(peripheral)
    }
}

