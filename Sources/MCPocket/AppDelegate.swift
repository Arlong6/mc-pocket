import SwiftUI
import UserNotifications
import UIKit

/// Handles APNs registration + remote-notification reception. Hands the device
/// token to whoever set `AppDelegate.onTokenReceived` (the AppStore wires this).
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    nonisolated(unsafe) static var onTokenReceived: (@Sendable (String) -> Void)?
    nonisolated(unsafe) static var onPushReceived: (@Sendable ([AnyHashable: Any]) -> Void)?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        Self.onTokenReceived?(hex)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Self-use: surface in UI later via AppStore.lastError.
        print("[APNs] registration failed: \(error)")
    }

    // Show banner even when app is foreground. Marked nonisolated to satisfy
    // UNUserNotificationCenterDelegate's protocol requirements — Swift 6
    // refuses to let UIApplicationDelegate (MainActor) and this delegate
    // coexist on the same isolation boundary otherwise.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async
                                            -> UNNotificationPresentationOptions {
        let snapshot = extractSendable(from: notification.request.content.userInfo)
        Self.onPushReceived?(snapshot)
        return [.banner, .sound, .list]
    }

    // Handle tap on push — surface payload so the app can deep-link to project.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let snapshot = extractSendable(from: response.notification.request.content.userInfo)
        Self.onPushReceived?(snapshot)
    }

    /// Filter the userInfo down to a Sendable [String: String] view of just
    /// the keys we know about. Crossing the actor boundary with the raw
    /// `[AnyHashable: Any]` dict isn't allowed under Swift 6.
    private nonisolated func extractSendable(from raw: [AnyHashable: Any]) -> [AnyHashable: Any] {
        var out: [AnyHashable: Any] = [:]
        for key in ["projectId", "sessionId", "kind"] {
            if let v = raw[key] as? String { out[key] = v }
        }
        return out
    }
}
