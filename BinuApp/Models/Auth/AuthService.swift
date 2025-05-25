//
//  AuthModel.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import Foundation
import FirebaseAuth

/**
 How to use:
 
 Call AuthService.createUser() OR AuthService.signIn() OR AuthService.signOut().
 */
struct AuthService {
    /**
     Creates a new Firebase user with the given email and password.

     - Parameters:
        - email:    The user’s email address. Must be a well-formed, valid email.
        - password: The user’s password. Must meet Firebase’s minimum requirements (at least 6 characters).
        - completion: A closure that’s called when the operation finishes. The result is
            - `.success(String)` containing the newly created user’s UID
            - `.failure(Error)` describing why creation failed (e.g. invalid email, network error, email already in use)

     - Note:
       - Client-side you should pre-validate email/password (e.g. with SwiftValidator) for best UX.
       - Firebase will perform its own checks and may return `AuthErrorCode.invalidEmail`,
         `AuthErrorCode.weakPassword`, etc.
     */
    static func createUser(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let uid = result?.user.uid {
                completion(.success(uid))
            } else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User Creation Failed with Unknown Error"])))
            }
        }
    }
    
    /**
      Signs in a user with email and password.
     
      - Parameters:
        - email: The user’s email address.
        - password: The user’s password.
        - completion:
            - On success: returns the signed-in user’s UID as `String`.
            - On failure: returns an `Error`.
     */
    static func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let uid = result?.user.uid {
                completion(.success(uid))
            } else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication Failed with Unknown Error"])))
            }
        }
    }
    
    /**
    Signs out the current user.
    
    Completion:
     - On success: returns a confirmation message `"Signed Out"`.
    - On failure: returns an `Error`.
     
     
     */
    
    static func signOut(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success("Signed Out"))
        } catch {
            completion(.failure(error))
        }
    }
}

