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
@MainActor
@Observable
final class MedicineListViewModel {
    var medicines: [Medicine] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var showingAddMedicine: Bool = false

    private let modelContext: ModelContext
    private let session: UserSessionStore

    init(modelContext: ModelContext, session: UserSessionStore) {
        self.modelContext = modelContext
        self.session = session
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

        guard let userId = session.currentUser?.uid else {
            medicines = []
            isLoading = false
            return
        }

        do {
            let descriptor = FetchDescriptor<Medicine>(
                predicate: #Predicate { $0.ownerUserId == userId },
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
    func deleteMedicine(_ medicine: Medicine) async {
        isLoading = true
        errorMessage = nil

        do {
            try await session.deleteMedicine(medicine)
            fetchMedicines()
        } catch {
            errorMessage = "Failed to delete medicine: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Toggles a medicine's active status.
    func toggleMedicineActive(_ medicine: Medicine) async {
        errorMessage = nil

        do {
            try await session.setMedicineActive(medicine, isActive: !medicine.isActive)
            fetchMedicines()
        } catch {
            errorMessage = "Failed to update medicine: \(error.localizedDescription)"
        }
    }

    /// Deletes medicines at the given index set (for swipe-to-delete in List).
    func deleteMedicines(at offsets: IndexSet, from list: [Medicine]) async {
        for index in offsets {
            let medicine = list[index]
            await deleteMedicine(medicine)
        }
    }
}
