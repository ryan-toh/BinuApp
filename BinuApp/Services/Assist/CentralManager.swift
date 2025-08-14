//
//  CentralManager.swift
//  BinuApp
//
//  Created by Hong Eungi on 22/7/25.
//

import SwiftUI
import CoreBluetooth
import UserNotifications
import Foundation

/**
 "Receives" nearby help requests. Runs in the foreground & background. DO NOT INSTANTIATE MORE THAN 1 INSTANCE of CentralManager.
 */

// MARK: - Errors

enum CentralManagerError: Error {
    case invalidManager
    case bluetoothNotAvailable

    case connectError(String)
    case disConnectError(String)
    case discoverServicesError(String)
    case discoverCharacteristicsError(String)
    case discoverIncludedServicesError(String)
    case discoverDescriptorError(String)

    case setNotifyError(String?)
    case updateCharacteristicValueError(String)
    case updateDescriptorValueError(String)
    case writeCharacteristicError(String)
}

// MARK: - Models

struct ScanningOption: Equatable {
    var serviceUUID: [CBUUID]?
    var allowDuplicates: Bool
    var solicitedServiceUUIDs: [CBUUID] = []
}

// MARK: - Central Manager

@Observable
class CentralManager: NSObject {
    // Target GATT UUIDs for your app/device
    let targetServiceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
    let targetCharacteristicUUID = CBUUID(string: "E100")
    let userDescriptionUUID = CBUUID(string: CBUUIDCharacteristicUserDescriptionString)

    /// Set of peripherals that both connect successfully and expose the target characteristic.
    private(set) var connectedTargetPeripherals: [CBPeripheral] = []

    // UI-facing state
    var characteristicDescriptions: [UUID: String] = [:]
    var error: CentralManagerError? = nil {
        didSet {
            // Auto-clear errors after a short delay to avoid “sticky” UI toasts.
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.error = nil }
            }
        }
    }
    var discoveredPeripherals: [CBPeripheral] = []
    /// Latest values received per characteristic; used for write-without-response verification.
    var receivedData: [CBCharacteristic: [Data]] = [:]
    /// Snapshot of system-restored scanning options (for UI display / diagnostics).
    var restoredScanningOption: ScanningOption? = nil
    /// Current scanning options used for `scanForPeripherals`.
    @ObservationIgnored var scanningOption: ScanningOption = .init(serviceUUID: nil, allowDuplicates: false)

    // Behavior flags
    private let alwaysScan = true                 // Keep scanning enabled as soon as BT is on (background-safe).
    private(set) var isScanning = false

    // Dedupe notifications: don't re-alert on the same request content within 3 minutes.
    private var recentRequestTimestamps: [String: Date] = [:]
    private let requestDedupeWindow: TimeInterval = 3 * 60

    // CoreBluetooth
    private var centralManager: CBCentralManager?
    private let managerUID: NSString = "BinuCentralManager"

    override init() {
        super.init()
        print("init was called")

        // Default scan target: your primary service.
        self.scanningOption = .init(serviceUUID: [targetServiceUUID], allowDuplicates: false)

        // Ask for notification permission early (on main actor).
        Task { @MainActor in
            Notifier.requestAuthorization()
        }

        // Create central with state restoration: the system may relaunch and hand us state.
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil, // main queue; move to background queue if you do heavy processing in delegates
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
                CBCentralManagerOptionRestoreIdentifierKey: managerUID
            ]
        )
    }
}

// MARK: - Public API

extension CentralManager {
    /// Returns `false` if we've already notified for the exact same request text within the dedupe window.
    /// - Parameters:
    ///   - value: The human-readable request (from the User Description descriptor).
    ///   - peripheral: The source peripheral (unused in global-dedupe mode).
    /// - Note: Switch the `key` to per-device if you want dedupe per peripheral instead of globally.
    private func shouldNotify(forRequest value: String, from peripheral: CBPeripheral) -> Bool {
        let key = value
        let now = Date()

        // Drop stale entries to keep the map small.
        recentRequestTimestamps = recentRequestTimestamps.filter { now.timeIntervalSince($0.value) < requestDedupeWindow }

        // If a recent notification exists for the same key, skip.
        if let last = recentRequestTimestamps[key], now.timeIntervalSince(last) < requestDedupeWindow {
            return false
        }

        // Record and allow.
        recentRequestTimestamps[key] = now
        return true
    }

