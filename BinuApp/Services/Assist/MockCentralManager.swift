// MockCentralManager.swift

import CoreBluetooth
@testable import BinuApp

class MockCentralManager: CentralManaging {
    var delegate: CBCentralManagerDelegate?
    var state: CBManagerState = .poweredOn

    var scanForPeripheralsCalled = false
    var stopScanCalled = false
    var connectCalled: CBPeripheral?
    var cancelPeripheralConnectionCalled: CBPeripheral?

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        scanForPeripheralsCalled = true
    }
    func stopScan() { stopScanCalled = true }
    func connect(_ peripheral: CBPeripheral, options: [String : Any]?) {
        connectCalled = peripheral
    }
    func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        cancelPeripheralConnectionCalled = peripheral
    }
}

class MockPeripheral: CBPeripheral {
    var servicesSet = false
    override var services: [CBService]? {
        get { servicesSet ? [CBMutableService(type: CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"), primary: true)] : nil }
        set { /* ignore */ }
    }
    var discoverServicesCalledWith: [CBUUID]?
    override func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesCalledWith = serviceUUIDs
        servicesSet = true
    }
}
