//
//  CBCharacteristicPropertiesExtension.swift
//  BinuApp
//
//  Created by Ryan on 24/7/25.
//

import CoreBluetooth
import Foundation

extension CBCharacteristicProperties {
    var string: String {
        var results: [String] = []
        for option: CBCharacteristicProperties in [.read, .writeWithoutResponse, .write, .notify] {
            guard self.contains(option) else { continue }
            switch option {
            case .read: results.append("read")
            case .writeWithoutResponse, .write:
                if self.contains(.writeWithoutResponse) {
                    results.append("write(without response)")
                } else {
                    results.append("write")
                }
            case .notify: results.append("notify")
            default: fatalError()
            }
        }
        
        if results.isEmpty {
            return "(none)"
        }
        
        return results.joined(separator: ", ")
    }
}
