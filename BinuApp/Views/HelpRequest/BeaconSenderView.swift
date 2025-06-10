import SwiftUI
import CoreLocation
import FirebaseFirestore

struct BeaconSenderView: View {
    @State private var viewModel = HelpRequestViewModel()
    @State private var isBroadcasting = false
    @State private var showError = false

    var body: some View {
        VStack(spacing: 20) {
            Text(isBroadcasting ? "Broadcasting Help Request" : "Not Broadcasting")
                .font(.headline)
            Button(isBroadcasting ? "Stop" : "Start") {
                Task {
                    if isBroadcasting {
                        isBroadcasting = false
                        // Optionally close request in Firestore
                    } else {
                        let uuid = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
                        let location = GeoPoint(latitude: 37.7749, longitude: -122.4194)
                        let broadcasterId = "currentUserId"
                        let success = await viewModel.createHelpRequest(
                            broadcasterId: broadcasterId,
                            uuid: uuid,
                            location: location
                        )
                        if success {
                            isBroadcasting = true
                        } else {
                            showError = true
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isBroadcasting ? .red : .green)
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

