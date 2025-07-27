//
//  LibraryModels.swift
//  BinuApp
//
//  Created by Hong Eungi on 27/7/25.
//

import Foundation

struct SupportCard: Identifiable {
    let id = UUID()
    let title: String
    let link: String?
    let image: String?
    
    init(title: String, link: String? = nil, image: String? = nil) {
        self.title = title
        self.link = link
        self.image = image
    }
}

struct HealthSummary: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let summary: String
    let source: String
}
