//
//  ReceiverService.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import Foundation
import CoreBluetooth
import CoreLocation
import UserNotifications
import UIKit
import MultipeerConnectivity

class ReceiverService: NSObject, ObservableObject {
    private let centralManager: CBCentralManager
    private var discoveredPeripheral: CBPeripheral?
    private let targetServiceUUID = CBUUID(string: "A0F0FFA0-1B9F-4E8F-BB8D-6F9A8E7D5C4A")
    private let targetCharacteristicUUID = CBUUID(string: "B0F0FFB0-1B9F-4E8F-BB8D-6F9A8E7D5C4A")

    @Published var receivedBroadcast: BroadcastData?
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    private var currentItem: Item?
    
    // Legacy from v1
    @Published var foundRequests: [(peer: MCPeerID, item: Item)] = []
    @Published var connectedPeers: [MCPeerID] = []

    // Legacy from v1
    func startBrowsing() {
        
    }
    
    // Legacy from v1
    func stopBrowsing() {
        
    }
    
    // Legacy from v1
    func connect(to peer: MCPeerID) {
        
    }
    
    // Legacy from v1
    func sendLocation(_ location: CLLocationCoordinate2D) {
        
    }

    override init() {
        centralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        centralManager.delegate = self
        requestNotificationPermission()
    }

    private func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: [targetServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(for item: Item) {
        let content = UNMutableNotificationContent()
        content.title = "Nearby Help Available"
        content.body = "Someone is offering \(item.description) nearby"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: CBCentralManagerDelegate
extension ReceiverService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        // Ensure service UUID present
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
              serviceUUIDs.contains(targetServiceUUID) else { return }

        // Extract item from localName
        guard let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
              let raw = UInt8(localName),
              let item = Item(rawValue: raw) else {
            return
        }

        currentItem = item
        discoveredPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)

        if let existing = backgroundTaskID {
            UIApplication.shared.endBackgroundTask(existing)
        }
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            [weak self] in self?.backgroundTaskID = .invalid
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([targetServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        discoveredPeripheral = nil
        currentItem = nil
        startScanning()

        if let tid = backgroundTaskID {
            UIApplication.shared.endBackgroundTask(tid)
            backgroundTaskID = nil
        }
    }
}

// MARK: CBPeripheralDelegate
extension ReceiverService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == targetServiceUUID }) else { return }
        peripheral.discoverCharacteristics([targetCharacteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let char = service.characteristics?.first(where: { $0.uuid == targetCharacteristicUUID }) else { return }
        peripheral.readValue(for: char)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value, data.count == 16,
              let item = currentItem else { return }

        let lat = data.subdata(in: 0..<8).withUnsafeBytes { $0.load(as: Double.self) }
        let lon = data.subdata(in: 8..<16).withUnsafeBytes { $0.load(as: Double.self) }
        let coords = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        DispatchQueue.main.async {
            self.receivedBroadcast = BroadcastData(item: item, coordinates: coords)
        }
        sendNotification(for: item)
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
