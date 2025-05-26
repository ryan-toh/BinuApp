//
//  LoadingSpinnerView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

/// A full-screen loading spinner. Use this when `isLoading == true`.
struct LoadingSpinnerView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    LoadingSpinnerView()
}
