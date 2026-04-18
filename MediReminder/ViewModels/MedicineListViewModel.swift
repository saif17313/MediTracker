//
//  MedicineListViewModel.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import SwiftData
import Observation

/// ViewModel for the medicine list screen.
/// Handles fetching, filtering, and deleting medicines.
@Observable
final class MedicineListViewModel {
    var medicines: [Medicine] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var showingAddMedicine: Bool = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties

    /// Filtered medicines based on search text
    var filteredMedicines: [Medicine] {
        if searchText.isEmpty {
            return medicines
        }
        return medicines.filter { medicine in
            medicine.name.localizedCaseInsensitiveContains(searchText) ||
            medicine.dosage.localizedCaseInsensitiveContains(searchText) ||
            medicine.form.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Active medicines only
    var activeMedicines: [Medicine] {
        filteredMedicines.filter { $0.isActive }
    }

    /// Inactive (completed) medicines
    var inactiveMedicines: [Medicine] {
        filteredMedicines.filter { !$0.isActive }
    }

    // MARK: - Actions

    /// Fetches all medicines from the data store.
    func fetchMedicines() {
        isLoading = true
        errorMessage = nil

        do {
            let descriptor = FetchDescriptor<Medicine>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            medicines = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load medicines: \(error.localizedDescription)"
            medicines = []
        }

        isLoading = false
    }

    /// Deletes a medicine and cancels its notifications.
    func deleteMedicine(_ medicine: Medicine) {
        // Cancel all notifications for this medicine
        NotificationService.shared.cancelAllReminders(for: medicine)

        modelContext.delete(medicine)
        save()
        fetchMedicines()
    }

    /// Toggles a medicine's active status.
    func toggleMedicineActive(_ medicine: Medicine) {
        medicine.isActive.toggle()

        if !medicine.isActive {
            // Deactivating — cancel notifications
            NotificationService.shared.cancelAllReminders(for: medicine)
        } else {
            // Reactivating — reschedule notifications
            for reminder in medicine.reminders where reminder.isEnabled {
                NotificationService.shared.scheduleReminder(for: medicine, reminder: reminder)
            }
        }

        save()
    }

    /// Deletes medicines at the given index set (for swipe-to-delete in List).
    func deleteMedicines(at offsets: IndexSet, from list: [Medicine]) {
        for index in offsets {
            let medicine = list[index]
            deleteMedicine(medicine)
        }
    }

    // MARK: - Private

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
