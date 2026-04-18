//
//  AppDelegate.swift
//  MediReminder
//
//  Created for MediReminder App
//

import UIKit
import UserNotifications
import SwiftData

/// Handles notification-related delegate methods.
/// Manages foreground notification display and user actions (Take / Snooze).
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set self as the notification center delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is delivered while the app is in the foreground.
    /// Displays the notification banner even when the app is active.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when the user interacts with a notification (tap, or action button).
    /// Handles "Take" and "Snooze" actions.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        guard let medicineIdString = userInfo["medicineId"] as? String,
              let medicineId = UUID(uuidString: medicineIdString) else {
            completionHandler()
            return
        }

        let ownerUserId = userInfo["ownerUserId"] as? String

        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case NotificationConstants.takeAction:
            handleDoseAction(medicineId: medicineId, ownerUserId: ownerUserId, status: .taken)

        case NotificationConstants.snoozeAction:
            handleSnooze(for: response.notification.request)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself — open the app to the medicine detail
            NotificationCenter.default.post(
                name: .openMedicineDetail,
                object: nil,
                userInfo: [
                    "medicineId": medicineId,
                    "ownerUserId": ownerUserId as Any
                ]
            )

        default:
            break
        }

        completionHandler()
    }

    // MARK: - Private Helpers

    /// Records a dose action (taken) in the SwiftData store.
    private func handleDoseAction(medicineId: UUID, ownerUserId: String?, status: DoseStatus) {
        // Post notification so the active ViewModel can handle the persistence
        NotificationCenter.default.post(
            name: .doseActionReceived,
            object: nil,
            userInfo: [
                "medicineId": medicineId,
                "ownerUserId": ownerUserId as Any,
                "status": status.rawValue,
                "scheduledTime": Date.now
            ]
        )
    }

    /// Reschedules a notification after a snooze delay.
    private func handleSnooze(for request: UNNotificationRequest) {
        let content = request.content.mutableCopy() as! UNMutableNotificationContent
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(AppConstants.defaultSnoozeDurationMinutes * 60),
            repeats: false
        )
        let snoozeRequest = UNNotificationRequest(
            identifier: "\(request.identifier)-snooze-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(snoozeRequest)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user taps a notification to open a specific medicine
    static let openMedicineDetail = Notification.Name("openMedicineDetail")

    /// Posted when user takes an action (Take) from a notification
    static let doseActionReceived = Notification.Name("doseActionReceived")
}
