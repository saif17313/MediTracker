//
//  ReminderViewModel.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import SwiftData
import Observation

/// ViewModel for managing reminders for a specific medicine.
/// Handles creating, editing, toggling, and deleting reminders, plus notification scheduling.
@Observable
final class ReminderViewModel {
    // MARK: - Form Fields
    var selectedTime: Date = {
        // Default to 8:00 AM
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
    }()
    var selectedFrequency: ReminderFrequency = .daily
    var selectedDaysOfWeek: Set<Int> = []
    var snoozeDuration: Int = AppConstants.defaultSnoozeDurationMinutes

    // MARK: - UI State
    var reminders: [Reminder] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var showingAddReminder: Bool = false
    var notificationPermissionGranted: Bool = false

    /// The medicine these reminders belong to
    let medicine: Medicine
    private let session: UserSessionStore

    // MARK: - Initialization

    init(medicine: Medicine, session: UserSessionStore) {
        self.medicine = medicine
        self.session = session
    }

    // MARK: - Actions

    /// Loads reminders for the current medicine.
    func loadReminders() {
        reminders = medicine.reminders.sorted { $0.time < $1.time }
    }

    /// Requests notification permission and updates the state.
    func requestNotificationPermission() async {
        do {
            notificationPermissionGranted = try await NotificationService.shared.requestAuthorization()
        } catch {
            errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            notificationPermissionGranted = false
        }
    }

    /// Checks current notification permission status.
    func checkNotificationPermission() async {
        let status = await NotificationService.shared.checkAuthorizationStatus()
        notificationPermissionGranted = (status == .authorized)
    }

    /// Creates a new reminder with the current form values and schedules its notification.
    func addReminder() async {
        guard notificationPermissionGranted else {
            errorMessage = "Please enable notifications in Settings to add reminders."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let reminderId = try await session.saveReminder(
                medicine: medicine,
                time: selectedTime,
                frequency: selectedFrequency,
                daysOfWeek: Array(selectedDaysOfWeek).sorted(),
                isEnabled: true,
                snoozeDurationMinutes: snoozeDuration
            )
            loadReminders()
            if let reminder = reminders.first(where: { $0.id == reminderId }) {
                NotificationService.shared.scheduleReminder(for: medicine, reminder: reminder)
            }
            resetForm()
        } catch {
            errorMessage = "Failed to save reminder: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Toggles a reminder on/off and schedules/cancels its notification.
    func toggleReminder(_ reminder: Reminder) async {
        isLoading = true
        errorMessage = nil

        do {
            let shouldEnable = !reminder.isEnabled
            _ = try await session.saveReminder(
                medicine: medicine,
                existingReminder: reminder,
                time: reminder.time,
                frequency: reminder.frequency,
                daysOfWeek: reminder.daysOfWeek,
                isEnabled: shouldEnable,
                snoozeDurationMinutes: reminder.snoozeDurationMinutes
            )
            loadReminders()

            if shouldEnable {
                NotificationService.shared.scheduleReminder(for: medicine, reminder: reminder)
            } else {
                NotificationService.shared.cancelReminder(reminder)
            }
        } catch {
            errorMessage = "Failed to update reminder: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Deletes a reminder and cancels its notification.
    func deleteReminder(_ reminder: Reminder) async {
        isLoading = true
        NotificationService.shared.cancelReminder(reminder)

        do {
            try await session.deleteReminder(reminder)
            loadReminders()
        } catch {
            errorMessage = "Failed to delete reminder: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Deletes reminders at given offsets.
    func deleteReminders(at offsets: IndexSet) async {
        for index in offsets {
            await deleteReminder(reminders[index])
        }
    }

    /// Resets the form to default values.
    func resetForm() {
        selectedTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
        selectedFrequency = .daily
        selectedDaysOfWeek = []
        snoozeDuration = AppConstants.defaultSnoozeDurationMinutes
        showingAddReminder = false
    }

    // MARK: - Quick Add Presets

    /// Adds common reminder presets (morning, afternoon, evening)
    func addPreset(_ preset: ReminderPreset) {
        let time: Date
        switch preset {
        case .morning:
            time = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
        case .afternoon:
            time = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: .now) ?? .now
        case .evening:
            time = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now
        case .bedtime:
            time = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now
        }

        selectedTime = time
        selectedFrequency = .daily
        Task {
            await addReminder()
        }
    }
}

// MARK: - Reminder Presets

/// Quick-add time presets for common medicine schedules
enum ReminderPreset: String, CaseIterable, Identifiable {
    case morning = "Morning (8 AM)"
    case afternoon = "Afternoon (2 PM)"
    case evening = "Evening (8 PM)"
    case bedtime = "Bedtime (10 PM)"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening:   return "sunset.fill"
        case .bedtime:   return "moon.fill"
        }
    }
}
