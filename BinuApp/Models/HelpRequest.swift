//
//  HelpRequest.swift
//  BinuApp
//
//  Created by Ryan on 10/6/25.
//

import FirebaseFirestore
import Firebase

struct HelpRequest: Identifiable, Codable {
    @DocumentID var id: String?
    var broadcasterId: String
    var receiverId: String?
    var uuid: String
    var status: String // "pending", "accepted", "completed"
    var createdAt: Timestamp?
    var location: GeoPoint
    var closedAt: Timestamp?
}
