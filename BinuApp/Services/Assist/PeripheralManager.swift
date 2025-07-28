//
//  PeripheralManager.swift
//  BinuApp
//
//  Created by Ryan on 22/7/25.
//

import SwiftUI
import CoreBluetooth


// Sender
enum PeripheralManagerError: Error {
    case invalidManager
    case bluetoothNotAvailable
    
    case addServiceError(String)
    case removeServiceError(String)
    case startAdvertisingError(String)

    case updateValueError(String)
}


@Observable
class PeripheralManager: NSObject {
    var lastWrittenValue: String = ""
    private(set) var writableCharacteristic: CBMutableCharacteristic?
    
    // Helper Function
//    func createSingleWritableService(withDescription description: String) -> CBMutableService {
//        // 1. Create the characteristic
//        let characteristic = CBMutableCharacteristic(
//            type: CBUUID(string: "E100"), // random char UUID
//            properties: [.write, .read],
//            value: nil,
//            permissions: [.readable, .writeable]
//        )
//        // 2. Add the description as a User Description descriptor
//        let descriptor = CBMutableDescriptor(
//            type: CBUUID(string: CBUUIDCharacteristicUserDescriptionString),
//            value: description
//        )
//        characteristic.descriptors = [descriptor]
//        // 3. Create the service with the fixed UUID and assign the characteristic
//        let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
//        let service = CBMutableService(type: serviceUUID, primary: true)
//        service.characteristics = [characteristic]
//        return service
//    }
    
    func createSingleWritableService(withDescription description: String) -> CBMutableService {
        let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
        let charUUID = CBUUID(string: "E100")
        let service = CBMutableService(type: serviceUUID, primary: true)
        let properties: CBCharacteristicProperties = [.write, .read]
        let permissions: CBAttributePermissions = [.writeable, .readable]
        let char = CBMutableCharacteristic(
            type: charUUID,
            properties: properties,
            value: nil, // value will be set dynamically
            permissions: permissions
        )
        // Descriptor for description
        let userDescription = CBMutableDescriptor(type: CBUUID(string:CBUUIDCharacteristicUserDescriptionString), value: description)
        char.descriptors = [userDescription]
        self.writableCharacteristic = char // Store for updates
        service.characteristics = [char]
        return service
    }
    
    var error: PeripheralManagerError? = nil {
        didSet {
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.error = nil
                }
            }
        }
    }

    // changes in subscribedCentrals WILL NOT TRIGGER ANY VIEW UPDATES
    // need to add some other variables and increment it in the delegation methods to force view to update
    var subscribedCentrals: [CBCharacteristic: [CBCentral]] = [:]
    var addedServices: [CBMutableService]  = []
    var characteristicData: [CBCharacteristic: [Data]] = [:]

    private var peripheralManager: CBPeripheralManager?
    private let managerUID: NSString = "ItsukiPeripheralManager"
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [
            CBPeripheralManagerOptionShowPowerAlertKey: true,
            // allow state restore
            CBPeripheralManagerOptionRestoreIdentifierKey: managerUID
        ])
    }

}
    
extension PeripheralManager {
    

    
    
    private func checkBluetooth() -> Bool {
        if peripheralManager?.state != .poweredOn {
            self.error = .bluetoothNotAvailable
            return false
        }
        return true
    }

    @MainActor
    func addService(_ service: CBMutableService) {
        if !checkBluetooth() {
            return
        }

        guard let peripheralManager else {
            self.error = .invalidManager
            return
        }
        if self.addedServices.contains(where: {$0.uuid == service.uuid}) {
            self.error = .addServiceError("Service exists.")
            return
        }
        service.characteristics?.forEach {
            if !validateCharacteristic($0 as? CBMutableCharacteristic) {
                return
            }
        }
        
        service.includedServices?.forEach {
            if !validateIncludedServices($0) {
                return
            }
        }

        peripheralManager.add(service)
        self.addedServices.append(service)
    }
    
    
    // Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Characteristics with cached values must be read-only'
    // cached value: characteristic init with value set to non-nil
    private func validateCharacteristic(_ characteristic: CBMutableCharacteristic?) -> Bool {
        if let characteristic  {
            if characteristic.value != nil && (characteristic.properties != .read || characteristic.permissions != .readable ){
                self.error = .addServiceError("Characteristics with cached values must be read-only")
                return false
            }
            if (characteristic.properties.contains(.read) && !characteristic.permissions.contains(.readable)) || ((characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)) && !characteristic.permissions.contains(.writeable)) {
                self.error = .addServiceError("Permission and Properties mismatch.")
                return false
            }
            if characteristic.properties.contains(.broadcast) || characteristic.properties.contains(.extendedProperties) {
                self.error = .addServiceError("Broadcast and extended properties are not supported for local peripheral service.")
                return false

            }
        }
        return true
    }
    
    private func validateIncludedServices(_ service: CBService) -> Bool {
        let valid = self.addedServices.contains(where: {$0.uuid == service.uuid})
        if !valid {
            self.error = .addServiceError("Included Service must first be publish.")
        }
        return valid
    }
    
    
    // NSException if removing a service that is included in other services
    @MainActor
    func removeService(_ service: CBMutableService) {
        if !checkBluetooth() {
            return
        }
        guard let peripheralManager else {
            self.error = .invalidManager
            return
        }
        
        for addedService in self.addedServices {
            if addedService.includedServices?.contains(where: {$0.uuid == service.uuid}) == true {
                self.error = .removeServiceError("Service in included in another service and cannot be removed.")
                return
            }
        }
        
        self.addedServices.removeAll(where: {$0 == service})
        peripheralManager.remove(service)
    }

    @MainActor
    func startAdvertising() {
        if !checkBluetooth() {
            return
        }
        if addedServices.isEmpty {
            error = .startAdvertisingError("Please add service(s) to advertise.")
            return
        }
        
        guard let peripheralManager else {
            self.error = .invalidManager
            return
        }
        
        if peripheralManager.state != .poweredOn {
            stopAdvertising()
            error = .bluetoothNotAvailable
            return
        }
        
        let serviceUUIDs: [CBUUID] = addedServices.map({$0.uuid})
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: serviceUUIDs,
//            CBAdvertisementDataLocalNameKey: peripheralName ?? "(null)"
        ])
    }

    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }

    
    @MainActor
    func updateValue(_ data: Data, for characteristic: CBCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) {
        if !checkBluetooth() {
            return
        }

        do {
            try updateValueHelper(data, for: self.addedServices.first!.characteristics!.first!, onSubscribedCentrals: centrals)
        } catch(let error) {
            if let error = error as? PeripheralManagerError {
                self.error = error
            }
        }
    }

    @MainActor
    private func updateValueHelper(_ data: Data, for characteristic: CBCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) throws {
        
        let mtu = centrals == nil || centrals!.isEmpty ? 512 : centrals!.map({$0.maximumUpdateValueLength}).min() ?? 512
        if data.count > mtu {
            throw PeripheralManagerError.updateValueError("Data is too long.")
        }
        
        guard let peripheralManager else {
            throw PeripheralManagerError.invalidManager
        }
        guard let mutable = characteristic as? CBMutableCharacteristic else {
            throw PeripheralManagerError.updateValueError("Characteristic cannot be convert to mutable")
        }
        
        // true if the update could be sent,
        let result = peripheralManager.updateValue(data, for: mutable, onSubscribedCentrals: centrals)
        
        if result {
            if self.characteristicData[characteristic] == nil {
                self.characteristicData[characteristic] = []
            }
            self.characteristicData[characteristic]?.insert(data, at: 0)
        } else {
            self.error = .updateValueError("Failed to update value. Transmit queue is full. Please try again later.")
        }

    }
    
}

