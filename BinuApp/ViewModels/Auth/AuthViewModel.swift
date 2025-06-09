import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: UserModel?
    @Published var authError: Error?
    @Published var isLoading = false
    @Published var isCheckingAuthState = true  // Added for initial loading state
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    func listenForAuthChanges() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            self.isCheckingAuthState = true
            
            if let firebaseUser = user {
                self.fetchUser(uid: firebaseUser.uid) { success in
                    self.isCheckingAuthState = false
                    if !success {
                        // If user document doesn't exist, force logout
                        self.signOut { _ in }
                    }
                }
            } else {
                self.user = nil
                self.isCheckingAuthState = false
            }
        }
    }
    
    // MARK: - Authentication Methods

    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        AuthService.signIn(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let uid):
                self?.fetchUser(uid: uid, completion: completion)
            case .failure(let error):
                self?.handleError(error, completion: completion)
            }
        }
    }
    
    func signUp(email: String, password: String, username: String, gender: String, age: Int, completion: @escaping (Bool) -> Void) {
        isLoading = true
        AuthService.createUser(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let uid):
                let newUser = UserModel(
                    id: uid,
                    email: email,
                    username: username,
                    gender: gender,
                    age: age
                )
                self?.saveUser(user: newUser, completion: completion)
            case .failure(let error):
                self?.handleError(error, completion: completion)
            }
        }
    }
    
    func signOut(completion: @escaping (Bool) -> Void) {
        isLoading = true
        AuthService.signOut { [weak self] result in
            switch result {
            case .success:
                self?.user = nil
                self?.isLoading = false
                completion(true)
            case .failure(let error):
                self?.handleError(error, completion: completion)
            }
        }
    }
    
    func getUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        fetchUser(uid: uid) { _ in }
    }
    
    // MARK: - Private Helpers
    
    private func fetchUser(uid: String, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            defer {
                self.isLoading = false
                completion(error == nil)
            }
            
            // First check if document exists
            guard let snapshot = snapshot, snapshot.exists else {
                self.authError = NSError(
                    domain: "AuthViewModel",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "User document not found"]
                )
                return
            }
            
            // Then attempt decoding
            do {
                self.user = try snapshot.data(as: UserModel.self)
            } catch {
                self.authError = error
                print("DECODING ERROR: \(error.localizedDescription)") // Add this
            }
        }
    }

    
    private func saveUser(user: UserModel, completion: @escaping (Bool) -> Void) {
        guard let uid = user.id else {
            authError = NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing user ID"])
            completion(false)
            return
        }
        
        do {
            try db.collection("users").document(uid).setData(from: user) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.authError = error
                    completion(false)
                } else {
                    self.user = user
                    completion(true)
                }
            }
        } catch {
            handleError(error, completion: completion)
        }
    }
    
    private func handleError(_ error: Error, completion: @escaping (Bool) -> Void) {
        authError = error
        isLoading = false
        completion(false)
    }
}

