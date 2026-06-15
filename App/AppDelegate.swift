import UIKit
import UserNotifications

/// AppDelegate handles APNs registration and remote notification delegation.
/// Conforms to UNUserNotificationCenterDelegate to process incoming push notifications.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Register default notification categories
        registerNotificationCategories()

        // Request notification authorization and register for remote notifications
        requestNotificationAuthorization { granted, _ in
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }

        // Handle cold start from a remote notification tap
        if let remoteNotification = launchOptions?[.remoteNotification] as? [String: Any] {
            handleBindingRequestNotification(userInfo: remoteNotification)
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert device token to hex string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()

        // Store token in UserDefaults for later use after login
        UserDefaults.standard.set(token, forKey: "apnsDeviceToken")

        // Post notification so services can pick up the updated token
        NotificationCenter.default.post(
            name: .didRegisterForRemoteNotifications,
            object: nil,
            userInfo: ["deviceToken": token]
        )

        print("[AppDelegate] Registered for remote notifications, token: \(token)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Refresh badge count when app becomes active
        application.applicationIconBadgeNumber = 0
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle push notifications when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge, .list])
    }

    /// Handle user's response to a notification (tap action).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Extract alert ID or deep link payload
        if let alertId = userInfo["alert_id"] as? String {
            NotificationCenter.default.post(
                name: .didReceiveAlertNotification,
                object: nil,
                userInfo: ["alert_id": alertId]
            )
        }

        // Handle binding request push notifications
        handleBindingRequestNotification(userInfo: userInfo)

        completionHandler()
    }

    // MARK: - Helpers

    /// Request notification authorization from the user.
    /// - Parameter completion: Called with granted boolean and optional error.
    func requestNotificationAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completion)
    }

    /// Register custom notification categories and actions.
    private func registerNotificationCategories() {
        // Alert detail action
        let viewAction = UNNotificationAction(
            identifier: "view_detail",
            title: String(localized: "notification_view_detail", defaultValue: "查看详情"),
            options: .foreground
        )

        // Alert category
        let alertCategory = UNNotificationCategory(
            identifier: "health_alert",
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Binding request category
        let viewBindingAction = UNNotificationAction(
            identifier: "view_binding",
            title: String(localized: "notification_view_binding", defaultValue: "查看绑定请求"),
            options: .foreground
        )

        let bindingCategory = UNNotificationCategory(
            identifier: "binding_request",
            actions: [viewBindingAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([alertCategory, bindingCategory])
    }

    /// Check if a notification payload is a binding request and post the appropriate notification.
    private func handleBindingRequestNotification(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String,
              type == "binding_request",
              let requestId = userInfo["requestId"] as? Int,
              let fromUserId = userInfo["fromUserId"] as? Int else {
            return
        }

        // Use a slight delay when handling cold starts to allow RootView to set up
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .showBindingRequest,
                object: nil,
                userInfo: [
                    "requestId": String(requestId),
                    "fromUserId": fromUserId
                ]
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the device successfully registers for remote notifications.
    static let didRegisterForRemoteNotifications = Notification.Name("didRegisterForRemoteNotifications")
    /// Posted when the user taps on a health alert notification.
    static let didReceiveAlertNotification = Notification.Name("didReceiveAlertNotification")
    /// Posted when the user taps a binding request push notification.
    static let showBindingRequest = Notification.Name("ShowBindingRequest")
}
