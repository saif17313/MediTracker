//
//  DoseHistory.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftData
import Foundation

/// Records whether a scheduled dose was taken, skipped, or missed.
/// Used to calculate adherence statistics and display dose history.
@Model
final class DoseHistory {
    var id: UUID
    var ownerUserId: String
    var status: DoseStatus
    var scheduledTime: Date
    var actionTime: Date?
    var notes: String

    /// The medicine this dose record belongs to
    var medicine: Medicine?

    init(
        status: DoseStatus,
        scheduledTime: Date,
        actionTime: Date? = nil,
        medicine: Medicine,
        notes: String = ""
    ) {
        self.id = UUID()
        self.ownerUserId = medicine.ownerUserId
        self.status = status
        self.scheduledTime = scheduledTime
        self.actionTime = actionTime
        self.medicine = medicine
        self.notes = notes
    }
}

// MARK: - Dose Status Enum

/// The status of a scheduled dose
enum DoseStatus: String, Codable, CaseIterable, Identifiable {
    case taken
    case skipped
    case missed

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    /// Color name to use in SwiftUI (matches asset catalog or system colors)
    var colorName: String {
        switch self {
        case .taken:   return "green"
        case .skipped: return "orange"
        case .missed:  return "red"
        }
    }

    /// SF Symbol icon for the status
    var iconName: String {
        switch self {
        case .taken:   return "checkmark.circle.fill"
        case .skipped: return "forward.fill"
        case .missed:  return "xmark.circle.fill"
        }
    }
}
