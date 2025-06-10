//
//  PostRowView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct PostRowView: View {
    @EnvironmentObject var forumVM: ForumViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    let post: Post

    @State private var showComments = false
    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Title
                    Text(post.title)
                        .font(.headline)
                    Spacer()
                    // Sentiment
                    Text(sentimentEmoji(for: post.sentiment))
                        .font(.title2)
                }
                // Optional image preview (first media item, if any)
                if let firstImage = post.media.first,
                   let url = URL(string: firstImage.downloadURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 150)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, minHeight: 150)
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            Color.gray
                                .frame(maxWidth: .infinity, minHeight: 150)
                                .cornerRadius(8)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Body text (limited to 2 lines)
                Text(post.text)
                    .font(.subheadline)
                    .lineLimit(2)
                
                // Metadata: likes, comments count, sentiment
                HStack(spacing: 16) {
                    // Likes
                    Button(action: {
                        forumVM.likeOrUnlikePost(post, userId: authVM.user?.id ?? "")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .foregroundStyle(.red)
                                .font(.title2)
                            Text("\(post.likes.count)")
                                .font(.title2)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    
                    // Comments button
                    Button(action: {
                        showComments = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("\(post.comments.count)")
                                .foregroundStyle(Color.primary)
                                .font(.title2)
                        }
                    }
                    .sheet(isPresented: $showComments) {
                        // Pass a new CommentViewModel for the post
                        CommentView(
                            viewModel: CommentViewModel(),
                            postId: post.id ?? ""
                        )
                    }
                    
                    
                    // Only show “Delete” if this post belongs to the current user
                    if let currentUserId = authVM.user?.id, post.userId == currentUserId {
                        HStack {
                            Spacer()
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.title2)
                            }
//                            .padding(.trailing, 16)
                            .alert("Delete Post", isPresented: $showDeleteAlert) {
                                Button("Delete", role: .destructive) {
                                    forumVM.deletePost(post)
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("Are you sure you want to delete this post? This action cannot be undone.")
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func sentimentEmoji(for sentiment: Sentiment) -> String {
        switch sentiment {
        case .positive: return "😊"
        case .neutral:  return "😐"
        case .negative: return "😟"
        }
    }
}



#Preview {
    // Provide mock data and environment objects for preview
    let mockPost = Post(
        id: "1", userId: "user123",
        title: "Sample Post",
        text: "This is a sample post body.",
        media: [],
        likes: [],
        comments: [],
        sentiment: .positive
    )
    let authVM = AuthViewModel()
    authVM.user = UserModel(id: "user123", email: "test@example.com", username: "TestUser", gender: "Other", age: 25)
    return PostRowView(post: mockPost)
        .environmentObject(authVM)
        .environmentObject(ForumViewModel())
}
