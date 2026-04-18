//
//  PersistenceController.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftData
import Foundation

/// Manages SwiftData ModelContainer configuration.
/// Provides shared instance for production and in-memory instance for previews/tests.
struct PersistenceController {
    /// Shared production instance with on-disk storage
    static let shared = PersistenceController()

    /// In-memory instance for SwiftUI previews and unit tests
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Add sample data for previews
        Task{ @MainActor in 
            controller.addSampleData()
        }
        return controller
    }()

    let modelContainer: ModelContainer

    init(inMemory: Bool = false) {
        do {
            modelContainer = try Self.makeModelContainer(inMemory: inMemory)
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    private static func makeModelContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([
            Medicine.self,
            Reminder.self,
            DoseHistory.self
        ])

        if inMemory {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(for: schema, configurations: [config])
        }

        let storeURL = try persistentStoreURL()
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            try? removePersistentStoreArtifacts()
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    private static func persistentStoreURL() throws -> URL {
        let fileManager = FileManager.default
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let rootURL = applicationSupportURL?.appendingPathComponent("MediReminder", isDirectory: true)

        guard let rootURL else {
            throw CocoaError(.fileNoSuchFile)
        }

        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        return rootURL.appendingPathComponent("MediReminder.store")
    }

    private static func removePersistentStoreArtifacts() throws {
        let fileManager = FileManager.default
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let rootURL = applicationSupportURL?.appendingPathComponent("MediReminder", isDirectory: true)

        guard let rootURL else { return }
        if fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.removeItem(at: rootURL)
        }
    }

    // MARK: - Sample Data for Previews

    /// Adds sample medicines, reminders, and dose history for SwiftUI previews.
    @MainActor
    private func addSampleData() {
        let context = modelContainer.mainContext
        let previewUserId = AppConstants.previewUserId

        // Sample Medicine 1: Aspirin
        let aspirin = Medicine(
            name: "Aspirin",
            dosage: "500mg",
            form: .tablet,
            instructions: "Take after food with water",
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now,
            ownerUserId: previewUserId
        )
        context.insert(aspirin)

        // Sample Reminder for Aspirin
        let morningTime = Calendar.current.date(
            bySettingHour: 8, minute: 0, second: 0, of: .now
        ) ?? .now
        let aspirinReminder = Reminder(
            time: morningTime,
            frequency: .daily,
            medicine: aspirin
        )
        context.insert(aspirinReminder)

        // Sample Medicine 2: Amoxicillin
        let amoxicillin = Medicine(
            name: "Amoxicillin",
            dosage: "250mg",
            form: .capsule,
            instructions: "Take before meals",
            startDate: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .day, value: 4, to: .now),
            ownerUserId: previewUserId
        )
        context.insert(amoxicillin)

        // Sample Reminders for Amoxicillin (3 times a day)
        for hour in [8, 14, 20] {
            let time = Calendar.current.date(
                bySettingHour: hour, minute: 0, second: 0, of: .now
            ) ?? .now
            let reminder = Reminder(time: time, frequency: .daily, medicine: amoxicillin)
            context.insert(reminder)
        }

        // Sample Medicine 3: Cough Syrup
        let coughSyrup = Medicine(
            name: "Dextromethorphan",
            dosage: "10ml",
            form: .syrup,
            instructions: "Take before sleep",
            ownerUserId: previewUserId
        )
        context.insert(coughSyrup)

        // Sample Dose History
        for dayOffset in 1...5 {
            let scheduledTime = Calendar.current.date(
                byAdding: .day, value: -dayOffset, to: .now
            ) ?? .now
            let status: DoseStatus = dayOffset % 3 == 0 ? .skipped : .taken
            let history = DoseHistory(
                status: status,
                scheduledTime: scheduledTime,
                actionTime: scheduledTime,
                medicine: aspirin
            )
            context.insert(history)
        }

        // A missed dose
        let missedDose = DoseHistory(
            status: .missed,
            scheduledTime: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            medicine: amoxicillin
        )
        context.insert(missedDose)

        try? context.save()
    }
}
