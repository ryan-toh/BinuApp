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
    
    // TODO: Implement fetchFromFollowers()
    func fetchFromFollowers() -> Void {
        
    }
    
    func createPost(
        userId: String,
        title: String,
        text: String,
        images: [UIImage] = [],
        completion: @escaping (Bool) -> Void
    ) {
        isLoading = true
        postService.createPost(userId: userId, title: title, text: text, images: images) { [weak self] result in
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
}

