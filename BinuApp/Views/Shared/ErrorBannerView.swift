//
//  ErrorBannerView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

/// A simple banner view that displays an error message in a red background.
struct ErrorBannerView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundColor(.white)
            .font(.body)
            .multilineTextAlignment(.center)
            .padding()
            .background(Color.red)
            .cornerRadius(8)
            .padding(.horizontal)
    }
}


#Preview {
    ErrorBannerView(message: "Preview Error")
}
