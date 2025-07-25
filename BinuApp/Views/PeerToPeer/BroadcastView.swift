import SwiftUI
import MapKit

struct BroadcastView: View {
    @StateObject private var viewModel = BroadcastViewModel()
    @State private var latitude = ""
    @State private var longitude = ""

    var body: some View {
        VStack(spacing: 20) {
            /*
            Picker("Item", selection: $viewModel.selectedItem) {
                ForEach(Item.allCases, id: \.self) { item in
                    Text(item.rawValue.capitalized)
                        .tag(item)
                }
            }
            .pickerStyle(MenuPickerStyle())
             */

            Button(action: {
                if viewModel.isBroadcasting {
                    viewModel.stopBroadcasting()
                } else {
                    viewModel.startBroadcasting()
                }
            }) {
                Text(viewModel.isBroadcasting ? "Stop Broadcasting" : "Start Broadcasting")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke())
            }

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
                .disabled(!viewModel.isBroadcasting)
            }
            .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("Broadcaster")
    }
}

