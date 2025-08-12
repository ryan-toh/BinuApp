import SwiftUI
import CoreBluetooth
import UserNotifications
import Foundation

// Receiver
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

struct ScanningOption: Equatable {
    var serviceUUID: [CBUUID]?
    var allowDuplicates: Bool
    var solicitedServiceUUIDs: [CBUUID] = []
}

@Observable
class CentralManager: NSObject {
    // target IDs
    let targetServiceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
    let targetCharacteristicUUID = CBUUID(string: "E100")
    let userDescriptionUUID = CBUUID(string: CBUUIDCharacteristicUserDescriptionString)

    // state
    var characteristicDescriptions: [UUID: String] = [:]
    var error: CentralManagerError? = nil {
        didSet {
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.error = nil }
            }
        }
    }
    var discoveredPeripherals: [CBPeripheral] = []
    var receivedData: [CBCharacteristic: [Data]] = [:]
    var restoredScanningOption: ScanningOption? = nil
    @ObservationIgnored var scanningOption: ScanningOption = .init(serviceUUID: nil, allowDuplicates: false)

    // always-on flags
    private let alwaysScan = true                 // <-- force background scanning
    private(set) var isScanning = false

    // local de-dupe for notifications
    private var lastNotifiedAt: [UUID: Date] = [:]
    private let notifyCooldown: TimeInterval = 60 * 5 // 5 min per device

    // CoreBluetooth
    private var centralManager: CBCentralManager?
    private let managerUID: NSString = "BinuCentralManager"

    override init() {
        super.init()
        // default scan target
        self.scanningOption = .init(serviceUUID: [targetServiceUUID], allowDuplicates: false)

        // Hop to main actor without blocking init
        Task { @MainActor in
            Notifier.requestAuthorization()
        }

        // central with state restoration
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true,
            CBCentralManagerOptionRestoreIdentifierKey: managerUID
        ])
    }
}

// MARK: - API
extension CentralManager {

    private func checkBluetooth() -> Bool {
        if centralManager?.state != .poweredOn {
            self.error = .bluetoothNotAvailable
            return false
        }
        return true
    }

    private func setError(_ error: CentralManagerError?) {
        DispatchQueue.main.async { self.error = error }
    }

