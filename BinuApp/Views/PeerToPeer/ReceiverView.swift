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
    @State private var latitude = ""
    @State private var longitude = ""

    var body: some View {
        VStack {
            HStack {
                Button("Start Browsing") {
                    viewModel.startBrowsing()
                }
                .padding(.horizontal)

                Button("Stop Browsing") {
                    viewModel.stopBrowsing()
                }
                .padding(.horizontal)
            }
            /*
            List {
                Section(header: Text("Found Requests")) {
                    ForEach(viewModel.foundRequests, id: \.peer) { req in
                        HStack {
                            Text(req.item.rawValue.capitalized)
                            Spacer()
                            Text(req.peer.displayName)
                            Button("Connect") {
                                viewModel.connect(to: req.peer)
                            }
                        }
                    }
                }
             
                Section(header: Text("Connected Peers")) {
                    ForEach(viewModel.connectedPeers, id: \.self) { peer in
                        Text(peer.displayName)
                    }
                }
            }
             */

            VStack {
                TextField("Latitude", text: $latitude)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Longitude", text: $longitude)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send Location") {
                    if let lat = Double(latitude), let lon = Double(longitude) {
                        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        viewModel.sendLocation(coord)
                    }
                }
                .disabled(viewModel.connectedPeers.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Receiver")
    }
}


