//
//  PeerToPeerView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct PeerToPeerView: View {
    @StateObject private var broadcaster = BroadcasterService()

    var body: some View {
        VStack(spacing: 20) {
            Text(broadcaster.isBroadcasting ? "Broadcasting as iBeacon" : "Not Broadcasting")
                .font(.headline)
            Button(broadcaster.isBroadcasting ? "Stop" : "Start") {
                if broadcaster.isBroadcasting {
                    broadcaster.stopBroadcasting()
                } else {
                    broadcaster.startBroadcasting()
                }
            }
            .padding()
            .background(broadcaster.isBroadcasting ? Color.red : Color.green)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding()
    }
}

//
//#Preview {
//    PeerToPeerView()
//}
