//
//  UserSessionStore.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import Observation
import SwiftData

/// App-wide session and authentication state.
@MainActor
@Observable
final class UserSessionStore {
    private let modelContext: ModelContext
    private let authService: AuthService?
    private let dataSyncService: UserDataSyncService

    private(set) var firebaseConfigurationState: FirebaseConfigurationState
    private(set) var authState: AuthSessionState = .loading
    private(set) var isWorking: Bool = false
    private(set) var isSyncingCloudData: Bool = false
    private(set) var infoMessage: String?
    var errorMessage: String?

    init(
        modelContext: ModelContext,
        authService: AuthService? = AuthService(),
        dataSyncService: UserDataSyncService = UserDataSyncService(),
        firebaseConfigurationState: FirebaseConfigurationState
    ) {
        self.modelContext = modelContext
        self.authService = authService
        self.dataSyncService = dataSyncService
        self.firebaseConfigurationState = firebaseConfigurationState

        if firebaseConfigurationState.isConfigured {
            startAuthObservation()
        } else {
            authState = .signedOut
        }
    }

    convenience init(previewUser: AuthenticatedUser?, modelContext: ModelContext) {
        self.init(
            modelContext: modelContext,
            authService: nil,
            dataSyncService: UserDataSyncService(),
            firebaseConfigurationState: .configured
        )
        if let previewUser {
            authState = .signedIn(previewUser)
        } else {
            authState = .signedOut
        }
    }

    var currentUser: AuthenticatedUser? {
        guard case let .signedIn(user) = authState else { return nil }
        return user
    }

