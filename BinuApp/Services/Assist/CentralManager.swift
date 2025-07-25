//
//  CentralManagerError.swift
//  BinuApp
//
//  Created by Ryan on 24/7/25.
//


import SwiftUI
import CoreBluetooth

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
    
    var error: CentralManagerError? = nil {
        didSet {
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.error = nil
                }
            }
        }
    }
    
    var discoveredPeripherals: [CBPeripheral] = []
    var receivedData: [CBCharacteristic: [Data]] = [:]
    var restoredScanningOption: ScanningOption? = nil
    @ObservationIgnored var scanningOption: ScanningOption = .init(allowDuplicates: false)

    
    private var centralManager: CBCentralManager?
    
    private let managerUID: NSString = "ItsukiCentralManager"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true,
            CBCentralManagerOptionRestoreIdentifierKey: managerUID
        ])
    }
}

extension CentralManager {
    
    private func checkBluetooth() -> Bool {
        if centralManager?.state != .poweredOn {
            self.error = .bluetoothNotAvailable
            return false
        }
        return true
    }
    
    private func setError(_ error: CentralManagerError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    // step 1: scan for peripheral
    @MainActor
    func startScanning(serviceUUIDs: [CBUUID]? , allowDuplicateKey: Bool = false, solicitedServiceUUIDs: [CBUUID] = []) {
        if !checkBluetooth() {
            return
        }
        for peripheral in discoveredPeripherals {
            cleanup(peripheral)
        }
        self.discoveredPeripherals.removeAll()
        self.scanningOption = .init(serviceUUID: serviceUUIDs, allowDuplicates: allowDuplicateKey, solicitedServiceUUIDs: solicitedServiceUUIDs)
                
        centralManager?.scanForPeripherals(
            withServices: serviceUUIDs,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: allowDuplicateKey,
                CBCentralManagerScanOptionSolicitedServiceUUIDsKey: solicitedServiceUUIDs
            ])
    }
    
    
    func stopScanning() {
        centralManager?.stopScan()
    }

    // step 2: connect to peripheral found
    // connection result send to didConnect, didFailToConnect
    func makeConnection(_ peripheral: CBPeripheral) {
        if !checkBluetooth() {
            return
        }
        guard let centralManager else {
            setError(.invalidManager)
            return
        }
        print("connecting to ", peripheral)
        centralManager.connect(peripheral, options: [CBConnectPeripheralOptionEnableAutoReconnect: true])
    }

    
    func cancelConnection(_ peripheral: CBPeripheral) {
        if !checkBluetooth() {
            return
        }
        cleanup(peripheral)
        updatePeripheral(peripheral)
    }
    
    
    // step 3: discover service(s) available to peripheral.
    // result send to didDiscoverServices
    // note: peripheral.services will be nil without calling discoverServices
    func discoverServices(_ peripheral: CBPeripheral, serviceUUIDs: [CBUUID]? = nil) {
        if !checkBluetooth() {
            return
        }
        peripheral.discoverServices(serviceUUIDs)
    }
    
    // step 4: discover characteristic and includedServices for a specific service
    // result send to didDiscoverCharacteristicsFor, didDiscoverIncludedServicesFor
    // nil without calling discover
    func discoverServiceDetails(_ peripheral: CBPeripheral, for service: CBService, characteristicUUIDs: [CBUUID]? = nil, includedServiceUUIDs: [CBUUID]? = nil) {
        if !checkBluetooth() {
            return
        }
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
    }
    
