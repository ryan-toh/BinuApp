//
//  ReceiverService.swift
//  BinuApp
//
//  Created by Ryan on 10/6/25.
//

import CoreLocation
import UserNotifications

class ReceiverService: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    let beaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
    let beaconID = "com.example.myibeacon"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        let region = CLBeaconRegion(uuid: beaconUUID, major: 1, minor: 1, identifier: beaconID)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        locationManager.startMonitoring(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification()
    }

    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Nearby User Detected"
        content.body = "A nearby app user is broadcasting!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
