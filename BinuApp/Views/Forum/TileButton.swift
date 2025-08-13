//
//  TileButton.swift
//  BinuApp
//
//  Created by Ryan on 13/8/25.
//

import SwiftUI

struct TileButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(tint.gradient)
            )
            .shadow(color: tint.opacity(0.25), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}
