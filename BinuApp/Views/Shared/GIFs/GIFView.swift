//
//  GIFView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

/// A SwiftUI wrapper for displaying a looping GIF
struct GIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.image = UIImage.gif(name: gifName)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Nothing needed here; the GIF loops automatically
    }
}


#Preview {
    GIFView(gifName: "waves")
}
