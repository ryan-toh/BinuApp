//
//  UserService.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import FirebaseFirestore

/// A service for performing CRUD operations on `UserProfile` documents in Firestore.
class UserService {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    // MARK: - Create
    
    /// Creates a new `UserProfile` document.
    /// If `profile.id` is non‐nil, that ID is used; otherwise Firestore auto-generates one.
    ///
    /// - Parameters:
    ///   - profile: A `UserProfile` struct with `id == nil` (or with a known `id` if you want to force-use it).
    ///   - completion: Returns `.success(UserProfile)` where `UserProfile.id` is now set, or `.failure(Error)`.
    func createUserProfile(
        _ profile: UserModel,
        completion: @escaping (Result<UserModel, Error>) -> Void
    ) {
        // 1) Determine which DocumentReference to use
        let docRef: DocumentReference
        if let uid = profile.id {
            // If an ID is already provided, write under /users/{uid}
            docRef = db.collection(usersCollection).document(uid)
        } else {
            // Otherwise, create a new document with an auto-generated ID
            docRef = db.collection(usersCollection).document()
        }
        
        // 2) Inject the chosen documentID back into a mutable copy
        var profileToSave = profile
        profileToSave.id = docRef.documentID
        
        // 3) Write the data
        do {
            try docRef.setData(from: profileToSave) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(profileToSave))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Read
    
    /// Fetches a single `UserProfile` by its document ID (usually the same as the Auth UID).
    ///
    /// - Parameters:
    ///   - id: The Firestore document ID of the user (e.g. the Auth UID).
    ///   - completion: Returns `.success(UserProfile)` if found and decoded, or `.failure(Error)`.
    func fetchUserProfile(
        withId id: String,
        completion: @escaping (Result<UserModel, Error>) -> Void
    ) {
        let docRef = db.collection(usersCollection).document(id)
        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(
                    domain: "UserService.Fetch",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "User profile not found"]
                )))
                return
            }
            do {
                let profile = try snapshot.data(as: UserModel.self)
                completion(.success(profile))
            } catch {
                completion(.failure(NSError(
                    domain: "UserService.Decode",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to decode user profile: \(error.localizedDescription)"]
                )))
            }
        }
    }
    
    // MARK: - Update
    
    /// Updates an existing `UserProfile`.
    /// The `profile.id` must be non-nil. This method overwrites the entire document at `/users/{id}`.
    ///
    /// - Parameters:
    ///   - profile: A `UserProfile` with a valid `id`.
    ///   - completion: Returns `.success(())` on success, or `.failure(Error)`.
    func updateUserProfile(
        _ profile: UserModel,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = profile.id else {
            completion(.failure(NSError(
                domain: "UserService.Update",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot update user profile without an ID"]
            )))
            return
        }
        
        let docRef = db.collection(usersCollection).document(uid)
        do {
            try docRef.setData(from: profile, merge: false) { error in
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
    
    /// Deletes the `UserProfile` document at `/users/{id}`.
    ///
    /// - Parameters:
    ///   - id: The document ID of the user to delete (usually the Auth UID).
    ///   - completion: Returns `.success(())` on success, or `.failure(Error)`.
    func deleteUserProfile(
        withId id: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection(usersCollection).document(id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Signs out the currently authenticated user by calling AuthService.signOut().
    /// - Parameter completion: Returns `.success(())` if sign‐out succeeded, or `.failure(Error)` otherwise.
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        AuthService.signOut { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

