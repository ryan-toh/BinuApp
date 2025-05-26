//
//  SentimentService.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation

class SentimentService {
    public static func get(title: String, text: String) -> Sentiment {
        return Sentiment.neutral
    }
}
