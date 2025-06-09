//
//  EditCommentView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

struct EditCommentView: View {
    let postId: String
    var comment: Comment
    @ObservedObject var viewModel: CommentViewModel
    @State private var updatedText: String
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
                    viewModel.updateComment(forPostId: postId, comment: edited) { success in
                        if success { onDismiss() }
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
        }
    }
}
