//
//  PostService.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import UIKit                 // For UIImage
import FirebaseFirestore
import FirebaseStorage       // For Firebase Storage

class PostService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let postsCollection = "posts"
    
    // MARK: - Create
    
    /// Creates a new Post by uploading any provided images to Firebase Storage,
    /// computing sentiment, and then writing a Post document to Firestore.
    ///
    /// - Parameters:
    ///   - userId:     The UID of the current user creating this post.
    ///   - title:      The post’s title.
    ///   - text:       The post’s body text.
    ///   - images:     An array of UIImages to upload. Defaults to an empty array.
    ///   - completion: Returns Result<Post, Error>. On success, the returned Post
    ///                 has its `id` populated with Firestore’s generated document ID.
    func createPost(
        userId: String,
        title: String,
        text: String,
        images: [UIImage] = [],
        completion: @escaping (Result<Post, Error>) -> Void
    ) {
        // 1) Compute sentiment now (synchronous).
        let sentiment = SentimentService.get(title: title, text: text)
        
        // 2) If there are no images, skip directly to Firestore write.
        guard !images.isEmpty else {
            let post = Post(
                userId: userId,
                title: title,
                text: text,
                media: [],
                likes: 0,
                comments: [],
                sentiment: sentiment
            )
            writePostToFirestore(post, completion: completion)
            return
        }
        
        // 3) Otherwise, upload each UIImage to Storage via helper, collect PostImage entries.
        var postImages: [PostImage] = []
        var uploadError: Error?
        let group = DispatchGroup()
        
        for image in images {
            group.enter()
            uploadSingleImage(image, forUserId: userId) { result in
                switch result {
                case .failure(let error):
                    // Capture the first error we see
                    if uploadError == nil {
                        uploadError = error
                    }
                case .success(let postImage):
                    postImages.append(postImage)
                }
                group.leave()
            }
        }
        
        // 4) After all uploads finish, either proceed or bail on error
        group.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
                return
            }
            
            // Build the Post with all PostImage entries
            let post = Post(
                userId: userId,
                title: title,
                text: text,
                media: postImages,
                likes: 0,
                comments: [],
                sentiment: sentiment
            )
            self.writePostToFirestore(post, completion: completion)
        }
    }
    
    /// Internal helper: uploads a single UIImage to Firebase Storage as a JPEG,
    /// then returns a PostImage containing `storagePath` and `downloadURL`.
    private func uploadSingleImage(
        _ image: UIImage,
        forUserId userId: String,
        completion: @escaping (Result<PostImage, Error>) -> Void
    ) {
        // 1) Convert UIImage to JPEG Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(
                domain: "PostService.Upload",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert UIImage to JPEG data"]
            )
            completion(.failure(error))
            return
        }
        
        // 2) Create a unique Storage path: "posts/{userId}/{UUID}.jpg"
        let filename = UUID().uuidString + ".jpg"
        let storagePath = "posts/\(userId)/\(filename)"
        let storageRef = storage.reference(withPath: storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // 3) Upload the data
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 4) Fetch download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURLString = url?.absoluteString else {
                    let error = NSError(
                        domain: "PostService.Upload",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to obtain download URL"]
                    )
                    completion(.failure(error))
                    return
                }
                
                // 5) Create and return a PostImage
                let postImage = PostImage(
                    id: nil,
                    storagePath: storagePath,
                    downloadURL: downloadURLString
                )
                completion(.success(postImage))
            }
        }
    }
    
    // MARK: - Internal Firestore Write
    
    /// Internal helper: writes a Post struct into Firestore under "posts/", letting Firestore generate the document ID.
    private func writePostToFirestore(
        _ post: Post,
        completion: @escaping (Result<Post, Error>) -> Void
    ) {
        // 1) Create a new document reference with an auto-generated ID:
        let newRef = db.collection(postsCollection).document()
        
        do {
            // 2) Make a mutable copy of `post`, inject the generated documentID
            var postToSave = post
            postToSave.id = newRef.documentID
            
            // 3) Use `setData(from: )` on that reference
            try newRef.setData(from: postToSave) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // 4) Return the same `postToSave` (with its id) in the completion
                    completion(.success(postToSave))
                }
            }
            
        } catch {
            completion(.failure(error))
        }
    }

    
    // MARK: - Read
    
    /// Fetch a single Post by its document ID.
    func fetchPost(withId id: String, completion: @escaping (Result<Post, Error>) -> Void) {
        let docRef = db.collection(postsCollection).document(id)
        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(
                    domain: "PostService.Fetch",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Post not found"]
                )))
                return
            }
            do {
                let post = try snapshot.data(as: Post.self)
                completion(.success(post))
            } catch {
                completion(.failure(NSError(
                    domain: "PostService.Decode",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to decode post: \(error.localizedDescription)"]
                )))
            }
        }
    }

    
    /// Fetch all Posts, ordered by `createdAt` descending.
    func fetchAllPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        db.collection(postsCollection)
            .order(by: "createdAt", descending: true)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let docs = querySnapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let posts: [Post] = docs.compactMap { snapshot in
                    return try? snapshot.data(as: Post.self)
                }
                completion(.success(posts))
            }
    }
    
    // MARK: - Update
    
    /// Update an existing Post—recomputes sentiment, but does NOT re‐upload images.
    /// If you need to change images, upload those separately and pass updated `media` array in `post`.
    func updatePost(_ post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let postId = post.id else {
            completion(.failure(NSError(
                domain: "PostService.Update",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot update a post without an ID"]
            )))
            return
        }
        
        // Recompute sentiment from the (possibly edited) title/body
        var updatedPost = post
        updatedPost.sentiment = SentimentService.get(title: post.title, text: post.text)
        
        do {
            try db.collection(postsCollection)
                .document(postId)
                .setData(from: updatedPost, merge: false) { error in
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
    
    // MARK: - Delete
    
    /// Delete a Post by its document ID.
    func deletePost(withId id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(postsCollection).document(id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
