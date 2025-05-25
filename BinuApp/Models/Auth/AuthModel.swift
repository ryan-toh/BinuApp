//
//  AuthModel.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import Foundation
import FirebaseAuth

struct AuthService {
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
    
    static func signOut(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success("Signed Out"))
        } catch {
            completion(.failure(error))
        }
    }
}

