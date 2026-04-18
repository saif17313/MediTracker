//
//  UserDataSyncService.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import FirebaseFirestore
import SwiftData

/// Firestore-backed snapshot of a user's app data.
struct UserDataSnapshot {
    let medicines: [MedicineDocument]
    let reminders: [ReminderDocument]
    let doseHistory: [DoseHistoryDocument]
}

/// Minimal user profile stored in Firestore.
struct UserProfileDocument: Codable {
    let email: String
    let createdAt: Date
    let lastLoginAt: Date
}

/// Firestore representation of a signed-in device for a user.
struct DeviceDocument: Codable {
    let id: String
    let ownerUserId: String
    let deviceName: String
    let platform: String
    let systemVersion: String
    let notificationsAuthorized: Bool
    let isSignedIn: Bool
    let lastSeenAt: Date
    let lastSignedOutAt: Date?
}

/// Firestore representation of a medicine.
struct MedicineDocument: Codable {
    let id: String
    let ownerUserId: String
    let name: String
    let dosage: String
    let formRawValue: String
    let instructions: String
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let createdAt: Date
}

/// Firestore representation of a reminder.
struct ReminderDocument: Codable {
    let id: String
    let ownerUserId: String
    let medicineId: String
    let time: Date
    let frequencyRawValue: String
    let daysOfWeek: [Int]
    let customIntervalDays: Int?
    let isEnabled: Bool
    let notificationIdentifier: String
    let snoozeDurationMinutes: Int
}

/// Firestore representation of a dose history record.
struct DoseHistoryDocument: Codable {
    let id: String
    let ownerUserId: String
    let medicineId: String
    let statusRawValue: String
    let scheduledTime: Date
    let actionTime: Date?
    let notes: String
}

enum UserDataSyncError: LocalizedError {
    case unauthenticated
    case missingMedicineReference

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "You need to be signed in before syncing data."
        case .missingMedicineReference:
            return "This record is missing its medicine reference."
        }
    }
}

/// Syncs signed-in user data between Firestore and the local SwiftData cache.
@MainActor
final class UserDataSyncService {
    private lazy var firestore = Firestore.firestore()

    func refreshData(for user: AuthenticatedUser, in context: ModelContext) async throws -> [Medicine] {
        try await ensureUserProfile(for: user)
        let snapshot = try await fetchSnapshot(for: user.uid)
        return try apply(snapshot: snapshot, for: user.uid, in: context)
    }

    func registerDevice(
        for user: AuthenticatedUser,
        device: RegisteredDevice,
        notificationsAuthorized: Bool
    ) async throws {
        let document = DeviceDocument(
            id: device.installationId,
            ownerUserId: user.uid,
            deviceName: device.name,
            platform: device.platform,
            systemVersion: device.systemVersion,
            notificationsAuthorized: notificationsAuthorized,
            isSignedIn: true,
            lastSeenAt: .now,
            lastSignedOutAt: nil
        )

        try await deviceDocument(for: user.uid, installationId: device.installationId)
            .setDataAsync(from: document)
    }

    func markDeviceSignedOut(
        for user: AuthenticatedUser,
        device: RegisteredDevice,
        notificationsAuthorized: Bool
    ) async throws {
        let document = DeviceDocument(
            id: device.installationId,
            ownerUserId: user.uid,
            deviceName: device.name,
            platform: device.platform,
            systemVersion: device.systemVersion,
            notificationsAuthorized: notificationsAuthorized,
            isSignedIn: false,
            lastSeenAt: .now,
            lastSignedOutAt: .now
        )

        try await deviceDocument(for: user.uid, installationId: device.installationId)
            .setDataAsync(from: document)
    }

    @discardableResult
    func saveMedicine(
        for user: AuthenticatedUser,
        existingMedicine: Medicine? = nil,
        name: String,
        dosage: String,
        form: MedicineForm,
        instructions: String,
        startDate: Date,
        endDate: Date?,
        in context: ModelContext
    ) async throws -> UUID {
        let medicineId = existingMedicine?.id ?? UUID()
        let document = MedicineDocument(
            id: medicineId.uuidString,
            ownerUserId: user.uid,
            name: name,
            dosage: dosage,
            formRawValue: form.rawValue,
            instructions: instructions,
            startDate: startDate,
            endDate: endDate,
            isActive: existingMedicine?.isActive ?? true,
            createdAt: existingMedicine?.createdAt ?? .now
        )

        try await medicineDocument(for: user.uid, medicineId: medicineId.uuidString)
            .setDataAsync(from: document)
        _ = try await refreshData(for: user, in: context)
        return medicineId
    }

