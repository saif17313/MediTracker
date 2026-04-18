//
//  MedicineDetailViewModel.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import SwiftData
import Observation

/// ViewModel for adding and editing a single medicine.
/// Handles form state, validation, and saving to SwiftData.
@MainActor
@Observable
final class MedicineDetailViewModel {
    // MARK: - Form Fields
    var name: String = ""
    var dosage: String = ""
    var form: MedicineForm = .tablet
    var instructions: String = ""
    var startDate: Date = .now
    var endDate: Date? = nil
    var hasEndDate: Bool = false

    // MARK: - UI State
    var isSaving: Bool = false
    var errorMessage: String?
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// The medicine being edited (nil for new medicine)
    private var existingMedicine: Medicine?
    private let session: UserSessionStore

    // MARK: - Initialization

    /// Initialize for creating a new medicine
    init(session: UserSessionStore) {
        self.session = session
        self.existingMedicine = nil
    }

    /// Initialize for editing an existing medicine
    init(medicine: Medicine, session: UserSessionStore) {
        self.session = session
        self.existingMedicine = medicine
        loadFromMedicine(medicine)
    }

    // MARK: - Actions

    /// Saves the medicine (creates new or updates existing).
    /// Returns `true` if the cloud write succeeded.
    @discardableResult
    func save() async -> Bool {
        guard isValid else {
            errorMessage = "Please fill in the medicine name and dosage."
            return false
        }

        isSaving = true
        errorMessage = nil

        do {
            try await session.saveMedicine(
                existingMedicine: existingMedicine,
                name: name.trimmingCharacters(in: .whitespaces),
                dosage: dosage.trimmingCharacters(in: .whitespaces),
                form: form,
                instructions: instructions.trimmingCharacters(in: .whitespaces),
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil
            )
            isSaving = false
            return true
        } catch {
            errorMessage = "Failed to save medicine: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }

    /// Resets form to default values.
    func reset() {
        name = ""
        dosage = ""
        form = .tablet
        instructions = ""
        startDate = .now
        endDate = nil
        hasEndDate = false
        errorMessage = nil
    }

    // MARK: - Private

    /// Populates form fields from an existing medicine.
    private func loadFromMedicine(_ medicine: Medicine) {
        name = medicine.name
        dosage = medicine.dosage
        form = medicine.form
        instructions = medicine.instructions
        startDate = medicine.startDate
        endDate = medicine.endDate
        hasEndDate = medicine.endDate != nil
    }
}
