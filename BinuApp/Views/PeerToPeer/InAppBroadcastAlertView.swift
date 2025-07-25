//
//  InAppBroadcastAlertView.swift
//  BinuApp
//
//  Created by Hong Eungi on 28/6/25.
//

import SwiftUI
import CoreLocation

struct InAppBroadcastAlertView: View {
    let request: BroadcastRequest
    var dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("🚨 Help Requested Nearby")
                .foregroundColor(Color("FontColor"))
                .font(.headline)
                .bold()
            Text("\(request.username) needs \(request.request).")
                .foregroundColor(Color("FontColor"))
            Text("Location: \(String(format: "%.4f", request.location.latitude)), \(String(format: "%.4f", request.location.longitude))")
                .font(.footnote)
                .foregroundColor(.gray)
            Button("Dismiss") {
                dismiss()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(Color("BGColor")))
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
    }
}


#Preview {
    InAppBroadcastAlertView(
        request: BroadcastRequest(
            username: "eungi",
            request: "Pads",
            location: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        ),
        dismiss: {}
    )
}
