import SwiftUI

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
                // ✅ Post section
                PostRowView(post: post, isTappable: false)
                    .environmentObject(authVM)
                    .environmentObject(ForumViewModel())
                    .environmentObject(postVM)
                    .padding()
                    .background(Color("PostBackground"))
                    .cornerRadius(12)
                    .padding(.horizontal)

                Divider().padding(.vertical, 5)

                // ✅ Comments section
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

//#Preview {
//    let mockPost = Post(
//        id: "mock123",
//        userId: "user123",
//        title: "Sample Post",
//        text: "This is a sample post body to test the layout of CombinedCommentView.",
//        media: [],
//        likes: [],
//        sentiment: .neutral
//    )
//
//    let mockAuthVM = AuthViewModel()
//    mockAuthVM.user = UserModel(
//        id: "user123",
//        email: "mock@example.com",
//        username: "MockUser",
//        gender: "Other",
//        age: 30
//    )
//
//    let mockCommentVM = CommentViewModel()
//    mockCommentVM.comments = [
//        Comment(id: "c1", userId: "user123", text: "First comment!"),
//        Comment(id: "c2", userId: "user456", text: "I totally agree."),
//        Comment(id: "c3", userId: "user789", text: "Thanks for posting this.")
//    ]
//
//    CombinedCommentView(post: mockPost, previewViewModel: mockCommentVM)
//        .environmentObject(mockAuthVM)
//}