    /// Adds a connected/qualified peripheral to `connectedTargetPeripherals` (idempotent).
    private func addConnectedTarget(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            if !self.connectedTargetPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                self.connectedTargetPeripherals.append(peripheral)
            } else if let i = self.connectedTargetPeripherals.firstIndex(where: { $0.identifier == peripheral.identifier }) {
                // Update reference to keep fresh state/characteristics.
                self.connectedTargetPeripherals[i] = peripheral
            }
        }
    }

    /// Removes a peripheral from the connected set.
    private func removeConnectedTarget(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.connectedTargetPeripherals.removeAll { $0.identifier == peripheral.identifier }
        }
    }

    /// Verifies BT power state; posts a user-facing error if not available.
    private func checkBluetooth() -> Bool {
        if centralManager?.state != .poweredOn {
            self.error = .bluetoothNotAvailable
            return false
        }
        return true
    }

    /// Sets `error` on the main thread to ensure UI updates happen safely.
    private func setError(_ error: CentralManagerError?) {
        DispatchQueue.main.async { self.error = error }
    }

    /// Starts scanning for peripherals advertising the specified services.
    /// - Parameters:
    ///   - serviceUUIDs: The services to filter by (defaults to `targetServiceUUID`).
    ///   - allowDuplicateKey: If true, CoreBluetooth delivers duplicates; increases CPU but catches rapid RSSI changes.
    ///   - solicitedServiceUUIDs: Services to solicit using extended advertising.
    /// - Note: This also clears previously discovered peripherals and cancels their connections.
    func startScanning(serviceUUIDs: [CBUUID]?, allowDuplicateKey: Bool = false, solicitedServiceUUIDs: [CBUUID] = []) {
        guard checkBluetooth() else { return }

        // Clean old peripherals and tear down notifications to avoid leaks.
        for p in discoveredPeripherals { cleanup(p) }
        discoveredPeripherals.removeAll()

        self.scanningOption = .init(
            serviceUUID: serviceUUIDs ?? [targetServiceUUID],
            allowDuplicates: allowDuplicateKey,
            solicitedServiceUUIDs: solicitedServiceUUIDs
        )

        centralManager?.scanForPeripherals(
            withServices: scanningOption.serviceUUID,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: scanningOption.allowDuplicates,
                CBCentralManagerScanOptionSolicitedServiceUUIDsKey: scanningOption.solicitedServiceUUIDs
            ])
        isScanning = true
    }

    /// Requests to stop scanning.
    /// - Important: If `alwaysScan` is true, this becomes a no-op so the app continues discovering in background.
    func stopScanning() {
        guard !alwaysScan else { return }   // intentionally ignore UI stop when always-on scanning is desired
        centralManager?.stopScan()
        isScanning = false
    }

    /// Initiates a connection to a peripheral with auto-reconnect enabled.
    func makeConnection(_ peripheral: CBPeripheral) {
        guard checkBluetooth(), let centralManager else { setError(.invalidManager); return }
        centralManager.connect(peripheral, options: [CBConnectPeripheralOptionEnableAutoReconnect: true])
    }

    /// Cancels connection and performs cleanup (disables notifications / removes from lists).
    func cancelConnection(_ peripheral: CBPeripheral) {
        guard checkBluetooth() else { return }
        cleanup(peripheral)
        updatePeripheral(peripheral)
    }

    /// Discovers services on a connected peripheral (optionally filtering).
    func discoverServices(_ peripheral: CBPeripheral, serviceUUIDs: [CBUUID]? = nil) {
        guard checkBluetooth() else { return }
        peripheral.discoverServices(serviceUUIDs)
    }

    /// Discovers characteristics and included services for a given service.
    func discoverServiceDetails(_ peripheral: CBPeripheral,
                                for service: CBService,
                                characteristicUUIDs: [CBUUID]? = nil,
                                includedServiceUUIDs: [CBUUID]? = nil) {
        guard checkBluetooth() else { return }
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
    }

    /// Discovers descriptors for a characteristic (e.g., User Description).
    func discoverDescriptors(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic) {
        guard checkBluetooth() else { return }
        peripheral.discoverDescriptors(for: characteristic)
    }

    /// Subscribes/unsubscribes to notifications for a characteristic, validating capabilities first.
    func setNotifying(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic, value: Bool) {
        guard checkBluetooth() else { return }
        if !characteristic.properties.contains(.notify) { setError(.setNotifyError(nil)) }
        peripheral.setNotifyValue(value, for: characteristic)
    }

    /// Reads the current value for a characteristic (triggers `didUpdateValueFor`).
    func readCharacteristicValue(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic) {
        guard checkBluetooth() else { return }
        peripheral.readValue(for: characteristic)
    }

    /// Reads the value for a descriptor (e.g., User Description string).
    func readDescriptorValue(_ peripheral: CBPeripheral,  for descriptor: CBDescriptor) {
        guard checkBluetooth() else { return }
        peripheral.readValue(for: descriptor)
    }

    /// Writes data to a characteristic with the selected write type.
    /// - Note: If using `.withoutResponse`, we optionally verify the write by polling the characteristic.
    func writeValue(_ peripheral: CBPeripheral, data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        guard checkBluetooth() else { return }
        switch type {
        case .withoutResponse:
            if !characteristic.properties.contains(.writeWithoutResponse) { setError(.writeCharacteristicError("Invalid write type.")) }
        case .withResponse:
            if !characteristic.properties.contains(.write) { setError(.writeCharacteristicError("Invalid write type.")) }
        @unknown default: break
        }
        peripheral.writeValue(data, for: characteristic, type: type)

        // For fire-and-forget writes, perform a lightweight confirmation loop.
        if type == .withoutResponse && !characteristic.isNotifying {
            Task { await checkWrite(peripheral, data: data, for: characteristic) }
        }
    }

    /// Best-effort confirmation for write-without-response:
    /// poll the characteristic up to `maxIterations` to see if the value reflects the write.
    private func checkWrite(_ peripheral: CBPeripheral, data: Data, for characteristic: CBCharacteristic) async {
        let maxIterations = 10
        var current = 0
        while self.receivedData[characteristic]?.first != data && current < maxIterations {
            self.readCharacteristicValue(peripheral, for: characteristic)
            try? await Task.sleep(for: .seconds(1))
            current += 1
        }
        if current == maxIterations && self.receivedData[characteristic]?.first != data {
            setError(.writeCharacteristicError("Write without response may failed."))
        }
    }

    /// Inserts or updates the peripheral in `discoveredPeripherals`, preserving relative order.
    private func updatePeripheral(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            if let i = self.discoveredPeripherals.firstIndex(where: { $0.identifier == peripheral.identifier }) {
                self.discoveredPeripherals.removeAll(where: { $0.identifier == peripheral.identifier })
                self.discoveredPeripherals.insert(peripheral, at: i)
            } else {
                self.discoveredPeripherals.append(peripheral)
            }
        }
    }

    /// Cancels notifications, removes from connected set, and asks CoreBluetooth to disconnect.
    private func cleanup(_ peripheral: CBPeripheral) {
        guard let centralManager else { setError(.invalidManager); return }
        if peripheral.state == .connected {
            for service in (peripheral.services ?? []) {
                for ch in (service.characteristics ?? []) {
                    peripheral.setNotifyValue(false, for: ch)
                }
            }
        }
        removeConnectedTarget(peripheral)
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

// MARK: - CBCentralManagerDelegate

extension CentralManager: CBCentralManagerDelegate {
    /// Responds to Bluetooth state changes. Starts scanning automatically when powered on.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            setError(.bluetoothNotAvailable)
            isScanning = false
            return
        }
        // Always start scanning as soon as Bluetooth is ready (background-friendly behavior).
        if central.state == .poweredOn {
            startScanning(
                serviceUUIDs: scanningOption.serviceUUID ?? [targetServiceUUID],
                allowDuplicateKey: scanningOption.allowDuplicates,
                solicitedServiceUUIDs: scanningOption.solicitedServiceUUIDs
            )
        }
    }

    /// Restores the prior scanning options and marks `isScanning = true` when the system relaunches your app.
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // Restore prior scan options from system-provided dictionary.
        let previousScanningService = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID]
        let previousScanningOptions = dict[CBCentralManagerRestoredStateScanOptionsKey] as? NSDictionary ?? [:]
        let allowDuplicateKey = previousScanningOptions[CBCentralManagerScanOptionAllowDuplicatesKey] as? Bool ?? false
        let solicitedServiceUUIDs = previousScanningOptions[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] as? [CBUUID] ?? []

        let scanningOption = ScanningOption(
            serviceUUID: previousScanningService,
            allowDuplicates: allowDuplicateKey,
            solicitedServiceUUIDs: solicitedServiceUUIDs
        )
        self.scanningOption = scanningOption
        DispatchQueue.main.async { self.restoredScanningOption = scanningOption }

        // The system may already be scanning on our behalf.
        isScanning = true
    }

    /// Peripheral discovered: we auto-connect (if not already connecting) and keep our local list fresh.
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // Optional: local push notification could be sent here.

        // Avoid duplicate connect attempts when the same peripheral re-appears.
        let isAlreadyConnecting = discoveredPeripherals.contains {
            $0.identifier == peripheral.identifier && ($0.state == .connected || $0.state == .connecting)
        }
        if !isAlreadyConnecting { makeConnection(peripheral) }
        updatePeripheral(peripheral)
    }

    /// Successful connection: set delegate, kick off service discovery, and update UI list.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        discoverServices(peripheral, serviceUUIDs: [targetServiceUUID])
        updatePeripheral(peripheral)
    }

    /// Connection failed: cleanup and surface the error.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        cancelConnection(peripheral)
        if let error { setError(.connectError(error.localizedDescription)) }
    }

    /// Disconnected (optionally with auto-retry if `isReconnecting` is false).
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        timestamp: CFAbsoluteTime,
                        isReconnecting: Bool,
                        error: (any Error)?) {
        if let error { setError(.disConnectError(error.localizedDescription)) }
        removeConnectedTarget(peripheral)
        if !isReconnecting { self.makeConnection(peripheral) } // simple auto-retry policy
    }
}

