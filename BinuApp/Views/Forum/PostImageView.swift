//
//  ImageLoader 2.swift
//  Binu
//
//  Created by Ryan on 26/8/25.
//


// 1) Add these helpers once (e.g., in the same file or a shared file)

import SwiftUI

struct PostImageView: View {
    let url: URL
    @StateObject private var loader = ImageLoader()

    var body: some View {
        ZStack {
            // Reserve height so the row doesn't collapse while loading
            Rectangle().opacity(0.0001).frame(height: 150)

            if let uiImage = loader.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .clipped()
                    .cornerRadius(8)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
            }
        }
        .task(id: url) {                // restarts when the cell reappears or URL changes
            await loader.load(from: url)
        }
    }
}
