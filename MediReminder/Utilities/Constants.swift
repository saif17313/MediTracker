//
//  Constants.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation

// MARK: - App Constants

/// App-wide constant values
enum AppConstants {
    /// Default snooze duration in minutes
    static let defaultSnoozeDurationMinutes = 10

    /// Maximum number of medicines to display in quick view
    static let maxQuickViewMedicines = 5

    /// OpenFDA API base URL
    static let openFDABaseURL = "https://api.fda.gov/drug/label.json"

    /// OpenFDA API key (empty = use without key, 240 req/min limit)
    /// Register at https://open.fda.gov/apis/authentication/ for production use
    static let openFDAApiKey = ""

    /// Maximum search results from OpenFDA
    static let maxSearchResults = 10

    /// Number of days ahead to schedule notifications (to stay under iOS 64 limit)
    static let notificationScheduleDays = 3

    /// Minimum iOS version required
    static let minimumIOSVersion = "17.0"
}

// MARK: - Notification Constants

/// Identifiers for notification categories and actions
enum NotificationConstants {
    /// Category identifier for dose reminders
    static let doseCategoryIdentifier = "DOSE_REMINDER"

    /// Action identifier for "Take" button
    static let takeAction = "TAKE_ACTION"

    /// Action identifier for "Skip" button
    static let skipAction = "SKIP_ACTION"

    /// Action identifier for "Snooze" button
    static let snoozeAction = "SNOOZE_ACTION"
}

// MARK: - UI Constants

/// Layout and styling constants
enum UIConstants {
    /// Standard corner radius for cards
    static let cornerRadius: CGFloat = 12

    /// Standard padding
    static let padding: CGFloat = 16

    /// Small padding
    static let smallPadding: CGFloat = 8

    /// Icon size for medicine form icons
    static let medicineIconSize: CGFloat = 32

    /// Calendar cell size
    static let calendarCellSize: CGFloat = 36

    /// Maximum width for form fields
    static let maxFormWidth: CGFloat = 600

    /// Animation duration
    static let animationDuration: Double = 0.3
}

// MARK: - Tab Identifiers

/// Tab identifiers for the main TabView
enum AppTab: String, CaseIterable, Identifiable {
    case medicines = "Medicines"
    case history = "History"
    case search = "Drug Search"
    case scan = "Scan Rx"
    case settings = "Settings"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .medicines: return "pill.fill"
        case .history:   return "clock.fill"
        case .search:    return "magnifyingglass"
        case .scan:      return "camera.viewfinder"
        case .settings:  return "gearshape.fill"
        }
    }
}
