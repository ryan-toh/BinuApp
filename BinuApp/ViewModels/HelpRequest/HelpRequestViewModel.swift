//
//  PeerToPeerViewModel.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import Foundation
import Firebase
import FirebaseFirestore

@Observable
class HelpRequestViewModel {
    private let db = Firestore.firestore()
    var helpRequests: [HelpRequest] = []
    var currentRequest: HelpRequest?
    var errorMessage: String?

    // Fetch all pending help requests for a beacon UUID
    func fetchPendingRequests(uuid: String) async {
        do {
            let snapshot = try await db.collection("helpRequests")
                .whereField("uuid", isEqualTo: uuid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            helpRequests = snapshot.documents.compactMap { try? $0.data(as: HelpRequest.self) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Create a new help request
    func createHelpRequest(broadcasterId: String, uuid: String, location: GeoPoint) async -> Bool {
        let newRequest = HelpRequest(
            broadcasterId: broadcasterId,
            receiverId: nil,
            uuid: uuid,
            status: "pending",
            createdAt: Timestamp(date: .now),
            location: location,
            closedAt: nil
        )
        do {
            _ = try db.collection("helpRequests").addDocument(from: newRequest)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // Accept a help request atomically
    func acceptHelpRequest(request: HelpRequest, receiverId: String) async -> Bool {
        guard let requestId = request.id else { return false }
        let ref = db.collection("helpRequests").document(requestId)
        do {
            let _ = try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(ref)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                let status = snapshot.get("status") as? String ?? ""
                if status != "pending" {
                    let error = NSError(
                        domain: "HelpRequest",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Request already accepted or closed."]
                    )
                    errorPointer?.pointee = error
                    return nil
                }
                transaction.updateData(["status": "accepted", "receiverId": receiverId], forDocument: ref)
                return nil
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }


    // Close a help request
    func closeHelpRequest(request: HelpRequest) async {
        guard let requestId = request.id else { return }
        do {
            try await db.collection("helpRequests").document(requestId).updateData([
                "status": "completed",
                "closedAt": Timestamp(date: .now)
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

