//
//  CreateCommentView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

struct CreateCommentView: View {
    let postId: String
    @ObservedObject var viewModel: CommentViewModel
    @State private var newCommentText: String = ""
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Send") {
                    let comment = Comment(
                        userId: "currentUserId",
                        text: newCommentText
                    )
                    viewModel.createComment(forPostId: postId, comment: comment) { success in
                        if success { onDismiss() }
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
        }
    }
}
