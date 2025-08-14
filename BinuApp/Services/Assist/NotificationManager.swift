//
//  NotificationManager.swift
//  BinuApp
//
//  Created by Hong Eungi on 12/8/25.
//

import Foundation
import UserNotifications

/**
 Delgates & Methods to Support Notification Delegate
 */
extension Notification.Name {
    static let openCentralFromNotification = Notification.Name("openCentralFromNotification")
}

// Requests the user for notification permissions
enum Notifier {
    @MainActor static func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        // show banner even when app is foregrounded
        center.delegate = ForegroundBannerDelegate.shared
    }

    static func sendNow(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}

@MainActor
final class ForegroundBannerDelegate: NSObject, UNUserNotificationCenterDelegate {
        static let shared = ForegroundBannerDelegate()
        //    private override init() {}
        override init() {}
    
    // show banners while app is in foreground too
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .list]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        NotificationCenter.default.post(name: .openCentralFromNotification, object: nil)
    }
}
