//
//  HomeViewModel.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import Combine
import UIKit

/// VM between PostService & Forum Views
final class ForumViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let postService = PostService()
    private var cancellables = Set<AnyCancellable>()
    
    /// All posts from all users are fetched for now
    func fetchAllPosts() {
        isLoading = true
        postService.fetchAllPosts { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let posts):
                    self?.posts = posts
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func createPost(
        userId: String,
        title: String,
        text: String,
        images: [UIImage] = [],
        topics: [String],
        completion: @escaping (Bool) -> Void
    ) {
        isLoading = true
        postService.createPost(userId: userId, title: title, text: text, images: images, topics: topics) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let newPost):
                    self?.posts.insert(newPost, at: 0)
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    /// Deletes the given post (only if it has a valid `id`), then removes it from `posts`.
    func deletePost(_ post: Post) {
        guard let postId = post.id else { return }
        isLoading = true
        
        postService.deletePost(withId: postId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    // Remove it from the local array
                    self?.posts.removeAll { $0.id == postId }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Like/Unlike Methods
    func likeOrUnlikePost(_ post: Post, userId: String) {
        guard let postId = post.id else { return }
        
        if post.likes.contains(userId) {
            // Unlike the post
            postService.unlikePost(post, uid: userId) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success:
                        if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                            var updatedPost = self.posts[index]
                            updatedPost.likes.removeAll { $0 == userId }
                            self.posts[index] = updatedPost
                        }
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            // Like the post
            postService.likePost(post, uid: userId) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success:
                        if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                            var updatedPost = self.posts[index]
                            updatedPost.likes.append(userId)
                            self.posts[index] = updatedPost
                        }
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

