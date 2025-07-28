//
//  PeripheralManaging.swift
//  BinuApp
//
//  Created by Ryan on 29/6/25.
//

import CoreBluetooth

protocol PeripheralManaging: AnyObject {
  var delegate: CBPeripheralManagerDelegate? { get set }
  var state: CBManagerState { get }
  func add(_ service: CBMutableService)
  func startAdvertising(_ advertisementData: [String:Any]?)
  func stopAdvertising()
  func removeAllServices()
}

extension CBPeripheralManager: PeripheralManaging {}
