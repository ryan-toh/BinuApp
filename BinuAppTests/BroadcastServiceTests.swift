//
//  BroadcastServiceTests.swift
//  BinuApp
//
//  Created by Ryan on 29/6/25.
//

import XCTest
import CoreLocation
@testable import BinuApp
import CoreBluetooth

class BroadcastServiceTests: XCTestCase {
  var fakeMgr: FakePeripheralManager!
  var svc: BroadcastService!

  override func setUp() {
    super.setUp()
    fakeMgr = FakePeripheralManager()
    svc    = BroadcastService(peripheralManager: fakeMgr)
  }

  func testStartBroadcastingAddsServiceAndAdvertises() {
    // Given
    let coords = CLLocationCoordinate2D(latitude: 12.34, longitude: 56.78)

    // When
      svc.startBroadcasting(item: .sanitaryPad, coordinates: coords)

    // Then
    // 1. It should have created & added exactly one CBMutableService
    XCTAssertEqual(fakeMgr.addedServices.count, 1)
    let added = fakeMgr.addedServices.first!
    XCTAssertEqual(added.uuid, CBUUID(string: "A0F0FFA0-1B9F-4E8F-BB8D-6F9A8E7D5C4A"))

    // 2. It should be advertising that same service UUID
    let advertisedUUIDs = fakeMgr.advertisedData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    XCTAssertTrue(advertisedUUIDs?.contains(added.uuid) == true)

    // 3. It should use the item’s rawValue as the local name
    let localName = fakeMgr.advertisedData?[CBAdvertisementDataLocalNameKey] as? String
      XCTAssertEqual(localName, String(Item.sanitaryPad.rawValue))

    // 4. And its flag should flip
    XCTAssertTrue(svc.isBroadcasting)
  }

  func testStopBroadcastingClearsEverything() {
    // Pre-populate some state
    svc.isBroadcasting = true
    fakeMgr.addedServices = [CBMutableService(type: CBUUID(), primary: true)]
    fakeMgr.advertisedData = ["dummy":"value"]

    // When
    svc.stopBroadcasting()

    // Then
    XCTAssertFalse(svc.isBroadcasting)
    XCTAssertTrue(fakeMgr.addedServices.isEmpty)
    XCTAssertNil(fakeMgr.advertisedData)
  }
}

class FakePeripheralManager: PeripheralManaging {
  var delegate: CBPeripheralManagerDelegate?
  var state: CBManagerState = .poweredOn

  var addedServices: [CBMutableService] = []
  var advertisedData: [String:Any]?

  func add(_ service: CBMutableService) {
    addedServices.append(service)
  }
  func startAdvertising(_ advertisementData: [String : Any]?) {
    self.advertisedData = advertisementData
  }
  func stopAdvertising() {
    advertisedData = nil
  }
  func removeAllServices() {
    addedServices.removeAll()
  }
}

