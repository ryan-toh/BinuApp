//
//  CommentService.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import FirebaseFirestore

/// CRUD Support for Comments on Posts.
class CommentService {
    private let db = Firestore.firestore()
    private let postsCollection = "posts"
    private let commentsSubcollection = "comments"
    
    /// Create a new Comment under a specific Post.
    /// - Parameters:
    ///   - postId: The ID of the parent Post document.
    ///   - comment: A Comment struct (with id == nil). This will be encoded and sent to Firestore.
    ///   - completion: Returns a Result containing the newly‐created Comment (with its generated `id`) or an Error.
    func createComment(forPostId postId: String, comment: Comment, completion: @escaping (Result<Comment, Error>) -> Void
    ) {
        let commentsRef = db
            .collection(postsCollection)
            .document(postId)
            .collection(commentsSubcollection)
        
        // 1) Create a new DocumentReference with an auto-generated ID
        let newRef = commentsRef.document()
        
        // 2) Make a mutable copy and inject the generated ID
        var commentToSave = comment
        commentToSave.id = newRef.documentID
        
        // 3) Write the comment data to Firestore
        do {
            try newRef.setData(from: commentToSave) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(commentToSave))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    
    /// Fetch all Comments for a given Post, ordered by `createdAt` ascending.
    /// - Parameters:
    ///   - postId: The ID of the parent Post document.
    ///   - completion: Returns a Result containing an array of Comments or an Error.
    func fetchComments(forPostId postId: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        let commentsRef = db.collection(postsCollection)
                           .document(postId)
                           .collection(commentsSubcollection)
        
        commentsRef
            .order(by: "createdAt", descending: false)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let docs = querySnapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let comments: [Comment] = docs.compactMap { snapshot in
                    return try? snapshot.data(as: Comment.self)
                }
                completion(.success(comments))
            }
    }
    
    /// Update an existing Comment under a specific Post.
    /// - Parameters:
    ///   - postId: The ID of the parent Post document.
    ///   - comment: A Comment struct with a non‐nil `id`. The entire document will be overwritten with this struct.
    ///   - completion: Returns a Result containing Void on success or an Error.
    func updateComment(forPostId postId: String, comment: Comment, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let commentId = comment.id else {
            completion(.failure(NSError(
                domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot update a comment without an ID"]
            )))
            return
        }
        
        let commentDocRef = db.collection(postsCollection)
                              .document(postId)
                              .collection(commentsSubcollection)
                              .document(commentId)
        
        do {
            try commentDocRef.setData(from: comment, merge: false) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Delete a Comment by its ID under a specific Post.
    /// - Parameters:
    ///   - postId: The ID of the parent Post document.
    ///   - commentId: The Firestore document ID of the Comment to delete.
    ///   - completion: Returns a Result containing Void on success or an Error.
    func deleteComment(forPostId postId: String, commentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let commentDocRef = db.collection(postsCollection)
                              .document(postId)
                              .collection(commentsSubcollection)
                              .document(commentId)
        
        commentDocRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
