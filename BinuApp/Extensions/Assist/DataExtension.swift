//
//  DataExtension.swift
//  BinuApp
//
//  Created by Ryan on 24/7/25.
//

import Foundation

extension Data {
    var string: String {
        String(data: self, encoding: .utf8) ?? ""
    }
}


