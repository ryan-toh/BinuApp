import SwiftUI

enum ForumTab: String, CaseIterable, Identifiable {
    case popular = "Popular"
    case recent = "Most Recent"
    case mine = "My Posts"
    
    var id: String { self.rawValue }
}

struct ForumView: View {
    @EnvironmentObject var forumVM: ForumViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var postVM: PostViewModel

    @State private var showingCreatePost = false
    @State private var postsLoaded = false
    @State private var showingCentralSheet = false
    @State private var showingPeripheralSheet = false
    @State private var selectedTab: ForumTab = .popular

    // MARK: - Filter logic
    func filteredPosts() -> [Post] {
        switch selectedTab {
        case .popular:
            return forumVM.posts.sorted { $0.likes.count > $1.likes.count }
        case .recent:
            return forumVM.posts.sorted {
                ($0.createdAt?.dateValue() ?? .distantPast) >
                ($1.createdAt?.dateValue() ?? .distantPast)
            }
        case .mine:
            return forumVM.posts.filter { $0.userId == authVM.user?.id }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                VStack(spacing: 0) {
                    // 🔹 Tab bar
                    Picker("Select Tab", selection: $selectedTab) {
                        ForEach(ForumTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .accentColor(Color("FontColor"))

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
                                Button("Provide Help") {
                                    showingCentralSheet = true
                                }
                                Button("Call for Help") {
                                    showingPeripheralSheet = true
                                }

                                ForEach(filteredPosts()) { post in
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
            .sheet(isPresented: $showingCentralSheet) {
                NavigationStack {
                    CentralView()
                }
            }
            .sheet(isPresented: $showingPeripheralSheet) {
                NavigationStack {
                    PeripheralView()
                }
            }
        }
    }
}