    var currentUserEmail: String {
        guard let email = currentUser?.email, !email.isEmpty else {
            return "Signed in user"
        }
        return email
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    func signIn(email: String, password: String) async {
        guard ensureFirebaseReady(), let authService else { return }

        isWorking = true
        errorMessage = nil
        infoMessage = nil

        do {
            let user = try await authService.signIn(email: email, password: password)
            authState = .signedIn(user)
            infoMessage = "Signed in successfully."
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    func signUp(email: String, password: String) async {
        guard ensureFirebaseReady(), let authService else { return }

        isWorking = true
        errorMessage = nil
        infoMessage = nil

        do {
            let user = try await authService.signUp(email: email, password: password)
            authState = .signedIn(user)
            infoMessage = "Account created successfully."
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    func sendPasswordReset(to email: String) async {
        guard ensureFirebaseReady(), let authService else { return }

        isWorking = true
        errorMessage = nil
        infoMessage = nil

        do {
            try await authService.sendPasswordReset(to: email)
            infoMessage = "Password reset email sent to \(email)."
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    func signOut() {
        guard let authService else { return }

        errorMessage = nil
        infoMessage = nil

        do {
            try authService.signOut()
            authState = .signedOut
            clearLocalData()
            NotificationService.shared.cancelAllPendingReminders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    func refreshCurrentUserData() async {
        guard let user = currentUser else { return }

        isSyncingCloudData = true
        errorMessage = nil

        do {
            let medicines = try await dataSyncService.refreshData(for: user, in: modelContext)
            NotificationService.shared.refreshAllReminders(medicines: medicines)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSyncingCloudData = false
    }

    func saveMedicine(
        existingMedicine: Medicine? = nil,
        name: String,
        dosage: String,
        form: MedicineForm,
        instructions: String,
        startDate: Date,
        endDate: Date?
    ) async throws {
        guard let user = currentUser else {
            throw UserDataSyncError.unauthenticated
        }

        isSyncingCloudData = true
        defer { isSyncingCloudData = false }

        _ = try await dataSyncService.saveMedicine(
            for: user,
            existingMedicine: existingMedicine,
            name: name,
            dosage: dosage,
            form: form,
            instructions: instructions,
            startDate: startDate,
            endDate: endDate,
            in: modelContext
        )
        NotificationService.shared.refreshAllReminders(medicines: localMedicinesForCurrentUser())
    }

    func deleteMedicine(_ medicine: Medicine) async throws {
        guard let user = currentUser else {
            throw UserDataSyncError.unauthenticated
        }

        isSyncingCloudData = true
        defer { isSyncingCloudData = false }

        try await dataSyncService.deleteMedicine(medicine, for: user, in: modelContext)
        NotificationService.shared.refreshAllReminders(medicines: localMedicinesForCurrentUser())
    }

    func setMedicineActive(_ medicine: Medicine, isActive: Bool) async throws {
        guard let user = currentUser else {
            throw UserDataSyncError.unauthenticated
        }

        isSyncingCloudData = true
        defer { isSyncingCloudData = false }

        try await dataSyncService.setMedicineActive(medicine, isActive: isActive, for: user, in: modelContext)
        NotificationService.shared.refreshAllReminders(medicines: localMedicinesForCurrentUser())
    }

    @discardableResult
    func saveReminder(
        medicine: Medicine,
        existingReminder: Reminder? = nil,
        time: Date,
        frequency: ReminderFrequency,
        daysOfWeek: [Int],
        isEnabled: Bool,
        snoozeDurationMinutes: Int
    ) async throws -> UUID {
        guard let user = currentUser else {
            throw UserDataSyncError.unauthenticated
        }

        isSyncingCloudData = true
        defer { isSyncingCloudData = false }

        let reminderId = try await dataSyncService.saveReminder(
            for: user,
            medicine: medicine,
            existingReminder: existingReminder,
            time: time,
            frequency: frequency,
            daysOfWeek: daysOfWeek,
            isEnabled: isEnabled,
            snoozeDurationMinutes: snoozeDurationMinutes,
            in: modelContext
        )
        NotificationService.shared.refreshAllReminders(medicines: localMedicinesForCurrentUser())
        return reminderId
    }

    func deleteReminder(_ reminder: Reminder) async throws {
        guard let user = currentUser else {
            throw UserDataSyncError.unauthenticated
        }

        isSyncingCloudData = true
        defer { isSyncingCloudData = false }

        try await dataSyncService.deleteReminder(reminder, for: user, in: modelContext)
        NotificationService.shared.refreshAllReminders(medicines: localMedicinesForCurrentUser())
    }

    @discardableResult
    func recordDose(
        medicine: Medicine,
        status: DoseStatus,
        scheduledTime: Date,
        actionTime: Date?,
        notes: String = ""
    ) async throws -> UUID {
        guard let user = currentUser else {
            throw UserDataSyncError.unauthenticated
        }

        isSyncingCloudData = true
        defer { isSyncingCloudData = false }

        let recordId = try await dataSyncService.recordDose(
            for: user,
            medicine: medicine,
            status: status,
            scheduledTime: scheduledTime,
            actionTime: actionTime,
            notes: notes,
            in: modelContext
        )
        NotificationService.shared.refreshAllReminders(medicines: localMedicinesForCurrentUser())
        return recordId
    }

    func updateDoseRecord(_ record: DoseHistory, newStatus: DoseStatus) async throws {
        guard let user = currentUser else {
            throw UserDataSyncError.unauthenticated
        }

        isSyncingCloudData = true
        defer { isSyncingCloudData = false }

        try await dataSyncService.updateDoseRecord(record, newStatus: newStatus, for: user, in: modelContext)
    }

    func deleteDoseRecord(_ record: DoseHistory) async throws {
        guard let user = currentUser else {
            throw UserDataSyncError.unauthenticated
        }

        isSyncingCloudData = true
        defer { isSyncingCloudData = false }

        try await dataSyncService.deleteDoseRecord(record, for: user, in: modelContext)
    }

    private func startAuthObservation() {
        authService?.startListening { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.authState = state

                switch state {
                case .loading:
                    break
                case .signedOut:
                    self.clearLocalData()
                    NotificationService.shared.cancelAllPendingReminders()
                case .signedIn:
                    self.clearLocalData()
                    NotificationService.shared.cancelAllPendingReminders()
                    await self.refreshCurrentUserData()
                }
            }
        }
    }

    @discardableResult
    private func ensureFirebaseReady() -> Bool {
        guard firebaseConfigurationState.isConfigured else {
            errorMessage = firebaseConfigurationState.userFacingMessage
            return false
        }
        return true
    }

    private func clearLocalData() {
        do {
            for reminder in try modelContext.fetch(FetchDescriptor<Reminder>()) {
                modelContext.delete(reminder)
            }
            for record in try modelContext.fetch(FetchDescriptor<DoseHistory>()) {
                modelContext.delete(record)
            }
            for medicine in try modelContext.fetch(FetchDescriptor<Medicine>()) {
                modelContext.delete(medicine)
            }
            try modelContext.save()
        } catch {
            errorMessage = "Failed to reset local data: \(error.localizedDescription)"
        }
    }

    private func localMedicinesForCurrentUser() -> [Medicine] {
        guard let currentUser else { return [] }
        let userId = currentUser.uid

        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.ownerUserId == userId },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

}
