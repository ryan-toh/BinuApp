//
//  CommentView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

struct CommentView: View {
    @ObservedObject var viewModel: CommentViewModel
    let postId: String

    @State private var showCreateSheet = false
    @State private var editingComment: Comment?

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                }
                List {
                    ForEach(viewModel.comments) { comment in
                        CommentRowView(
                            comment: comment,
                            onEdit: {
                                editingComment = comment
                            },
                            onDelete: {
                                viewModel.deleteComment(forPostId: postId, commentId: comment.id ?? "") { _ in }
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            // Create Comment Sheet
            .sheet(isPresented: $showCreateSheet, onDismiss: {
                viewModel.fetchComments(forPostId: postId)
            }) {
                CreateCommentView(
                    postId: postId,
                    viewModel: viewModel,
                    onDismiss: { showCreateSheet = false }
                )
            }
            // Edit Comment Sheet (using sheet(item:) for safety)
            .sheet(item: $editingComment, onDismiss: {
                viewModel.fetchComments(forPostId: postId)
            }) { editing in
                EditCommentView(
                    postId: postId,
                    comment: editing,
                    viewModel: viewModel,
                    onDismiss: { editingComment = nil }
                )
            }
            .onAppear {
                viewModel.fetchComments(forPostId: postId)
            }
        }
    }
}

