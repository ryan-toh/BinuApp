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

// Legacy from v1
import MultipeerConnectivity

class ReceiverService: NSObject, ObservableObject {
    static let shared = ReceiverService()
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    
    // maybe v4?
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

    @Published var receivedBroadcast: BroadcastData?
    @Published var discoveredItem: Item?
    @Published private var currentItem: Item?
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    
    // For sending location information
    private var writableCharacteristic: CBCharacteristic?
    private var pendingLocationToSend: CLLocationCoordinate2D?
    
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
//    func connect(to peer: MCPeerID) {
//        
//    }
    
    private override init() {
        
        super.init()
        centralManager = CBCentralManager(delegate: nil, queue: nil)
//        centralManager.delegate = self
        requestNotificationPermission()
    }

    // Search for broadcasters
    private func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        
        isScanning = true
        discoveredDevices.removeAll()
        
        centralManager.scanForPeripherals(
            withServices: [targetServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // Helper function to alert user to connect
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
    
    // Legacy from v1
    // Updated for v3
    
    // Call to accept the connection
    func sendLocation(_ location: CLLocationCoordinate2D, to characteristic: CBCharacteristic) {
        var data = Data()
        data.append(withUnsafeBytes(of: location.latitude) { Data($0) })
        data.append(withUnsafeBytes(of: location.longitude) { Data($0) })
        
        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        DispatchQueue.main.async {
            self.writeStatus = "Sending..."
        }
    }
    
    func connect() {
        self.peripheral =
        self.peripheral?.delegate = self
        isConnecting = true
        
        // Add 1 second delay before connecting
        let options: [String: Any] = [
            CBConnectPeripheralOptionStartDelayKey: 1.0
        ]
        
        centralManager.connect(peripheral, options: options)
        
        if let existing = backgroundTaskID {
            UIApplication.shared.endBackgroundTask(existing)
        }
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            [weak self] in self?.backgroundTaskID = .invalid
        }
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
        
        // don't connect, get approval from notif first
        sendNotification(for: item)
        
//        centralManager.connect(peripheral, options: nil)
//
//        if let existing = backgroundTaskID {
//            UIApplication.shared.endBackgroundTask(existing)
//        }
//        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
//            [weak self] in self?.backgroundTaskID = .invalid
//        }
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
        
        // If location is already cached
        if let location = pendingLocationToSend {
            sendLocation(to: CBCharacteristic())
            pendingLocationToSend = nil
        }
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

// MARK: UNUserNotificationCenterDelegate
extension ReceiverService: UNUserNotificationCenterDelegate {
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.userInfo["action"] as? String == "connectToBroadcaster" {
            connect()
        }
        completionHandler()
    }
}
