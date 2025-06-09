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
    @State private var showEditSheet = false

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
                                showEditSheet = true
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
            .sheet(isPresented: $showCreateSheet) {
                CreateCommentView(
                    postId: postId,
                    viewModel: viewModel,
                    onDismiss: { showCreateSheet = false }
                )
            }
            .sheet(isPresented: $showEditSheet) {
                if let editing = editingComment {
                    EditCommentView(
                        postId: postId,
                        comment: editing,
                        viewModel: viewModel,
                        onDismiss: { showEditSheet = false }
                    )
                }
            }
            .onAppear {
                viewModel.fetchComments(forPostId: postId)
            }
        }
    }
}

