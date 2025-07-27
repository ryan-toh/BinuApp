//
//  PostModel.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

// Identifiable for ease of use in SwiftUI Lists
struct Post: Codable, Identifiable {
    // Tag lets Firestore auto-populate id when Post is written
    @DocumentID var id: String?
    var userId: String
    var title: String
    var text: String
    var media: [PostImage]
    // Contains id of user who liked it
    var likes: [String]
    var commentCount: Int
    var sentiment: Sentiment
    
    // recently added
    var topics: [String] = []
    
    // Tag lets Firestore automatically set createdAt & updatedAt
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
    
    init(
        id: String? = nil,
        userId: String,
        title: String,
        text: String,
        media: [PostImage] = [],
        likes: [String] = [],
        sentiment: Sentiment = .neutral,
        topics: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.text = text
        self.media = media
        self.likes = likes
        self.commentCount = 0
        self.sentiment = sentiment
        self.topics = topics
    }
}
