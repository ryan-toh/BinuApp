//
//  ImageModel.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

// Identifiable for ease of use in SwiftUI Lists
struct PostImage: Codable, Identifiable {
    // Tag lets Firestore auto-populate id when Image is written
    @DocumentID var id: String?
    var storagePath: String
    var downloadURL: String
    
    init(
        id: String? = nil,
        storagePath: String,
        downloadURL: String
    ) {
        self.id = id
        self.storagePath = storagePath
        self.downloadURL = downloadURL
    }
}

