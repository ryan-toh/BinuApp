//
//  StringExtension.swift
//  BinuApp
//
//  Created by Ryan on 24/7/25.
//

import Foundation
import CoreBluetooth

extension String {
    var data: Data? {
        self.data(using: .utf8)
    }

     var cbUUIDs: [CBUUID]?  {
        if self.isEmpty {
            return nil
        }
        let array = self.split(separator: ",")
        let uuids: [UUID?] = array.map({UUID(uuidString: $0.trimmingCharacters(in: .whitespacesAndNewlines))})
        let nonNil = uuids.filter({$0 != nil}).map({$0!})
        return nonNil.map({CBUUID(nsuuid: $0)})
    }
}
