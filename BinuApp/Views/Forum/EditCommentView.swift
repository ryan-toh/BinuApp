//
//  EditCommentView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

// TODO: Fix Edit Comment
struct EditCommentView: View {
    let postId: String
    var comment: Comment
    @EnvironmentObject private var authVM: AuthViewModel
    @ObservedObject var viewModel: CommentViewModel
    @State private var updatedText: String
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    var onDismiss: () -> Void

    init(postId: String, comment: Comment, viewModel: CommentViewModel, onDismiss: @escaping () -> Void) {
        self.postId = postId
        self.comment = comment
        self.viewModel = viewModel
        _updatedText = State(initialValue: comment.text)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Edit comment...", text: $updatedText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Update") {
                    var edited = comment
                    edited.text = updatedText
                    viewModel.updateComment(forPostId: postId, comment: edited) { error in
                        if let error = error {
                            errorMessage = error
                            showErrorAlert = true
                        } else {
                            onDismiss()
                        }
                    }
                }
                .disabled(updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding()

                Spacer()
            }
            .navigationTitle("Edit Comment")
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
