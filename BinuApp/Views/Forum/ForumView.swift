//
//  ForumView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct ForumView: View {
    @EnvironmentObject var forumVM: ForumViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showingCreatePost = false
    @State private var postsLoaded = false
    
    var body: some View {
        NavigationStack {
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
                            .foregroundColor(.gray)
                        Text("No Posts")
                            .font(.title)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        Button {
                            showingCreatePost = true
                        } label: {
                            Text("New Post...")
                        }
                        .padding(.top, 10)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(forumVM.posts) { post in
                                VStack(alignment: .leading, spacing: 8) {
                                    // The existing post UI
                                    PostRowView(post: post)
                                        .environmentObject(authVM)
                                        .environmentObject(forumVM)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .refreshable {
                        forumVM.fetchAllPosts()
                    }
                }
            }
            .navigationTitle("Forum")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
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

