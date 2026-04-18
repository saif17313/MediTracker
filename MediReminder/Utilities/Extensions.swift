//
//  Extensions.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Returns time-only string (e.g., "8:30 AM")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Returns short date string (e.g., "Mar 2, 2026")
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    /// Returns full date-time string (e.g., "Mar 2, 2026 at 8:30 AM")
    var fullString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Returns relative date description (e.g., "Today", "Yesterday", "3 days ago")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    /// Returns the start of the day (midnight) for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns the end of the day (23:59:59) for this date
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Checks if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Checks if this date is in the past
    var isPast: Bool {
        self < Date.now
    }

    /// Returns the number of days between this date and another
    func daysBetween(_ other: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.startOfDay, to: other.startOfDay)
        return components.day ?? 0
    }

    /// Returns all dates in a date range from this date
    func datesUntil(_ endDate: Date) -> [Date] {
        var dates: [Date] = []
        var current = self.startOfDay
        let end = endDate.startOfDay

        while current <= end {
            dates.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return dates
    }
}

// MARK: - String Extensions

extension String {
    /// Truncates string to a maximum length, appending "..." if truncated
    func truncated(to maxLength: Int) -> String {
        if self.count <= maxLength { return self }
        return String(self.prefix(maxLength)) + "..."
    }

    /// Returns nil if the string is empty or only whitespace
    var nilIfEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Color Extensions

extension Color {
    /// Returns a color for a given DoseStatus
    static func forDoseStatus(_ status: DoseStatus) -> Color {
        switch status {
        case .taken:   return .green
        case .skipped: return .orange
        case .missed:  return .red
        }
    }
}

// MARK: - Array Extensions

extension Array where Element == DoseHistory {
    /// Calculates adherence percentage (taken / total * 100)
    var adherencePercentage: Double {
        guard !isEmpty else { return 0 }
        let takenCount = filter { $0.status == .taken }.count
        return (Double(takenCount) / Double(count)) * 100.0
    }

    /// Groups dose history by date
    var groupedByDate: [Date: [DoseHistory]] {
        Dictionary(grouping: self) { $0.scheduledTime.startOfDay }
    }
}
