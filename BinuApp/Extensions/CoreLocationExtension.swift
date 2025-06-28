//
//  CoreLocationExtension.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import CoreLocation
import Foundation

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

