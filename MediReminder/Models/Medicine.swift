//
//  Medicine.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftData
import Foundation

/// Represents a medicine that the user is tracking.
/// Stores all relevant details including dosage, form, instructions, and time range.
@Model
final class Medicine {
    var id: UUID
    var name: String
    var dosage: String
    var form: MedicineForm
    var instructions: String
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var createdAt: Date

    /// All reminders associated with this medicine (cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \Reminder.medicine)
    var reminders: [Reminder] = []

    /// All dose history records for this medicine (cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \DoseHistory.medicine)
    var doseHistory: [DoseHistory] = []

    init(
        name: String,
        dosage: String,
        form: MedicineForm,
        instructions: String = "",
        startDate: Date = .now,
        endDate: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.form = form
        self.instructions = instructions
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
        self.createdAt = .now
    }
}

// MARK: - Medicine Form Enum

/// The physical form of a medicine
enum MedicineForm: String, Codable, CaseIterable, Identifiable {
    case tablet
    case capsule
    case liquid
    case syrup
    case injection
    case topical
    case inhaler
    case drops
    case patch
    case other

    var id: String { rawValue }

    /// SF Symbol name for each form
    var iconName: String {
        switch self {
        case .tablet:    return "pill.fill"
        case .capsule:   return "capsule.fill"
        case .liquid:    return "drop.fill"
        case .syrup:     return "cup.and.saucer.fill"
        case .injection: return "syringe.fill"
        case .topical:   return "hand.raised.fill"
        case .inhaler:   return "wind"
        case .drops:     return "drop.triangle.fill"
        case .patch:     return "bandage.fill"
        case .other:     return "cross.case.fill"
        }
    }

    /// User-friendly display name
    var displayName: String {
        rawValue.capitalized
    }
}