    // Scan (UI can call this, but scanning also auto-starts once BT is on)
//    @MainActor
    func startScanning(serviceUUIDs: [CBUUID]?, allowDuplicateKey: Bool = false, solicitedServiceUUIDs: [CBUUID] = []) {
        guard checkBluetooth() else { return }
        // Clean old peripherals
        for p in discoveredPeripherals { cleanup(p) }
        discoveredPeripherals.removeAll()

        self.scanningOption = .init(serviceUUID: serviceUUIDs ?? [targetServiceUUID],
                                    allowDuplicates: allowDuplicateKey,
                                    solicitedServiceUUIDs: solicitedServiceUUIDs)

        centralManager?.scanForPeripherals(
            withServices: scanningOption.serviceUUID,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: scanningOption.allowDuplicates,
                CBCentralManagerScanOptionSolicitedServiceUUIDsKey: scanningOption.solicitedServiceUUIDs
            ])
        isScanning = true
    }

    // If alwaysScan == true, ignore stop requests from UI
    func stopScanning() {
        guard !alwaysScan else { return }   // <-- ignore UI stop
        centralManager?.stopScan()
        isScanning = false
    }

    func makeConnection(_ peripheral: CBPeripheral) {
        guard checkBluetooth(), let centralManager else { setError(.invalidManager); return }
        centralManager.connect(peripheral, options: [CBConnectPeripheralOptionEnableAutoReconnect: true])
    }

    func cancelConnection(_ peripheral: CBPeripheral) {
        guard checkBluetooth() else { return }
        cleanup(peripheral)
        updatePeripheral(peripheral)
    }

    func discoverServices(_ peripheral: CBPeripheral, serviceUUIDs: [CBUUID]? = nil) {
        guard checkBluetooth() else { return }
        peripheral.discoverServices(serviceUUIDs)
    }

    func discoverServiceDetails(_ peripheral: CBPeripheral, for service: CBService,
                                characteristicUUIDs: [CBUUID]? = nil,
                                includedServiceUUIDs: [CBUUID]? = nil) {
        guard checkBluetooth() else { return }
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
    }

    func discoverDescriptors(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic) {
        guard checkBluetooth() else { return }
        peripheral.discoverDescriptors(for: characteristic)
    }

    func setNotifying(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic, value: Bool) {
        guard checkBluetooth() else { return }
        if !characteristic.properties.contains(.notify) { setError(.setNotifyError(nil)) }
        peripheral.setNotifyValue(value, for: characteristic)
    }

    func readCharacteristicValue(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic) {
        guard checkBluetooth() else { return }
        peripheral.readValue(for: characteristic)
    }

    func readDescriptorValue(_ peripheral: CBPeripheral,  for descriptor: CBDescriptor) {
        guard checkBluetooth() else { return }
        peripheral.readValue(for: descriptor)
    }

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
        if type == .withoutResponse && !characteristic.isNotifying {
            Task { await checkWrite(peripheral, data: data, for: characteristic) }
        }
    }

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

    private func cleanup(_ peripheral: CBPeripheral) {
        guard let centralManager else { setError(.invalidManager); return }
        if peripheral.state == .connected {
            for service in (peripheral.services ?? []) {
                for ch in (service.characteristics ?? []) {
                    peripheral.setNotifyValue(false, for: ch)
                }
            }
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Local notifications
    private func notifyOnce(peripheral: CBPeripheral, title: String, body: String) {
        let now = Date()
        if let last = lastNotifiedAt[peripheral.identifier], now.timeIntervalSince(last) < notifyCooldown {
            return
        }
        lastNotifiedAt[peripheral.identifier] = now
        Notifier.sendNow(id: "help.\(peripheral.identifier.uuidString)", title: title, body: body)
    }
}

// MARK: - CBCentralManagerDelegate
extension CentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            setError(.bluetoothNotAvailable)
            isScanning = false
            return
        }
        // Always start scanning as soon as Bluetooth is ready (background-safe)
        if central.state == .poweredOn {
            startScanning(serviceUUIDs: scanningOption.serviceUUID ?? [targetServiceUUID],
                          allowDuplicateKey: scanningOption.allowDuplicates,
                          solicitedServiceUUIDs: scanningOption.solicitedServiceUUIDs)
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // Restore previously discovered peripherals - Deprecated
//        let previousPeripheral = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
//        self.discoveredPeripherals = previousPeripheral

        // Restore prior scan options
        let previousScanningService = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID]
        let previousScanningOptions = dict[CBCentralManagerRestoredStateScanOptionsKey] as? NSDictionary ?? [:]
        let allowDuplicateKey = previousScanningOptions[CBCentralManagerScanOptionAllowDuplicatesKey] as? Bool ?? false
        let solicitedServiceUUIDs = previousScanningOptions[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] as? [CBUUID] ?? []

        let scanningOption = ScanningOption(serviceUUID: previousScanningService, allowDuplicates: allowDuplicateKey, solicitedServiceUUIDs: solicitedServiceUUIDs)
        self.scanningOption = scanningOption
        DispatchQueue.main.async { self.restoredScanningOption = scanningOption }
        isScanning = true // the system is already scanning on our behalf
    }

    // Discovery: autoconnect + notify user immediately
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // Notify right away (we may not have descriptor text yet)
//        notifyOnce(peripheral: peripheral,
//                   title: "Someone nearby needs help",
//                   body: "Tap to open and see the request.")

        // Autoconnect if not already connecting/connected
        let isAlreadyConnecting = discoveredPeripherals.contains {
            $0.identifier == peripheral.identifier && ($0.state == .connected || $0.state == .connecting)
        }
        if !isAlreadyConnecting { makeConnection(peripheral) }
        updatePeripheral(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        discoverServices(peripheral, serviceUUIDs: [targetServiceUUID])
        updatePeripheral(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        cancelConnection(peripheral)
        if let error { setError(.connectError(error.localizedDescription)) }
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        timestamp: CFAbsoluteTime,
                        isReconnecting: Bool,
                        error: (any Error)?) {
        if let error { setError(.disConnectError(error.localizedDescription)) }
        if !isReconnecting { self.makeConnection(peripheral) } // auto-retry
    }
}

// MARK: - CBPeripheralDelegate
extension CentralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error { setError(.discoverServicesError(error.localizedDescription)); return }
        guard let service = peripheral.services?.first(where: { $0.uuid == targetServiceUUID }) else { return }
        peripheral.discoverCharacteristics([targetCharacteristicUUID], for: service)
        updatePeripheral(peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error { setError(.discoverCharacteristicsError(error.localizedDescription)); return }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == targetCharacteristicUUID }) else { return }
        discoverDescriptors(peripheral, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error { setError(.discoverDescriptorError(error.localizedDescription)); return }
        if characteristic.uuid == targetCharacteristicUUID,
           let userDesc = characteristic.descriptors?.first(where: { $0.uuid == userDescriptionUUID }) {
            readDescriptorValue(peripheral, for: userDesc)
        }
    }

    // When we finally read the characteristic's User Description, notify with detail
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        if let error { setError(.updateDescriptorValueError(error.localizedDescription)); return }
        if descriptor.uuid == userDescriptionUUID,
           let value = descriptor.value as? String,
           let char = descriptor.characteristic,
           char.uuid == targetCharacteristicUUID {
            characteristicDescriptions[peripheral.identifier] = value
            Notifier.sendNow(
                id: "help.detail.\(peripheral.identifier.uuidString)",
                title: "Help request nearby",
                body: "Requested: \(value)"
            )
        }
        updatePeripheral(peripheral)
    }
}
