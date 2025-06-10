//
//  HelpRequestListView.swift
//  BinuApp
//
//  Created by Ryan on 10/6/25.
//

import SwiftUI
import FirebaseFirestore

struct HelpRequestListView: View {
    @State private var viewModel = HelpRequestViewModel()
    @State private var selectedRequest: HelpRequest?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List(viewModel.helpRequests) { request in
                VStack(alignment: .leading) {
                    Text("Help requested by: \(request.broadcasterId)")
                    Text("Status: \(request.status)")
                }
                .contentShape(Rectangle())
                .onTapGesture { selectedRequest = request }
            }
            .navigationTitle("Nearby Help Requests")
            .task {
                let uuid = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
                await viewModel.fetchPendingRequests(uuid: uuid)
            }
            .sheet(item: $selectedRequest) { request in
                HelpRequestDetailView(request: request, viewModel: viewModel)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}