    func discoverDescriptors(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic) {
        if !checkBluetooth() {
            return
        }
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    func setNotifying(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic, value: Bool) {
        if !checkBluetooth() {
            return
        }
        if !characteristic.properties.contains(.notify) {
            setError(.setNotifyError(nil))
        }
        peripheral.setNotifyValue(value, for: characteristic)
    }
    
    func readCharacteristicValue(_ peripheral: CBPeripheral, for characteristic: CBCharacteristic) {
        if !checkBluetooth() {
            return
        }
        peripheral.readValue(for: characteristic)
    }
    
    func readDescriptorValue(_ peripheral: CBPeripheral,  for descriptor: CBDescriptor) {
        if !checkBluetooth() {
            return
        }
        peripheral.readValue(for: descriptor)
    }
    
    func writeValue(_ peripheral: CBPeripheral, data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        if !checkBluetooth() {
            return
        }
        switch type {
        case .withoutResponse:
            if !characteristic.properties.contains(.writeWithoutResponse) {
                setError(.writeCharacteristicError("Invalid write type."))
            }
        case .withResponse:
            if !characteristic.properties.contains(.write) {
                setError(.writeCharacteristicError("Invalid write type."))
            }
        @unknown default:
            break
        }
        peripheral.writeValue(data, for: characteristic, type: type)
        // if we write without response and we are not notifying, we need to poll to check if the write is success so that we can update the data to the newest.
        if type == .withoutResponse && !characteristic.isNotifying {
            Task {
                await checkWrite(peripheral, data: data, for: characteristic)
            }
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
            return
        }
    }
    
    
    private func updatePeripheral(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            if let index = self.discoveredPeripherals.firstIndex(where: {$0.identifier == peripheral.identifier}) {
                self.discoveredPeripherals.removeAll(where: {$0.identifier == peripheral.identifier})
                self.discoveredPeripherals.insert(peripheral, at: index)
            } else {
                self.discoveredPeripherals.append(peripheral)
            }
        }
    }
    
    
    private func cleanup(_ peripheral: CBPeripheral) {
        guard let centralManager else {
            setError(.invalidManager)
            return
        }
        
        if peripheral.state == .connected {
            for service in (peripheral.services ?? [] as [CBService]) {
                for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

// MARK: - Central Manager Delegate
extension CentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            setError(.bluetoothNotAvailable)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("central manager will restore: ", dict)
        
        // previously connected peripherals
        let previousPeripheral = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        self.discoveredPeripherals = previousPeripheral
        print("previousPeripheral: ", previousPeripheral)
        
        
        // to keep scanning the previous left over
        // previous service under scan
        let previousScanningService: [CBUUID]? = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID]
        // previous scan options
        let previousScanningOptions = dict[CBCentralManagerRestoredStateScanOptionsKey] as? NSDictionary ?? [:]
        let allowDuplicateKey: Bool = previousScanningOptions[CBCentralManagerScanOptionAllowDuplicatesKey] as? Bool ?? false
        let solicitedServiceUUIDs: [CBUUID] = previousScanningOptions[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] as? [CBUUID] ?? []
        
        let scanningOption = ScanningOption(serviceUUID: previousScanningService, allowDuplicates: allowDuplicateKey, solicitedServiceUUIDs: solicitedServiceUUIDs)
        self.scanningOption = scanningOption

        
        DispatchQueue.main.async {
            self.restoredScanningOption = scanningOption
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("did discover peripheral")
        print(peripheral)
        updatePeripheral(peripheral)
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected ", peripheral)
        peripheral.delegate = self
        discoverServices(peripheral, serviceUUIDs: self.scanningOption.serviceUUID)
        updatePeripheral(peripheral)
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to ", peripheral)
        cancelConnection(peripheral)
        if let error {
            setError(.connectError(error.localizedDescription))
        }
    }
    
    // If the disconnection was not initiated by {@link cancelPeripheralConnection}, the cause will be detailed in the <i>error</i> parameter.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        print("peripheral disconnected: ", peripheral)
        print("is reconnecting: ", isReconnecting)

        // disconnect not being a result of cancelPeripheralConnection
        if let error {
            print("error: ", error)
            setError(.disConnectError(error.localizedDescription))
            // not automatically reconnecting
            if !isReconnecting {
                self.makeConnection(peripheral)
            }
        }
    }

}

extension CentralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("didModifyServices: ", invalidatedServices)
        discoverServices(peripheral, serviceUUIDs: invalidatedServices.map({$0.uuid}))
        self.updatePeripheral(peripheral)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        print("service discovered for peripheral:" , peripheral)
        print("services :" , peripheral.services as Any)
        print(self.discoveredPeripherals.first?.services as Any)
        if let error {
            self.setError(.discoverServicesError(error.localizedDescription))
            return
        }
        self.updatePeripheral(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: (any Error)?) {
        print("discovered included services")
        print("included services :" , service.includedServices as Any)
            
        if let error {
            setError(.discoverIncludedServicesError(error.localizedDescription))
            return
        }
        self.updatePeripheral(peripheral)
    
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        print("characteristic found for service: ", service)
        print(service.characteristics as Any)
        
        for characteristic in service.characteristics ?? [] {
            discoverDescriptors(peripheral, for: characteristic)
            // first read to get the initial value if there is any
            readCharacteristicValue(peripheral, for: characteristic)
        }
        
        if let error {
            setError(.discoverCharacteristicsError(error.localizedDescription))
            return
        }
        self.updatePeripheral(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        print("descriptor found for characteristic: ", characteristic)
        print(characteristic.descriptors as Any)

        if let error {
            setError(.discoverDescriptorError(error.localizedDescription))
            return
        }
        if let userDescriptor = characteristic.descriptors?.first(where: {$0.uuid == CBUUID(string: CBUUIDCharacteristicUserDescriptionString)}) {
            self.readDescriptorValue(peripheral, for: userDescriptor)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error {
            setError(.setNotifyError(error.localizedDescription))
        }
        self.updatePeripheral(peripheral)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        print("didUpdateValueFor", characteristic)

        if let error {
            setError(.updateCharacteristicValueError(error.localizedDescription))
            return
        }
        if let data = characteristic.value,  !data.string.isEmpty  {
            if self.receivedData[characteristic] == nil {
                self.receivedData[characteristic] = []
            }
            self.receivedData[characteristic]?.insert(data, at: 0)
        }
        self.updatePeripheral(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        print("didUpdateValueFor", descriptor)
        if let error {
            setError(.updateDescriptorValueError(error.localizedDescription))
            return
        }
        self.updatePeripheral(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        print("didWriteValueFor")

        if let error {
            print("error writing value")
            setError(.writeCharacteristicError(error.localizedDescription))
            self.updatePeripheral(peripheral)
            return
        } else if !characteristic.isNotifying {
            print("reading value")
            self.readCharacteristicValue(peripheral, for: characteristic)
        }

    }
}
