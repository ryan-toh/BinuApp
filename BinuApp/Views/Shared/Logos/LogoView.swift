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
        Image("NewLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 25
                )
            )
    }
}

#Preview {
    LogoView()
}
