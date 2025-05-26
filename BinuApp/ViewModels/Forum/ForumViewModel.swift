//
//  HomeViewModel.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import Combine
import UIKit

final class ForumViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let postService = PostService()
    private var cancellables = Set<AnyCancellable>()
    
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
    
    func createPost(userId: String, title: String, text: String, images: [UIImage] = [], completion: @escaping (Bool) -> Void) {
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
}