    func deleteMedicine(
        _ medicine: Medicine,
        for user: AuthenticatedUser,
        in context: ModelContext
    ) async throws {
        let batch = firestore.batch()
        batch.deleteDocument(medicineDocument(for: user.uid, medicineId: medicine.id.uuidString))

        for reminder in medicine.reminders {
            batch.deleteDocument(reminderDocument(for: user.uid, reminderId: reminder.id.uuidString))
        }

        for record in medicine.doseHistory {
            batch.deleteDocument(doseHistoryDocument(for: user.uid, recordId: record.id.uuidString))
        }

        try await batch.commitAsync()
        _ = try await refreshData(for: user, in: context)
    }

    func setMedicineActive(
        _ medicine: Medicine,
        isActive: Bool,
        for user: AuthenticatedUser,
        in context: ModelContext
    ) async throws {
        let document = MedicineDocument(
            id: medicine.id.uuidString,
            ownerUserId: user.uid,
            name: medicine.name,
            dosage: medicine.dosage,
            formRawValue: medicine.form.rawValue,
            instructions: medicine.instructions,
            startDate: medicine.startDate,
            endDate: medicine.endDate,
            isActive: isActive,
            createdAt: medicine.createdAt
        )

        try await medicineDocument(for: user.uid, medicineId: medicine.id.uuidString)
            .setDataAsync(from: document)
        _ = try await refreshData(for: user, in: context)
    }

    @discardableResult
    func saveReminder(
        for user: AuthenticatedUser,
        medicine: Medicine,
        existingReminder: Reminder? = nil,
        time: Date,
        frequency: ReminderFrequency,
        daysOfWeek: [Int],
        customIntervalDays: Int? = nil,
        isEnabled: Bool,
        snoozeDurationMinutes: Int,
        in context: ModelContext
    ) async throws -> UUID {
        let reminderId = existingReminder?.id ?? UUID()
        let document = ReminderDocument(
            id: reminderId.uuidString,
            ownerUserId: user.uid,
            medicineId: medicine.id.uuidString,
            time: time,
            frequencyRawValue: frequency.rawValue,
            daysOfWeek: daysOfWeek,
            customIntervalDays: customIntervalDays,
            isEnabled: isEnabled,
            notificationIdentifier: existingReminder?.notificationIdentifier ?? UUID().uuidString,
            snoozeDurationMinutes: snoozeDurationMinutes
        )

        try await reminderDocument(for: user.uid, reminderId: reminderId.uuidString)
            .setDataAsync(from: document)
        _ = try await refreshData(for: user, in: context)
        return reminderId
    }

    func deleteReminder(
        _ reminder: Reminder,
        for user: AuthenticatedUser,
        in context: ModelContext
    ) async throws {
        try await reminderDocument(for: user.uid, reminderId: reminder.id.uuidString)
            .deleteAsync()
        _ = try await refreshData(for: user, in: context)
    }

    @discardableResult
    func recordDose(
        for user: AuthenticatedUser,
        medicine: Medicine,
        status: DoseStatus,
        scheduledTime: Date,
        actionTime: Date?,
        notes: String,
        in context: ModelContext
    ) async throws -> UUID {
        let recordId = UUID()
        let document = DoseHistoryDocument(
            id: recordId.uuidString,
            ownerUserId: user.uid,
            medicineId: medicine.id.uuidString,
            statusRawValue: status.rawValue,
            scheduledTime: scheduledTime,
            actionTime: actionTime,
            notes: notes
        )

        try await doseHistoryDocument(for: user.uid, recordId: recordId.uuidString)
            .setDataAsync(from: document)
        _ = try await refreshData(for: user, in: context)
        return recordId
    }

    func updateDoseRecord(
        _ record: DoseHistory,
        newStatus: DoseStatus,
        for user: AuthenticatedUser,
        in context: ModelContext
    ) async throws {
        guard let medicineId = record.medicine?.id else {
            throw UserDataSyncError.missingMedicineReference
        }

        let document = DoseHistoryDocument(
            id: record.id.uuidString,
            ownerUserId: user.uid,
            medicineId: medicineId.uuidString,
            statusRawValue: newStatus.rawValue,
            scheduledTime: record.scheduledTime,
            actionTime: .now,
            notes: record.notes
        )

        try await doseHistoryDocument(for: user.uid, recordId: record.id.uuidString)
            .setDataAsync(from: document)
        _ = try await refreshData(for: user, in: context)
    }

