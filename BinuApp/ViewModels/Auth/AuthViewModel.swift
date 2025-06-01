//
//  AuthViewModel.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import FirebaseAuth
import Combine

/// Temporary struct (as UserModel is still in development)
struct User {
    let uid: String
    let email: String?
}

final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isCheckingAuthState = true
    @Published var authErrorMessage: String?
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let userService = UserService()
    
    init() {
        listenForAuthChanges()
    }
    
    /// Starts listening for Firebase Auth state changes.
    func listenForAuthChanges() {
        isCheckingAuthState = true
        
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            if let firebaseUser = firebaseUser {
                self.currentUser = User(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email
                )
            } else {
                self.currentUser = nil
            }
            self.isCheckingAuthState = false
        }
    }
    
    /// Creates a new user via AuthService, then updates `currentUser`.
    func signUp(email: String, password: String) {
        authErrorMessage = nil
        
        AuthService.createUser(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self?.authErrorMessage = error.localizedDescription
                    
                case .success(let uid):
                    if let firebaseUser = Auth.auth().currentUser, firebaseUser.uid == uid {
                        self?.currentUser = User(
                            uid: firebaseUser.uid,
                            email: firebaseUser.email
                        )
                    } else {
                        self?.currentUser = User(uid: uid, email: nil)
                    }
                }
            }
        }
    }
    
    /// Signs in via AuthService, then updates `currentUser`.
    func signIn(email: String, password: String) {
        authErrorMessage = nil
        
        AuthService.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self?.authErrorMessage = error.localizedDescription
                    
                case .success(let uid):
                    if let firebaseUser = Auth.auth().currentUser, firebaseUser.uid == uid {
                        self?.currentUser = User(
                            uid: firebaseUser.uid,
                            email: firebaseUser.email
                        )
                    } else {
                        self?.currentUser = User(uid: uid, email: nil)
                    }
                }
            }
        }
    }
    
    /// Signs out via UserService (which wraps AuthService.signOut).
    func signOut() {
        authErrorMessage = nil
        
        userService.signOut { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self?.authErrorMessage = error.localizedDescription
                case .success:
                    self?.currentUser = nil
                }
            }
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

