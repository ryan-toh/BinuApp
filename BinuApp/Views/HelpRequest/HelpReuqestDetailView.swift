//
//  HelpReuqestDetailView.swift
//  BinuApp
//
//  Created by Ryan on 10/6/25.
//

import SwiftUI

struct HelpRequestDetailView: View {
    let request: HelpRequest
    @Bindable var viewModel: HelpRequestViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isAccepting = false
    @State private var showError = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Help requested by: \(request.broadcasterId)")
            Text("Status: \(request.status)")
            if request.status == "pending" {
                Button(isAccepting ? "Accepting..." : "Accept Help") {
                    Task {
                        isAccepting = true
                        let receiverId = "currentUserId"
                        let success = await viewModel.acceptHelpRequest(request: request, receiverId: receiverId)
                        isAccepting = false
                        if success {
                            dismiss()
                        } else {
                            showError = true
                        }
                    }
                }
                .disabled(isAccepting)
                .buttonStyle(.borderedProminent)
            } else if request.status == "accepted" {
                Text("Help accepted by: \(request.receiverId ?? "Unknown")")
            } else if request.status == "completed" {
                Text("Help request completed.")
            }
            Button("Close", role: .cancel) { dismiss() }
                .padding(.top)
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}


