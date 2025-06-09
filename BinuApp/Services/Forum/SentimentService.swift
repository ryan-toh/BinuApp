//
//  SentimentService.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import NaturalLanguage

/// Create, Update Support for Sentiment on Posts
class SentimentService {
    /// Analyzes the sentiment of the combined title and text using Apple's Natural Language framework.
    public static func get(title: String, text: String) -> Sentiment {
        let content = "\(title) \(text)"
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = content

        let (sentiment, _) = tagger.tag(at: content.startIndex, unit: .paragraph, scheme: .sentimentScore)
        if let sentiment = sentiment, let score = Double(sentiment.rawValue) {
            if score > 0.1 {
                return .positive
            } else if score < -0.1 {
                return .negative
            } else {
                return .neutral
            }
        } else {
            return .neutral
        }
    }
}
