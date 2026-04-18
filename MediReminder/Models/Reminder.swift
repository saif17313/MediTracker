//
//  Reminder.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftData
import Foundation

/// Represents a scheduled reminder for a medicine dose.
/// Each reminder has a specific time, frequency, and optional day-of-week configuration.
@Model
final class Reminder {
    var id: UUID
    var ownerUserId: String
    var time: Date
    var frequency: ReminderFrequency
    var daysOfWeek: [Int]
    var isEnabled: Bool
    var notificationIdentifier: String
    var snoozeDurationMinutes: Int

    /// The medicine this reminder belongs to
    var medicine: Medicine?

    init(
        time: Date,
        frequency: ReminderFrequency = .daily,
        daysOfWeek: [Int] = [],
        medicine: Medicine,
        snoozeDurationMinutes: Int = 10
    ) {
        self.id = UUID()
        self.ownerUserId = medicine.ownerUserId
        self.time = time
        self.frequency = frequency
        self.daysOfWeek = daysOfWeek
        self.isEnabled = true
        self.notificationIdentifier = UUID().uuidString
        self.medicine = medicine
        self.snoozeDurationMinutes = snoozeDurationMinutes
    }

    /// Returns a formatted time string (e.g., "8:30 AM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    /// Returns a human-readable description of the schedule
    var scheduleDescription: String {
        switch frequency {
        case .daily:
            return "Every day at \(formattedTime)"
        case .everyOtherDay:
            return "Every other day at \(formattedTime)"
        case .weekly:
            let dayNames = daysOfWeek.compactMap { dayNumber -> String? in
                let formatter = DateFormatter()
                guard dayNumber >= 1 && dayNumber <= 7 else { return nil }
                return formatter.shortWeekdaySymbols[dayNumber - 1]
            }
            return "Weekly on \(dayNames.joined(separator: ", ")) at \(formattedTime)"
        case .custom:
            return "Custom schedule at \(formattedTime)"
        }
    }
}

// MARK: - Reminder Frequency Enum

/// How often a reminder should fire
enum ReminderFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case everyOtherDay
    case weekly
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:        return "Daily"
        case .everyOtherDay: return "Every Other Day"
        case .weekly:       return "Weekly"
        case .custom:       return "Custom"
        }
    }
}
