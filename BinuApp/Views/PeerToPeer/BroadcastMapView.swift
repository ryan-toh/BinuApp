import SwiftUI
import CoreLocation

struct BroadcastMapView: View {
    let requestType: String
    let username: String

    @StateObject private var broadcaster = BroadcasterService()
    @State private var hasCalledForHelp = false
    @State private var locationManager = CLLocationManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("BGColor").ignoresSafeArea()

            VStack(spacing: 24) {
                Text("📡 Broadcasting Request")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color("FontColor"))

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("🙋‍♀️ Requester:")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text(username)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("FontColor"))
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("🧻 Request:")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text(requestType.capitalized)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("FontColor"))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .frame(maxWidth: 320)

                if !broadcaster.isBroadcasting {
                    Text("Broadcasting...")
                        .font(.subheadline)
                        .foregroundColor(Color("FontColor"))
                        .padding(.top)
                } else {
                    Text("Bluetooth is off or not broadcasting")
                        .font(.subheadline)
                        .foregroundColor(Color("FontColor"))
                        .padding(.top)
                }

                // Stop Button
                Button(action: {
                    broadcaster.stopBroadcasting()
                    dismiss()
                }) {
                    Text("Stop Broadcasting")
                        .foregroundColor(Color("BGColor"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color("FontColor"))
                        .cornerRadius(24)
                        .font(.headline)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            broadcaster.startBroadcasting()
            handleBroadcast()
        }
        .onDisappear {
            broadcaster.stopBroadcasting()
        }
        .navigationTitle("Broadcasting")
    }

    // placeholder function for broadcasting request
    private func handleBroadcast() {
        
        //ensures function is called once only
        guard !hasCalledForHelp else { return }

        if let location = locationManager.location {
            // TODO: Replace this with your actual function, eg.
            // callForHelp(username: username, item: requestType, location: location)
        }

        hasCalledForHelp = true
    }
}

#Preview {
    BroadcastMapView(requestType: "pads", username: "eungi")
}
