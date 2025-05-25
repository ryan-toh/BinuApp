//
//  PostService.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth


/**
 How to use:
 
 Create a PostService Object.
 Call obj.upload().
 */
struct PostService {
//    private let storage = Storage.storage()
//    private let db = Firestore.firestore()
//    
//    /**
//    Uploads raw image data to Storage and returns an Image struct
//     - Parameters:
//        - data: Raw image data
//        - postId: ID of the post under which to store the image
//        - completion: Resulting Image or Error
//     */
//    private func uploadRawImage(data: Data, postId: String, completion: @escaping (Result<PostImage, Error>) -> Void) {
//        let imageId = UUID().uuidString
//        let path = "posts/\(postId)/images/\(imageId).jpg"
//        let ref = Storage.storage().reference(withPath: path)
//        
//        let meta = StorageMetadata()
//        meta.contentType = "image/jpeg"
//        
//        // 1. Upload to Firebase Firestore
//        ref.putData(data, metadata: meta) { _, error in
//            if let error = error {
//                return completion(.failure(error))
//            }
//            // 2. Get the downloadURL from firestore
//            ref.downloadURL { url, error in
//                if let error = error {
//                    completion(.failure(error))
//                }
//                guard let downloadURL = url else {
//                    return completion(.failure(NSError(
//                        domain: "UploadError",
//                        code: -1,
//                        userInfo: [NSLocalizedDescriptionKey: "Download URL is nil"]
//                    )))
//                }
//                // 3. Create the PostImage Object
//                let imageObj = PostImage(
//                    id: nil,
//                    storagePath: path,
//                    downloadURL: downloadURL.absoluteString
//                )
//                completion(.success(imageObj))
//            }
//        }
//    }
//    
//    /**
//     Writes a Post object to Firestore
//     - Parameters:
//       - post: The Post to upload
//       - completion: Resulting success (post ID) or Error
//     */
//    private func uploadPost(_ post: Post, completion: @escaping (Result<String, Error>) -> Void) {
//        // 1. Fetch PostId from Post Object
//        guard let postId = post.id else {
//            return completion(.failure(NSError (
//                domain: "PostError",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "Post ID is missing"]
//            )))
//        }
//    
//        // 2. Retrieve post reference from Firestore
//        let docRef = db.collection("posts").document(postId)
//        
//        do {
//            // 3. Upload data to Firestore
//            try docRef.setData(from: post)
//            completion(.success(postId))
//        } catch {
//            completion(.failure(error))
//        }
//    }
//    
    
    /**
      Upload a post to Firebase.
      - Parameters:
        - title: Title of the post
        - text: Body text of the post
        - imageDatas: Array of image Data to upload
        - completion: Resulting Post or Error
     */
//    public func upload(title: String, text: String, rawImages: [Data], completion: @escaping (Result<Post, Error>) -> Void) {
//        guard let userId = Auth.auth().currentUser?.uid else {
//            return completion(.failure(NSError(
//                domain: "AuthError",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]
//            )))
//        }
//        
//        // 1. Get a new postID from Firestore
//        let postId = db.collection("posts").document().documentID
//        var images = [PostImage]()
//        var uploadError: Error?
//        let group = DispatchGroup()
//        
//        // 2. Upload each image
//        for rawImage in rawImages {
//            group.enter()
//            uploadRawImage(data: rawImage, postId: postId) { result in
//                switch result {
//                case .success(let image):
//                    images.append(image)
//                case .failure(let error):
//                    uploadError = error
//                }
//                group.leave()
//            }
//        }
//        
//        // 3. Once all images uploaded, create and upload the post
//        group.notify(queue: .main) {
//            if let error = uploadError {
//                return completion(.failure(error))
//            }
//            
//            let newPost = Post(
//                id: postId,
//                userId: userId,
//                title: title,
//                text: text,
//                media: images,
//                likes: 0, 
//                comments: [],
//                sentiment: .neutral
//            )
//            
//            // 4. Return Post information
//            self.uploadPost(newPost) { result in
//                switch result {
//                case .success:
//                    completion(.success(newPost))
//                case .failure:
//                    completion(.failure(error))
//                }
//            }
//        }
//        
//        
//    }
}
