//
//  CombinedCommentView.swift
//  BinuApp
//
//  Created by Hong Eungi on 13/7/25.
//

import SwiftUI

/**
 Displays the Post + Comments underneath as a single view.
 */
struct CombinedCommentView: View {
    let post: Post
    @StateObject private var commentVM: CommentViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var postVM: PostViewModel

    @State private var showCreateSheet = false
    @State private var editingComment: Comment?
    

    // For preview
    init(post: Post, previewViewModel: CommentViewModel? = nil) {
        _commentVM = StateObject(wrappedValue: previewViewModel ?? CommentViewModel())
        self.post = post
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Post section
                PostRowView(post: post, isTappable: false)
                    .environmentObject(authVM)
                    .environmentObject(ForumViewModel())
                    .environmentObject(postVM)
                    .padding()
                    .background(Color("PostBackground"))
                    .cornerRadius(12)
                    .padding(.horizontal)

                Divider().padding(.vertical, 5)

                // Comments section
                if commentVM.isLoading {
                    ProgressView()
                } else if let error = commentVM.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(commentVM.comments) { comment in
                                CommentRowView(
                                    comment: comment,
                                    onEdit: { editingComment = comment },
                                    onDelete: {
                                        commentVM.deleteComment(
                                            forPostId: post.id ?? "",
                                            commentId: comment.id ?? ""
                                        ) { _ in }
                                    }
                                )
                                .environmentObject(authVM)
                                .environmentObject(commentVM)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }

                Spacer()
            }
            .navigationTitle("Post & Comments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("FontColor"))
                    }
                }
            }
            .onAppear {
                commentVM.fetchComments(forPostId: post.id ?? "")
            }
            .sheet(isPresented: $showCreateSheet, onDismiss: {
                commentVM.fetchComments(forPostId: post.id ?? "")
            }) {
                CreateCommentView(
                    postId: post.id ?? "",
                    viewModel: commentVM,
                    onDismiss: { showCreateSheet = false }
                )
            }
            .sheet(item: $editingComment, onDismiss: {
                commentVM.fetchComments(forPostId: post.id ?? "")
            }) { editing in
                EditCommentView(
                    postId: post.id ?? "",
                    comment: editing,
                    viewModel: commentVM,
                    onDismiss: { editingComment = nil }
                )
            }
            .background(Color("BGColor").ignoresSafeArea())
        }
    }
}
