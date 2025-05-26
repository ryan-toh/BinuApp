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
    
    var body: some View {
        NavigationStack {
            Group {
                if forumVM.isLoading {
                    LoadingSpinnerView()
                } else if let error = forumVM.errorMessage {
                    ErrorBannerView(message: error)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(forumVM.posts) { post in
                                PostRowView(post: post)
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
                forumVM.fetchAllPosts()
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
                    .environmentObject(authVM)
                    .environmentObject(forumVM)
            }
        }
    }
}


#Preview {
    ForumView()
}
