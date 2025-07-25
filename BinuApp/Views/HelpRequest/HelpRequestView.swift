//
//  HelpRequestView.swift
//  BinuApp
//
//  Created by Ryan on 14/6/25.
//

import SwiftUI

struct HelpRequestView: View {
    @EnvironmentObject var viewModel: HelpRequestViewModel
    
    var body: some View {
        VStack {
            switch viewModel.uiState {
            case .broadcast:
                Button("Broadcast Request") {
                    let item = Item(id: UUID().uuidString, name: "Sanitary Pad")
                    viewModel.broadcastRequest(item: item)
                }
            case .waiting:
                Text("Waiting for someone to accept your request...")
            case .accepted:
                if let proximity = viewModel.proximity {
                    Text(proximity == .near ? "Help is near" : "Help is still a while more away")
                }
                Button("Help has arrived.") {
                    viewModel.completeRequest()
                }
            case .completed:
                Text("Request Completed")
            }
        }
        .onAppear {
            viewModel.listenForNearbyRequests()
        }
    }
}

#Preview {
    HelpRequestView().environmentObject(HelpRequestViewModel(userId: "abc123"))
}
