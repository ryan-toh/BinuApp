//
//  HelpView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var libraryVM: LibraryViewModel
    
    var body: some View {
        NotReadyView()
    }
}

#Preview {
    LibraryView()
}