    func deleteDoseRecord(
        _ record: DoseHistory,
        for user: AuthenticatedUser,
        in context: ModelContext
    ) async throws {
        try await doseHistoryDocument(for: user.uid, recordId: record.id.uuidString)
            .deleteAsync()
        _ = try await refreshData(for: user, in: context)
    }

    private func ensureUserProfile(for user: AuthenticatedUser) async throws {
        let now = Date.now
        let profile = UserProfileDocument(
            email: user.email,
            createdAt: now,
            lastLoginAt: now
        )
        try await userDocument(for: user.uid).setDataAsync(from: profile, merge: true)
    }

    private func fetchSnapshot(for userId: String) async throws -> UserDataSnapshot {
        async let medicines = fetchMedicineDocuments(for: userId)
        async let reminders = fetchReminderDocuments(for: userId)
        async let history = fetchDoseHistoryDocuments(for: userId)

        return try await UserDataSnapshot(
            medicines: medicines,
            reminders: reminders,
            doseHistory: history
        )
    }

    private func fetchMedicineDocuments(for userId: String) async throws -> [MedicineDocument] {
        let snapshot = try await medicinesCollection(for: userId).getDocumentsAsync()
        return try snapshot.documents.compactMap { document in
            try document.data(as: MedicineDocument.self)
        }
    }

    private func fetchReminderDocuments(for userId: String) async throws -> [ReminderDocument] {
        let snapshot = try await remindersCollection(for: userId).getDocumentsAsync()
        return try snapshot.documents.compactMap { document in
            try document.data(as: ReminderDocument.self)
        }
    }

    private func fetchDoseHistoryDocuments(for userId: String) async throws -> [DoseHistoryDocument] {
        let snapshot = try await doseHistoryCollection(for: userId).getDocumentsAsync()
        return try snapshot.documents.compactMap { document in
            try document.data(as: DoseHistoryDocument.self)
        }
    }

