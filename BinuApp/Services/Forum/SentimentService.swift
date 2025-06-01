//
//  SentimentService.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation

/// Create, Update Support for Sentiment on Posts
class SentimentService {
    // TODO: Link to a HuggingFace Model for ML Sentiment readings
    public static func get(title: String, text: String) -> Sentiment {
        return Sentiment.neutral
    }
}
