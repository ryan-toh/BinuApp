//
//  BroadcasterService.swift
//  BinuApp
//
//  Created by Ryan on 10/6/25.
//

import CoreBluetooth
import CoreLocation

class BroadcasterService: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    @Published var isBroadcasting = false
    private var peripheralManager: CBPeripheralManager?
    private let beaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
    private let beaconID = "com.example.myibeacon"
    private var beaconRegion: CLBeaconRegion?

    func startBroadcasting() {
        beaconRegion = CLBeaconRegion(uuid: beaconUUID, major: 1, minor: 1, identifier: beaconID)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func stopBroadcasting() {
        peripheralManager?.stopAdvertising()
        isBroadcasting = false
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn, let region = beaconRegion {
            let peripheralData = region.peripheralData(withMeasuredPower: nil)
            peripheralManager?.startAdvertising((peripheralData as NSDictionary) as? [String: Any])
            isBroadcasting = true
        } else {
            isBroadcasting = false
        }
    }
}

