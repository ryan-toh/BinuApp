//
//  NotificationHelper.swift
//  BinuApp
//
//  Created by Hong Eungi on 12/8/25.
//

import UserNotifications

/**
 Delgates & Methods to Support Notification Delegate
 */
final class NotificationHelper {
    static let shared = NotificationHelper()
    private init() {}

    @MainActor func configure() {
        // delegate + permission
        UNUserNotificationCenter.current().delegate = ForegroundBannerDelegate.shared
        Notifier.requestAuthorization()
    }
}
