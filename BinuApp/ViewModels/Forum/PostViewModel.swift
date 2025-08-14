//
//  PostViewModel.swift
//  BinuApp
//
//  Created by Hong Eungi on 27/7/25.
//

import Foundation
import FirebaseFirestore

/**
 Logic Handling for CreatePostView
 */
class PostViewModel: ObservableObject {
    @Published var usernameMap: [String: String] = [:]

    func fetchUsername(for userId: String) {
        if usernameMap[userId] != nil { return }

        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore error: \(error.localizedDescription)")
                return
            }

            guard let doc = snapshot else {
                print("⚠️ No snapshot found")
                return
            }

            do {
                let user = try doc.data(as: UserModel.self)
                DispatchQueue.main.async {
                    self.usernameMap[userId] = user.username
                }
            } catch {
                print("❌ Decoding failed for user \(userId): \(error)")
            }
        }
    }
}
