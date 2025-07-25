import SwiftUI

struct PostRowView: View {
    @EnvironmentObject var forumVM: ForumViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    let post: Post

    @State private var showDeleteAlert = false

    var body: some View {
        // Entire post is tappable
        NavigationLink(destination: CombinedCommentView(post: post)) {
            VStack(alignment: .leading, spacing: 8) {
                // Title and sentiment
                HStack {
                    Text(post.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(sentimentEmoji(for: post.sentiment))
                        .font(.title2)
                }

                // Optional image
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

                // Body text
                Text(post.text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Like / Comment / Delete Row
                HStack(spacing: 16) {
                    Button {
                        forumVM.likeOrUnlikePost(post, userId: authVM.user?.id ?? "")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .foregroundColor(Color("FontColor"))
                            Text("\(post.likes.count)")
                                .foregroundColor(.primary)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(Color("ExtraColor1"))
                        Text("\(post.commentCount)")
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    if let currentUserId = authVM.user?.id, post.userId == currentUserId {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(Color("FontColor"))
                        }
                        .alert("Delete Post", isPresented: $showDeleteAlert) {
                            Button("Delete", role: .destructive) {
                                forumVM.deletePost(post)
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("Are you sure you want to delete this post?")
                        }
                    }
                }
                .font(.title2)
                .padding(.top, 10)
            }
            .padding()
            .background(Color("PostBackground"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("FontColor").opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    let mockPost = Post(
        id: "1", userId: "user123",
        title: "Sample Post",
        text: "This is a sample post body.",
        media: [],
        likes: [],
        sentiment: .positive
    )
    let authVM = AuthViewModel()
    authVM.user = UserModel(id: "user123", email: "test@example.com", username: "TestUser", gender: "Other", age: 25)
    return PostRowView(post: mockPost)
        .environmentObject(authVM)
        .environmentObject(ForumViewModel())
} 
