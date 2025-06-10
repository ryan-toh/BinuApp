//
//  CommentViewModel.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import Foundation
import Combine

final class CommentViewModel: ObservableObject, Identifiable {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let commentService = CommentService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchComments(forPostId postId: String) {
        isLoading = true
        commentService.fetchComments(forPostId: postId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let comments):
                    self?.comments = comments
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    
    func createComment(forPostId postId: String, comment: Comment, completion: @escaping (String?) -> Void) {
        isLoading = true
        commentService.createComment(forPostId: postId, comment: comment) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let newComment):
                    self?.comments.append(newComment)
                    completion(nil) // No error
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(error.localizedDescription) // Pass error message
                }
            }
        }
    }

    func updateComment(forPostId postId: String, comment: Comment, completion: @escaping (String?) -> Void) {
        isLoading = true
        commentService.updateComment(forPostId: postId, comment: comment) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    if let idx = self?.comments.firstIndex(where: { $0.id == comment.id }) {
                        self?.comments[idx] = comment
                    }
                    completion(nil)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(error.localizedDescription)
                }
            }
        }
    }

    func deleteComment(forPostId postId: String, commentId: String, completion: @escaping (String?) -> Void) {
        isLoading = true
        commentService.deleteComment(forPostId: postId, commentId: commentId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.comments.removeAll { $0.id == commentId }
                    completion(nil)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(error.localizedDescription)
                }
            }
        }
    }
}

