//
//  ViewModelTests.swift
//  MediReminderTests
//
//  Created for MediReminder App
//

import Testing
import Foundation
import SwiftData
@testable import MediReminder

/// Tests for ViewModel logic and data operations.
struct ViewModelTests {

    // MARK: - Helper

    /// Creates an in-memory ModelContext for testing.
    private func makeTestContext() throws -> ModelContext {
        let schema = Schema([Medicine.self, Reminder.self, DoseHistory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    // MARK: - MedicineDetailViewModel Tests

    @Test func testMedicineDetailViewModelValidation() throws {
        let context = try makeTestContext()
        let vm = MedicineDetailViewModel(modelContext: context)

        // Empty name should be invalid
        vm.name = ""
        vm.dosage = "500mg"
        #expect(vm.isValid == false)

        // Empty dosage should be invalid
        vm.name = "Aspirin"
        vm.dosage = ""
        #expect(vm.isValid == false)

        // Both filled should be valid
        vm.name = "Aspirin"
        vm.dosage = "500mg"
        #expect(vm.isValid == true)

        // Whitespace-only should be invalid
        vm.name = "   "
        #expect(vm.isValid == false)
    }

    @Test func testMedicineDetailViewModelSave() throws {
        let context = try makeTestContext()
        let vm = MedicineDetailViewModel(modelContext: context)

        vm.name = "Aspirin"
        vm.dosage = "500mg"
        vm.form = .tablet
        vm.instructions = "Take after food"

        let medicine = vm.save()
        #expect(medicine != nil)
        #expect(medicine?.name == "Aspirin")
        #expect(medicine?.dosage == "500mg")
    }

    @Test func testMedicineDetailViewModelEdit() throws {
        let context = try makeTestContext()

        let medicine = Medicine(name: "Old Name", dosage: "100mg", form: .tablet)
        context.insert(medicine)
        try context.save()

        let vm = MedicineDetailViewModel(medicine: medicine, modelContext: context)
        #expect(vm.name == "Old Name")

        vm.name = "New Name"
        vm.dosage = "200mg"
        let updated = vm.save()

        #expect(updated?.name == "New Name")
        #expect(updated?.dosage == "200mg")
    }

    @Test func testMedicineDetailViewModelReset() throws {
        let context = try makeTestContext()
        let vm = MedicineDetailViewModel(modelContext: context)

        vm.name = "Test"
        vm.dosage = "500mg"
        vm.reset()

        #expect(vm.name == "")
        #expect(vm.dosage == "")
    }

    // MARK: - DrugSearchViewModel Tests

    @Test func testDrugSearchViewModelInitialState() {
        let vm = DrugSearchViewModel()

        #expect(vm.searchText == "")
        #expect(vm.results.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.hasSearched == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func testDrugSearchViewModelClearResults() {
        let vm = DrugSearchViewModel()
        vm.searchText = "test"
        vm.hasSearched = true

        vm.clearResults()

        #expect(vm.searchText == "")
        #expect(vm.hasSearched == false)
        #expect(vm.results.isEmpty)
    }

    // MARK: - DoseHistory Adherence Tests

    @Test func testAdherencePercentage() {
        let medicine = Medicine(name: "Test", dosage: "100mg", form: .tablet)

        let history: [DoseHistory] = [
            DoseHistory(status: .taken, scheduledTime: .now, medicine: medicine),
            DoseHistory(status: .taken, scheduledTime: .now, medicine: medicine),
            DoseHistory(status: .taken, scheduledTime: .now, medicine: medicine),
            DoseHistory(status: .skipped, scheduledTime: .now, medicine: medicine),
            DoseHistory(status: .missed, scheduledTime: .now, medicine: medicine),
        ]

        let percentage = history.adherencePercentage
        #expect(percentage == 60.0) // 3 out of 5 taken
    }

    @Test func testEmptyAdherencePercentage() {
        let history: [DoseHistory] = []
        #expect(history.adherencePercentage == 0.0)
    }
}
