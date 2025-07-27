import SwiftUI

struct ForumView: View {
    @EnvironmentObject var forumVM: ForumViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var postVM: PostViewModel

    @State private var showingCreatePost = false
    @State private var postsLoaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                Group {
                    if forumVM.isLoading {
                        LoadingSpinnerView()
                    } else if let error = forumVM.errorMessage {
                        ErrorBannerView(message: error)
                    } else if forumVM.posts.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "tray")
                                .font(.system(size: 30))
                                .foregroundColor(Color("FontColor").opacity(0.5))
                            Text("No Posts")
                                .font(.title)
                                .foregroundColor(Color("FontColor").opacity(0.8))
                                .padding(.top, 10)
                            Button {
                                showingCreatePost = true
                            } label: {
                                Text("New Post...")
                                    .foregroundColor(Color("FontColor"))
                            }
                            .padding(.top, 10)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(forumVM.posts) { post in
                                    PostRowView(post: post)
                                        .environmentObject(authVM)
                                        .environmentObject(forumVM)
                                        .environmentObject(postVM)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        }
                        .refreshable {
                            forumVM.fetchAllPosts()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Forum")
                        .font(.title.bold())
                        .foregroundColor(Color("FontColor"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("FontColor"))
                    }
                }
            }
            .onAppear {
                if !postsLoaded {
                    forumVM.fetchAllPosts()
                    postsLoaded = true
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
                    .environmentObject(authVM)
                    .environmentObject(forumVM)
            }
        }
    }
}

//#Preview {
//    ForumView()
//        .environmentObject(ForumViewModel())
//        .environmentObject(AuthViewModel())
//}
