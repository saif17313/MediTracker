//
//  ModelTests.swift
//  MediReminderTests
//
//  Created for MediReminder App
//

import Testing
import Foundation
@testable import MediReminder

/// Tests for SwiftData model creation and relationships.
struct ModelTests {

    // MARK: - Medicine Tests

    @Test func testMedicineCreation() {
        let medicine = Medicine(
            name: "Aspirin",
            dosage: "500mg",
            form: .tablet,
            instructions: "Take after food"
        )

        #expect(medicine.name == "Aspirin")
        #expect(medicine.dosage == "500mg")
        #expect(medicine.form == .tablet)
        #expect(medicine.instructions == "Take after food")
        #expect(medicine.ownerUserId == "")
        #expect(medicine.isActive == true)
        #expect(medicine.endDate == nil)
        #expect(medicine.reminders.isEmpty)
        #expect(medicine.doseHistory.isEmpty)
    }

    @Test func testMedicineWithEndDate() {
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: .now)
        let medicine = Medicine(
            name: "Amoxicillin",
            dosage: "250mg",
            form: .capsule,
            endDate: endDate
        )

        #expect(medicine.endDate != nil)
    }

    @Test func testMedicineFormProperties() {
        for form in MedicineForm.allCases {
            #expect(!form.displayName.isEmpty)
            #expect(!form.iconName.isEmpty)
            #expect(!form.id.isEmpty)
        }
    }

    // MARK: - Reminder Tests

    @Test func testReminderCreation() {
        let medicine = Medicine(name: "Test", dosage: "100mg", form: .tablet)
        let time = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!

        let reminder = Reminder(
            time: time,
            frequency: .daily,
            medicine: medicine
        )

        #expect(reminder.frequency == .daily)
        #expect(reminder.isEnabled == true)
        #expect(reminder.daysOfWeek.isEmpty)
        #expect(!reminder.notificationIdentifier.isEmpty)
    }

    @Test func testReminderFormattedTime() {
        let medicine = Medicine(name: "Test", dosage: "100mg", form: .tablet)
        let time = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: .now)!

        let reminder = Reminder(time: time, medicine: medicine)

        #expect(!reminder.formattedTime.isEmpty)
    }

    @Test func testReminderFrequencyProperties() {
        for freq in ReminderFrequency.allCases {
            #expect(!freq.displayName.isEmpty)
            #expect(!freq.id.isEmpty)
        }
    }

    // MARK: - DoseHistory Tests

    @Test func testDoseHistoryCreation() {
        let medicine = Medicine(name: "Test", dosage: "100mg", form: .tablet)

        let history = DoseHistory(
            status: .taken,
            scheduledTime: .now,
            actionTime: .now,
            medicine: medicine,
            notes: "Took with water"
        )

        #expect(history.status == .taken)
        #expect(history.actionTime != nil)
        #expect(history.notes == "Took with water")
    }

    @Test func testDoseStatusProperties() {
        for status in DoseStatus.allCases {
            #expect(!status.displayName.isEmpty)
            #expect(!status.colorName.isEmpty)
            #expect(!status.iconName.isEmpty)
        }
    }
}
