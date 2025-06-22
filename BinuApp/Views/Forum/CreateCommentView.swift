//
//  CreateCommentView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

struct CreateCommentView: View {
    let postId: String
    
    @EnvironmentObject private var authVM: AuthViewModel
    @ObservedObject var viewModel: CommentViewModel
    @State private var newCommentText: String = ""
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Send") {
                    guard let uid = authVM.user?.id else {
                        errorMessage = "You must be signed in to post."
                        showErrorAlert = true
                        return
                    }
                    
                    let comment = Comment(
                        userId: uid,
                        text: newCommentText
                    )
                    viewModel.createComment(forPostId: postId, comment: comment) { error in
                        if let error = error {
                            errorMessage = error
                            showErrorAlert = true
                        } else {
                            onDismiss()
                        }
                    }
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding()

                Spacer()
            }
            .navigationTitle("New Comment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

