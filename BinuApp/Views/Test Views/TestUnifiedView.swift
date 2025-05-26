//
//  TestUnifiedView.swift
//  BinuApp
//
//  Created by Ryan on 26/5/25.
//

import SwiftUI

struct TestUnifiedView: View {
    var body: some View {
        VStack {
            TestUploadView()
            TestAuthView()
        }
    }
}

#Preview {
    TestUnifiedView()
}