    private func apply(
        snapshot: UserDataSnapshot,
        for userId: String,
        in context: ModelContext
    ) throws -> [Medicine] {
        let localMedicines = try context.fetch(
            FetchDescriptor<Medicine>(
                predicate: #Predicate { $0.ownerUserId == userId }
            )
        )
        let localReminders = try context.fetch(
            FetchDescriptor<Reminder>(
                predicate: #Predicate { $0.ownerUserId == userId }
            )
        )
        let localHistory = try context.fetch(
            FetchDescriptor<DoseHistory>(
                predicate: #Predicate { $0.ownerUserId == userId }
            )
        )

        var medicinesById = Dictionary(uniqueKeysWithValues: localMedicines.map { ($0.id.uuidString, $0) })
        var remindersById = Dictionary(uniqueKeysWithValues: localReminders.map { ($0.id.uuidString, $0) })
        var historyById = Dictionary(uniqueKeysWithValues: localHistory.map { ($0.id.uuidString, $0) })

        var remoteMedicineIds = Set<String>()
        for document in snapshot.medicines {
            remoteMedicineIds.insert(document.id)

            let medicine = medicinesById[document.id] ?? Medicine(
                name: document.name,
                dosage: document.dosage,
                form: MedicineForm(rawValue: document.formRawValue) ?? .other,
                instructions: document.instructions,
                startDate: document.startDate,
                endDate: document.endDate,
                ownerUserId: document.ownerUserId
            )

            if medicinesById[document.id] == nil {
                context.insert(medicine)
            }

            medicine.id = UUID(uuidString: document.id) ?? medicine.id
            medicine.ownerUserId = document.ownerUserId
            medicine.name = document.name
            medicine.dosage = document.dosage
            medicine.form = MedicineForm(rawValue: document.formRawValue) ?? .other
            medicine.instructions = document.instructions
            medicine.startDate = document.startDate
            medicine.endDate = document.endDate
            medicine.isActive = document.isActive
            medicine.createdAt = document.createdAt

            medicinesById[document.id] = medicine
        }

        var remoteReminderIds = Set<String>()
        for document in snapshot.reminders {
            guard let medicine = medicinesById[document.medicineId] else { continue }
            remoteReminderIds.insert(document.id)

            let reminder = remindersById[document.id] ?? Reminder(
                time: document.time,
                frequency: ReminderFrequency(rawValue: document.frequencyRawValue) ?? .daily,
                daysOfWeek: document.daysOfWeek,
                customIntervalDays: document.customIntervalDays,
                medicine: medicine,
                snoozeDurationMinutes: document.snoozeDurationMinutes
            )

            if remindersById[document.id] == nil {
                context.insert(reminder)
            }

            reminder.id = UUID(uuidString: document.id) ?? reminder.id
            reminder.ownerUserId = document.ownerUserId
            reminder.time = document.time
            reminder.frequency = ReminderFrequency(rawValue: document.frequencyRawValue) ?? .daily
            reminder.daysOfWeek = document.daysOfWeek
            reminder.customIntervalDays = document.customIntervalDays
            reminder.isEnabled = document.isEnabled
            reminder.notificationIdentifier = document.notificationIdentifier
            reminder.snoozeDurationMinutes = document.snoozeDurationMinutes
            reminder.medicine = medicine

            remindersById[document.id] = reminder
        }

        var remoteHistoryIds = Set<String>()
        for document in snapshot.doseHistory {
            guard let medicine = medicinesById[document.medicineId] else { continue }
            remoteHistoryIds.insert(document.id)

            let record = historyById[document.id] ?? DoseHistory(
                status: DoseStatus(rawValue: document.statusRawValue) ?? .taken,
                scheduledTime: document.scheduledTime,
                actionTime: document.actionTime,
                medicine: medicine,
                notes: document.notes
            )

            if historyById[document.id] == nil {
                context.insert(record)
            }

            record.id = UUID(uuidString: document.id) ?? record.id
            record.ownerUserId = document.ownerUserId
            record.status = DoseStatus(rawValue: document.statusRawValue) ?? .taken
            record.scheduledTime = document.scheduledTime
            record.actionTime = document.actionTime
            record.notes = document.notes
            record.medicine = medicine

            historyById[document.id] = record
        }

        for record in localHistory where !remoteHistoryIds.contains(record.id.uuidString) {
            context.delete(record)
        }
        for reminder in localReminders where !remoteReminderIds.contains(reminder.id.uuidString) {
            context.delete(reminder)
        }
        for medicine in localMedicines where !remoteMedicineIds.contains(medicine.id.uuidString) {
            context.delete(medicine)
        }

        try context.save()

        return try context.fetch(
            FetchDescriptor<Medicine>(
                predicate: #Predicate { $0.ownerUserId == userId },
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
        )
    }

    private func userDocument(for userId: String) -> DocumentReference {
        firestore.collection("users").document(userId)
    }

    private func medicinesCollection(for userId: String) -> CollectionReference {
        userDocument(for: userId).collection("medicines")
    }

    private func remindersCollection(for userId: String) -> CollectionReference {
        userDocument(for: userId).collection("reminders")
    }

    private func doseHistoryCollection(for userId: String) -> CollectionReference {
        userDocument(for: userId).collection("doseHistory")
    }

    private func devicesCollection(for userId: String) -> CollectionReference {
        userDocument(for: userId).collection("devices")
    }

    private func medicineDocument(for userId: String, medicineId: String) -> DocumentReference {
        medicinesCollection(for: userId).document(medicineId)
    }

    private func reminderDocument(for userId: String, reminderId: String) -> DocumentReference {
        remindersCollection(for: userId).document(reminderId)
    }

    private func doseHistoryDocument(for userId: String, recordId: String) -> DocumentReference {
        doseHistoryCollection(for: userId).document(recordId)
    }

    private func deviceDocument(for userId: String, installationId: String) -> DocumentReference {
        devicesCollection(for: userId).document(installationId)
    }
}

private extension DocumentReference {
    func setDataAsync<T: Encodable>(from value: T, merge: Bool = false) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try setData(from: value, merge: merge) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func deleteAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

private extension Query {
    func getDocumentsAsync() async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot else {
                    continuation.resume(throwing: UserDataSyncError.unauthenticated)
                    return
                }

                continuation.resume(returning: snapshot)
            }
        }
    }
}

private extension WriteBatch {
    func commitAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            commit { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
