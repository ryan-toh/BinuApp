//
//  SwiftUIView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        // Workaround as AppIcon asset is blocked from the image name space
        Image(uiImage: (UIImage(named:"AppIcon"))! )
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 25
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 25
                )
                .stroke(.white, lineWidth: 4)
        }
    }
}

#Preview {
    LogoView()
}
