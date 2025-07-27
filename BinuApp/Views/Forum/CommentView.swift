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
    
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let error = viewModel.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.comments) { comment in
                                    CommentRowView(
                                        comment: comment,
                                        onEdit: { editingComment = comment },
                                        onDelete: {
                                            viewModel.deleteComment(
                                                forPostId: postId,
                                                commentId: comment.id ?? ""
                                            ) { _ in }
                                        }
                                    )
                                    .environmentObject(authVM)
                                    .environmentObject(viewModel)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("FontColor"))
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet, onDismiss: {
                viewModel.fetchComments(forPostId: postId)
            }) {
                CreateCommentView(
                    postId: postId,
                    viewModel: viewModel,
                    onDismiss: { showCreateSheet = false }
                )
            }
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
                #if !DEBUG
                viewModel.fetchComments(forPostId: postId)
                #endif
            }
        }
    }
}

#Preview {
    CommentView(
        viewModel: {
            let vm = CommentViewModel()
            vm.comments = [
                Comment(id: "c1", userId: "UserA", text: "First!"),
                Comment(id: "c2", userId: "UserB", text: "Nice post."),
                Comment(id: "c3", userId: "UserC", text: "Thanks for sharing!")
            ]
            return vm
        }(),
        postId: "mockPost"
    )
}


#Preview {
    CommentView(
        viewModel: {
            let vm = CommentViewModel()
            vm.comments = [
                Comment(id: "c1", userId: "UserA", text: "First!"),
                Comment(id: "c2", userId: "UserB", text: "Nice post."),
                Comment(id: "c3", userId: "UserC", text: "Thanks for sharing!")
            ]
            return vm
        }(),
        postId: "mockPost"
    )
}
