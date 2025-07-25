//
//  Request.swift
//  BinuApp
//
//  Created by Ryan on 14/6/25.
//

import Foundation
import FirebaseFirestore

let appUuidString: String = "0F94F868-6715-4388-A7D8-60FBC37E72B8"

struct Request: Codable, Identifiable {
    @DocumentID var id: String?
    var senderId: String?
    var receiverId: String?
    let item: Item
    var isCompleted: Bool = false
    
    mutating func accept(by receiverId: String) {
        self.receiverId = receiverId
    }
}
