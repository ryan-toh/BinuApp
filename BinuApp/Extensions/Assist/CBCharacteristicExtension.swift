//
//  CBCharacteristicExtension.swift
//  BinuApp
//
//  Created by Ryan on 24/7/25.
//

import CoreBluetooth
import Foundation

extension CBCharacteristic {
    var userDescription: String {
        if self.descriptors == nil || self.descriptors!.isEmpty {
            return ""
        }
        let descriptors = self.descriptors!
        for descriptor in descriptors {
            if descriptor.uuid == CBUUID(string: CBUUIDCharacteristicUserDescriptionString) {
                return descriptor.value as? String ?? ""
            }
        }
        return ""
    }
}
