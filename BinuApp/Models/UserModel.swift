//
//  UserModel.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import FirebaseFirestore

/// A model representing a user’s profile in Firestore.
struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?           // Typically the same as the Firebase Auth UID
    var email: String
    var username: String
    var gender: String
    var age: Int
    
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
    
    init(
        id: String? = nil,
        email: String,
        username: String,
        gender: String,
        age: Int
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.gender = gender
        self.age = age
    }
}
