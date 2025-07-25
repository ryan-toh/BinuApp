//
//  ReceiverServiceV4.swift
//  BinuApp
//
//  Created by Ryan on 8/7/25.
//

import CoreBluetooth
import SwiftUI
import Combine
import CoreLocation

// MARK: - Bluetooth Manager
class ReceiverServiceV4: NSObject, ObservableObject {
    static let sharedReceiver = ReceiverServiceV4()
    private var notificationService = NotificationService.shared
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    
    @Published var isScanning = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var connectedDevice: CBPeripheral?
    @Published var discoveredServices: [CBService] = []
    @Published var selectedService: CBService?
    @Published var discoveredCharacteristics: [CBCharacteristic] = []
    @Published var lastMessage: String = ""
    @Published var writeStatus: String = ""
    @Published var isConnecting = false
    
    private let targetServiceUUID = CBUUID(string: "A0F0FFA0-1B9F-4E8F-BB8D-6F9A8E7D5C4A")
    private let targetCharacteristicUUID = CBUUID(string: "B0F0FFB0-1B9F-4E8F-BB8D-6F9A8E7D5C4A")
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        
        isScanning = true
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(withServices: [targetServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }
    
    func connect(to peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        isConnecting = true
        
        // Add 1 second delay before connecting
        let options: [String: Any] = [
            CBConnectPeripheralOptionStartDelayKey: 1.0
        ]
        centralManager.connect(peripheral, options: options)
    }
    
    func disconnect() {
        if let peripheral = connectedDevice {
            centralManager.cancelPeripheralConnection(peripheral)
            discoveredServices.removeAll()
            discoveredCharacteristics.removeAll()
            selectedService = nil
            isConnecting = false
        }
    }
        
    // Simple data sending function for testing
//    func sendData(_ dataString: String, to characteristic: CBCharacteristic) {
//        guard let data = dataString.data(using: .utf8) else { return }
//        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
//        DispatchQueue.main.async {
//            self.writeStatus = "Sending..."
//        }
//    }
    
    func sendLocation(_ location: CLLocationCoordinate2D, to characteristic: CBCharacteristic) {
        var data = Data()
        data.append(withUnsafeBytes(of: location.latitude) { Data($0) })
        data.append(withUnsafeBytes(of: location.longitude) { Data($0) })
        
        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        DispatchQueue.main.async {
            self.writeStatus = "Sending..."
        }
    }
    
    func readValue(for characteristic: CBCharacteristic) {
        peripheral?.readValue(for: characteristic)
    }
    
    func startNotifications(for characteristic: CBCharacteristic) {
        peripheral?.setNotifyValue(true, for: characteristic)
    }
    
    func stopNotifications(for characteristic: CBCharacteristic) {
        peripheral?.setNotifyValue(false, for: characteristic)
    }
}

// MARK: - CBCentralManagerDelegate
extension ReceiverServiceV4: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.bluetoothState = central.state
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
              serviceUUIDs.contains(targetServiceUUID) else { return }
        
        guard let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
              let raw = UInt8(localName),
              let item = Item(rawValue: raw) else { return }
        
        
        
        // Only append if the device matches the Service UUID and Item is not malformed
        DispatchQueue.main.async {
            if !self.discoveredDevices.contains(peripheral) {
                self.discoveredDevices.append(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.connectedDevice = peripheral
            self.isConnecting = false
            self.stopScanning()
            peripheral.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnecting = false
            print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectedDevice = nil
            self.isConnecting = false
            self.discoveredServices.removeAll()
            self.discoveredCharacteristics.removeAll()
            self.selectedService = nil
            self.lastMessage = ""
            self.writeStatus = ""
            self.peripheral = nil
        }
    }
}

// MARK: - CBPeripheralDelegate
extension ReceiverServiceV4: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        DispatchQueue.main.async {
            self.discoveredServices = services
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == targetCharacteristicUUID {
                DispatchQueue.main.async {
                    self.selectedService = service
                    self.discoveredCharacteristics = [characteristic]
                }
                break
            }
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error reading characteristic value: \(error!.localizedDescription)")
            return
        }
        guard let data = characteristic.value, data.count == 16 else {
            print("Invalid location data received")
            return
        }

        let lat = data.subdata(in: 0..<8).withUnsafeBytes { $0.load(as: Double.self) }
        let lon = data.subdata(in: 8..<16).withUnsafeBytes { $0.load(as: Double.self) }

        DispatchQueue.main.async {
            self.lastMessage = "Lat: \(lat), Lon: \(lon)"
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.writeStatus = "Error: \(error.localizedDescription)"
            } else {
                self.writeStatus = "Sent successfully"
            }
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }
    }
}

