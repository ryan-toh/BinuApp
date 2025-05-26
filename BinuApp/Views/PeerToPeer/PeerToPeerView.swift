//
//  PeerToPeerView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct PeerToPeerView: View {
    @EnvironmentObject var helpVM: PeerToPeerViewModel
    
    var body: some View {
        NotReadyView()
    }
}

#Preview {
    PeerToPeerView()
}
