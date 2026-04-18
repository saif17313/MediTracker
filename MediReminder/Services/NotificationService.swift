//
//  NotificationService.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import UserNotifications

/// Manages all local notification scheduling, cancellation, and authorization.
/// Handles iOS's 64 pending notification limit by scheduling only the next few days.
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization

    /// Requests notification permission from the user.
    /// Returns `true` if granted.
    @discardableResult
    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Checks current authorization status.
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Category Registration

    /// Registers actionable notification categories with Take, Skip, and Snooze buttons.
    func registerCategories() {
        let takeAction = UNNotificationAction(
            identifier: NotificationConstants.takeAction,
            title: "✅ Take",
            options: .foreground
        )
        let skipAction = UNNotificationAction(
            identifier: NotificationConstants.skipAction,
            title: "⏭ Skip",
            options: .destructive
        )
        let snoozeAction = UNNotificationAction(
            identifier: NotificationConstants.snoozeAction,
            title: "⏰ Snooze",
            options: []
        )

        let doseCategory = UNNotificationCategory(
            identifier: NotificationConstants.doseCategoryIdentifier,
            actions: [takeAction, skipAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([doseCategory])
    }

    // MARK: - Scheduling

    /// Schedules a repeating notification for a medicine reminder.
    /// Uses calendar-based triggers for daily reminders.
    func scheduleReminder(for medicine: Medicine, reminder: Reminder) {
        guard reminder.isEnabled else { return }

        let content = createNotificationContent(for: medicine, reminder: reminder)

        switch reminder.frequency {
        case .daily:
            scheduleDailyReminder(content: content, reminder: reminder)

        case .everyOtherDay:
            // Schedule for a fixed horizon to handle 15-day pattern
            scheduleIntervalReminder(content: content, reminder: reminder, medicine: medicine, intervalDays: 15)

        case .weekly:
            scheduleWeeklyReminder(content: content, reminder: reminder)

        case .custom:
            let customInterval = max(reminder.customIntervalDays ?? 1, 1)
            scheduleIntervalReminder(content: content, reminder: reminder, medicine: medicine, intervalDays: customInterval)
        }
    }

    /// Cancels all notifications for a specific reminder.
    func cancelReminder(_ reminder: Reminder) {
        // Cancel the main notification and any variants (numbered identifiers)
        var identifiers = [reminder.notificationIdentifier]
        for i in 0..<90 {
            identifiers.append("\(reminder.notificationIdentifier)-\(i)")
        }
        for i in 1...7 {
            identifiers.append("\(reminder.notificationIdentifier)-day\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancels all notifications for a medicine (all its reminders).
    func cancelAllReminders(for medicine: Medicine) {
        for reminder in medicine.reminders {
            cancelReminder(reminder)
        }
    }

    /// Cancels every pending reminder on the current device.
    func cancelAllPendingReminders() {
        center.removeAllPendingNotificationRequests()
    }

    /// Reschedules all active reminders (call on app foreground to refresh).
    func refreshAllReminders(medicines: [Medicine]) {
        center.removeAllPendingNotificationRequests()
        for medicine in medicines where medicine.isActive {
            for reminder in medicine.reminders where reminder.isEnabled {
                scheduleReminder(for: medicine, reminder: reminder)
            }
        }
    }

    /// Returns current count of pending notifications.
    func pendingNotificationCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }

    // MARK: - Private Helpers

    /// Creates notification content for a medicine reminder.
    private func createNotificationContent(for medicine: Medicine, reminder: Reminder) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "💊 Time for \(medicine.name)"
        content.body = "\(medicine.dosage) \(medicine.form.displayName)"
        if !medicine.instructions.isEmpty {
            content.body += " — \(medicine.instructions)"
        }
        content.sound = .default
        content.categoryIdentifier = NotificationConstants.doseCategoryIdentifier
        content.userInfo = [
            "medicineId": medicine.id.uuidString,
            "reminderId": reminder.id.uuidString,
            "ownerUserId": medicine.ownerUserId,
            "deviceInstallationId": DeviceIdentityService.shared.currentDevice.installationId
        ]
        return content
    }

    /// Schedules a daily repeating notification.
    private func scheduleDailyReminder(content: UNMutableNotificationContent, reminder: Reminder) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: reminder.notificationIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error {
                print("Failed to schedule daily reminder: \(error.localizedDescription)")
            }
        }
    }

    /// Schedules notifications on a configurable N-day interval over a fixed horizon.
    private func scheduleIntervalReminder(
        content: UNMutableNotificationContent,
        reminder: Reminder,
        medicine: Medicine,
        intervalDays: Int
    ) {
        let calendar = Calendar.current
        let startDate = medicine.startDate
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminder.time)
        let safeInterval = max(intervalDays, 1)
        let schedulingHorizonDays = 90

        for dayOffset in stride(from: 0, to: schedulingHorizonDays, by: safeInterval) {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            // Skip if the date is in the past
            guard targetDate > Date.now else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(reminder.notificationIdentifier)-\(dayOffset)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// Schedules weekly notifications on specific days of the week.
    private func scheduleWeeklyReminder(content: UNMutableNotificationContent, reminder: Reminder) {
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)

        for weekday in reminder.daysOfWeek {
            var components = DateComponents()
            components.weekday = weekday
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(reminder.notificationIdentifier)-day\(weekday)",
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                if let error {
                    print("Failed to schedule weekly reminder: \(error.localizedDescription)")
                }
            }
        }
    }
}
