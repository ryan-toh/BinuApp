//
//  ReceiverView.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

import SwiftUI
import MapKit

struct ReceiverView: View {
    @StateObject private var viewModel = ReceiverViewModel()
    @State private var userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(spacing: 16) {
            if let item = viewModel.discoveredItem {
                Text("Nearby broadcast: \(item.description)")
                    .font(.headline)
            } else {
                Text("Scanning for broadcasts...")
                    .foregroundColor(.secondary)
            }
            
            if let location = viewModel.broadcasterLocation {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                )))
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)
                Text("Broadcaster's Location")
                    .font(.subheadline)
            }
            
            Button("Send My Location") {
                // For demo, use a fixed location or get from CoreLocation
                let myLocation = userLocation ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                viewModel.sendLocation(myLocation)
            }
            .disabled(viewModel.discoveredItem == nil)
            .padding()
        }
    }

//    var body: some View {
//        VStack {
//            HStack {
//                Button("Start Browsing") {
//                    viewModel.startBrowsing()
//                }
//                .padding(.horizontal)
//
//                Button("Stop Browsing") {
//                    viewModel.stopBrowsing()
//                }
//                .padding(.horizontal)
//            }
//            /*
//            List {
//                Section(header: Text("Found Requests")) {
//                    ForEach(viewModel.foundRequests, id: \.peer) { req in
//                        HStack {
//                            Text(req.item.rawValue.capitalized)
//                            Spacer()
//                            Text(req.peer.displayName)
//                            Button("Connect") {
//                                viewModel.connect(to: req.peer)
//                            }
//                        }
//                    }
//                }
//             
//                Section(header: Text("Connected Peers")) {
//                    ForEach(viewModel.connectedPeers, id: \.self) { peer in
//                        Text(peer.displayName)
//                    }
//                }
//            }
//             */
//
//            VStack {
//                TextField("Latitude", text: $latitude)
//                    .keyboardType(.decimalPad)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//
//                TextField("Longitude", text: $longitude)
//                    .keyboardType(.decimalPad)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//
//                Button("Send Location") {
//                    if let lat = Double(latitude), let lon = Double(longitude) {
//                        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
//                        viewModel.sendLocation(coord)
//                    }
//                }
//                .disabled(viewModel.connectedPeers.isEmpty)
//            }
//            .padding()
//        }
//        .navigationTitle("Receiver")
//    }
}


