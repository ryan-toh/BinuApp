//
//  AccountViewModel.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation

final class AccountViewModel: ObservableObject {
    @Published var userProfile: UserModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userService = UserService()
    
    func fetchUserProfile(uid: String) {
        isLoading = true
        // Note that this will fail as userModel was never created (still in development)
        userService.fetchUserProfile(withId: uid) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let profile):
                    self?.userProfile = profile
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

