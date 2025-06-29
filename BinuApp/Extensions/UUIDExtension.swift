//
//  UUIDExtension.swift
//  BinuApp
//
//  Created by Ryan on 29/6/25.
//

import Foundation

// MARK: To convert from UUID to Data efficiently
// Used for iBeacon Services
extension UUID {
    init?(data: Data) {
        guard data.count == 16 else { return nil }
        self = data.withUnsafeBytes { $0.load(as: UUID.self) }
    }
    
    var data: Data {
        withUnsafeBytes(of: self) { Data($0) }
    }
}
