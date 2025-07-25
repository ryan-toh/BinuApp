//
//  NotificationService.swift
//  BinuApp
//
//  Created by Ryan on 8/7/25.
//

import Foundation
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private var receiver = ReceiverServiceV4.sharedReceiver
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    // Helper function to alert user to connect
    func sendNotification(for item: Item) {
        let content = UNMutableNotificationContent()
        content.title = "Nearby Help Available"
        content.body = "Someone is offering \(item.description) nearby"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.userInfo["action"] as? String == "connectToBroadcaster" {
            guard let discoveredDevice = receiver.discoveredDevices.first else { return }
            receiver.connect(to: discoveredDevice)
        }
        completionHandler()
    }
}
