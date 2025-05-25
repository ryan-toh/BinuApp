//
//  CommentModel.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

// Identifiable for ease of use in SwiftUI Lists
struct Comment: Codable, Identifiable {
    // Tag lets Firestore auto-populate id when Comment is written
    @DocumentID var id: String?
    var userId: String
    var text: String
    var likes: Int
    
    // Tag lets Firestore automatically set createdAt
    @ServerTimestamp var createdAt: Timestamp?
    
    init(
        id: String? = nil,
        userId: String,
        text: String,
        likes: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.text = text
        self.likes = likes
    }
}
