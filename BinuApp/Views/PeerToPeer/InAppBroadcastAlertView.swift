//
//  InAppBroadcastAlertView.swift
//  BinuApp
//
//  Created by Hong Eungi on 28/6/25.
//

import SwiftUI

struct InAppBroadcastAlert: View {
    let request: BroadcastRequest
    var dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("🚨 Help Requested Nearby")
                .font(.headline)
                .bold()
            Text("\(request.username) needs \(request.request).")
            Text("Location: \(String(format: "%.4f", request.location.latitude)), \(String(format: "%.4f", request.location.longitude))")
                .font(.footnote)
                .foregroundColor(.gray)
            Button("Dismiss") {
                dismiss()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
    }
}


#Preview {
    InAppBroadcastAlert()
}
