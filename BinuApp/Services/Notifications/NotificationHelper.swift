//
//  AppRoute.swift
//  BinuApp
//
//  Created by Ryan on 12/8/25.
//

import Foundation
import UserNotifications

enum AppRoute: String { case openCentral }

final class NotificationHelper: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHelper()
    private override init() {}

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let open = UNNotificationAction(identifier: AppRoute.openCentral.rawValue,
                                        title: "Open",
                                        options: [.foreground])
        let cat = UNNotificationCategory(identifier: "FOUND_TARGET",
                                         actions: [open],
                                         intentIdentifiers: [],
                                         options: [])
        center.setNotificationCategories([cat])

        center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func notifyTargetFound(deviceName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Device found"
        content.body = (deviceName?.isEmpty == false)
            ? "Discovered \(deviceName!) with target service."
            : "A target device was discovered."
        content.categoryIdentifier = "FOUND_TARGET"
        content.userInfo = ["route": AppRoute.openCentral.rawValue]

        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    // Tapped banner / action → broadcast an internal signal the UI listens to.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.userInfo["route"] as? String == AppRoute.openCentral.rawValue {
            NotificationCenter.default.post(name: .openCentralFromNotification, object: nil)
        }
        completionHandler()
    }

    // Show notifications while foregrounded, too.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

extension Notification.Name {
    static let openCentralFromNotification = Notification.Name("openCentralFromNotification")
}
