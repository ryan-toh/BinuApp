//
//  RequestViewModel.swift
//  BinuApp
//
//  Created by Ryan on 14/6/25.
//

import Foundation
import Combine
import FirebaseFirestore
import CoreLocation
import CoreBluetooth

class HelpRequestViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    enum UIState {
        case broadcast
        case waiting
        case accepted
        case completed
    }
    
    @Published var currentRequest: Request?
    @Published var proximity: CLProximity?
    @Published var uiState: UIState = .broadcast
    
    // Firebase and iBeacon attributes
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let locationManager = CLLocationManager()
    private var beaconRegion: CLBeaconRegion?
    private let beaconUUID = UUID(uuidString: appUuidString)!
    private var cancellables = Set<AnyCancellable>()
    
    // User
    let userId: String
    
    init(userId: String) {
        self.userId = userId
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Sender Functions
    
    func broadcastRequest(item: Item) {
        let request = Request(senderId: userId, receiverId: nil, item: item)
        let docRef = db.collection("requests").document()
        try? docRef.setData(from: request)
        self.currentRequest = request
        self.uiState = .waiting
        
        // Start advertising iBeacon
        startBeaconAdvertising(major: 1, minor: 1)
        listenForRequestChanges(requestId: docRef.documentID)
    }
    
    func completeRequest() {
        guard let requestId = currentRequest?.id else { return }
        db.collection("requests").document(requestId).updateData(["isCompleted": true])
        
        stopBeacon()
        self.uiState = .broadcast
        self.currentRequest = nil
    }
    
    // MARK: - Receiver Functions
    
    func listenForNearbyRequests() {
        // Start search for iBeacon
        startBeaconRanging()
    }
    
    func acceptRequest(requestId: String) {
        let reqRef = db.collection("requests").document(requestId)
        reqRef.updateData(["receiverId": userId])
        self.uiState = .accepted
        listenForRequestChanges(requestId: requestId)
    }
    
    // MARK: - Firestore Sync
    
    private func listenForRequestChanges(requestId: String) {
        listener?.remove()
        listener = db.collection("requests").document(requestId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else { return }
            let request = try? snapshot?.data(as: Request.self)
            self.currentRequest = request
            
            if request?.isCompleted == true {
                self.uiState = .broadcast
                self.currentRequest = nil
                self.listener?.remove()
            } else if request?.receiverId != nil && self.userId == request?.senderId {
                self.uiState = .accepted
            }
        }
    }
    
    // MARK: - iBeacon
    
    private func startBeaconAdvertising(major: CLBeaconMajorValue, minor: CLBeaconMinorValue) {
        beaconRegion = CLBeaconRegion(uuid: beaconUUID, major: major, minor: minor, identifier: "RequestBeacon")
        let peripheralData = beaconRegion!.peripheralData(withMeasuredPower: nil) as? [String: Any]
        let peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)
        peripheralManager.startAdvertising(peripheralData)
    }
    
    private func stopBeacon() {
        let peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)
        peripheralManager.stopAdvertising()
    }
    
    private func startBeaconRanging() {
        beaconRegion = CLBeaconRegion(uuid: beaconUUID, identifier: "RequestBeacon")
        locationManager.requestAlwaysAuthorization()
        locationManager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: beaconUUID))
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying constraint: CLBeaconIdentityConstraint) {
        guard let nearest = beacons.first else { return }
        self.proximity = nearest.proximity
    }
    
    
    
}