// MARK: - Peripheral Manager Delegate
extension PeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state != .poweredOn {
            self.error = .bluetoothNotAvailable
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("will restore: ", dict)
        
        let perviousServices = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] ?? []
        
        DispatchQueue.main.async {
            self.addedServices = perviousServices
            for service in perviousServices {
                guard let characteristics = service.characteristics else { continue }
                for characteristic in characteristics {
                    guard let mutable = characteristic as? CBMutableCharacteristic else { continue }
                    self.subscribedCentrals[characteristic] = mutable.subscribedCentrals
                }
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: (any Error)?) {
        DispatchQueue.main.async {
            if let error {
                self.addedServices.removeAll(where: {$0.uuid == service.uuid})
                self.error = .addServiceError(error.localizedDescription)
                return
            }
        }
    }
    
    
    // communication related
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        print("did start advertising: \(String(describing: error))")
        if let error {
            DispatchQueue.main.async {
                self.error = .startAdvertisingError(error.localizedDescription)
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("subscribed to ", central)
        print("characteristic ", characteristic)

        DispatchQueue.main.async {
            self.subscribedCentrals[characteristic]?.removeAll(where: {$0 == central})
            if self.subscribedCentrals[characteristic] == nil {
                self.subscribedCentrals[characteristic] = []
            }
            self.subscribedCentrals[characteristic]?.append(central)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        DispatchQueue.main.async {
            self.subscribedCentrals[characteristic]?.removeAll(where: {$0 == central})
        }
    }
    
    // invoked when Central made a read request
    // to have central receive the value of the characteristic, need to be set using request.value
    // otherwise, central will not receive any update on the value of the characteristic in peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?)
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("peripheral receive read request")
        // set the value of the request to be what we want the central to receive.
        // Otherwise, central side will always receive an empty value in didUpdateValueFor method
        request.value = self.characteristicData[request.characteristic]?.first as? Data ?? request.characteristic.value
        peripheral.respond(to: request, withResult: .success)
        
    }
    
    
    // invoked when Central made a write request
    // handle the request (update the value)
    // respond using respondToRequest:withResult:
//    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
//        print("peripheral receive write request")
//        var data = Data()
//
//        for aRequest in requests {
//            guard var requestValue = aRequest.value else {
//                    continue
//            }
//
//            requestValue = requestValue.dropFirst(aRequest.offset)
//            data.append(requestValue)
//            print("Received write request of \(requestValue.count) bytes: \(requestValue.string)")
//        }
//        
//        if let firstRequest = requests.first {
//            DispatchQueue.main.async {
//                do {
//                    try self.updateValueHelper(data, for: firstRequest.characteristic, onSubscribedCentrals: nil)
//                    peripheral.respond(to: firstRequest, withResult: .success)
//                } catch(let error) {
//                    if let error  = error as? PeripheralManagerError {
//                        self.error = error
//                    }
//                    peripheral.respond(to: firstRequest, withResult: .invalidHandle)
//                }
//            }
//        }
//    }
//    
    // For processing central text
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let char = writableCharacteristic, request.characteristic.uuid == char.uuid, let value = request.value, let str = String(data: value, encoding: .utf8) {
                self.lastWrittenValue = str // update observable value
                char.value = value // update underlying CBMutableCharacteristic value
            }
            peripheral.respond(to: request, withResult: .success)
        }
    }
}
