//
//  BroadcastTestView.swift
//  BinuApp
//
//  Created by Ryan on 29/6/25.
//


import SwiftUI
import CoreLocation

/// A simple SwiftUI view to test the BroadcastService.
/// Allows entering an Item (by raw UInt8), latitude, and longitude, then starting/stopping BLE broadcasts.
struct BroadcastTestView: View {
    @StateObject private var broadcastService = BroadcastService()
    @State private var rawItemValue: String = "1"
    @State private var latitudeText: String = "1.3521"
    @State private var longitudeText: String = "103.8198"

    var body: some View {
        VStack(spacing: 20) {
            Text("Broadcast Test").font(.largeTitle)

            HStack {
                Text("Item (UInt8):")
                TextField("e.g. 1", text: $rawItemValue)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            HStack {
                Text("Latitude:")
                TextField("e.g. 1.3521", text: $latitudeText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            HStack {
                Text("Longitude:")
                TextField("e.g. 103.8198", text: $longitudeText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            Button(action: startBroadcast) {
                Text("Start Broadcasting")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: broadcastService.stopBroadcasting) {
                Text("Stop Broadcasting")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("Broadcasting: \(broadcastService.isBroadcasting ? "Yes" : "No")")
                .font(.headline)
                .padding(.top)

            Spacer()
        }
        .padding()
    }

    private func startBroadcast() {
        guard let raw = UInt8(rawItemValue),
              let item = Item(rawValue: raw),
              let lat = Double(latitudeText),
              let lon = Double(longitudeText) else {
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        broadcastService.startBroadcasting(item: item, coordinates: coordinate)
    }
}

#Preview {
    BroadcastTestView()
}