// MARK: - CBPeripheralDelegate

extension CentralManager: CBPeripheralDelegate {
    /// If the target service becomes invalidated, drop the peripheral from our connected set.
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        if invalidatedServices.contains(where: {$0.uuid == targetServiceUUID}) {
            removeConnectedTarget(peripheral)
        }
    }

    /// Services discovered: focus on the target service and proceed to characteristic discovery.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error { setError(.discoverServicesError(error.localizedDescription)); return }
        guard let service = peripheral.services?.first(where: { $0.uuid == targetServiceUUID }) else { return }
        peripheral.discoverCharacteristics([targetCharacteristicUUID], for: service)
        updatePeripheral(peripheral)
    }

    /// Characteristics discovered: track peripherals that expose the target characteristic, then discover descriptors.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error { setError(.discoverCharacteristicsError(error.localizedDescription)); return }

        if let hasTarget = service.characteristics?.contains(where: { $0.uuid == targetCharacteristicUUID }),
           hasTarget {
            addConnectedTarget(peripheral)
        }

        guard let characteristic = service.characteristics?.first(where: { $0.uuid == targetCharacteristicUUID }) else { return }
        discoverDescriptors(peripheral, for: characteristic)
    }

    /// Descriptors discovered: attempt to read User Description for human-friendly text.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error { setError(.discoverDescriptorError(error.localizedDescription)); return }
        if characteristic.uuid == targetCharacteristicUUID,
           let userDesc = characteristic.descriptors?.first(where: { $0.uuid == userDescriptionUUID }) {
            readDescriptorValue(peripheral, for: userDesc)
        }
    }

    /// Descriptor value updated: store human-readable request and optionally notify the user (with dedupe).
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        if let error { setError(.updateDescriptorValueError(error.localizedDescription)); return }
        if descriptor.uuid == userDescriptionUUID,
           let value = descriptor.value as? String,
           let char = descriptor.characteristic,
           char.uuid == targetCharacteristicUUID {

            characteristicDescriptions[peripheral.identifier] = value

            // Avoid spamming notifications for the same request content.
            guard shouldNotify(forRequest: value, from: peripheral) else { return }

            Notifier.sendNow(
                id: "help.detail.\(peripheral.identifier.uuidString)",
                title: "Help request nearby",
                body: "Requested: \(value)"
            )
        }
        updatePeripheral(peripheral)
    }
}

