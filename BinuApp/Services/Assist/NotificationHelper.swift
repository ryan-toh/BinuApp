import UserNotifications

final class NotificationHelper {
    static let shared = NotificationHelper()
    private init() {}

    func configure() {
        // delegate + permission
        UNUserNotificationCenter.current().delegate = ForegroundBannerDelegate.shared
        Notifier.requestAuthorization()
    }
}
