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

    private(set) var firebaseConfigurationState: FirebaseConfigurationState
    private(set) var authState: AuthSessionState = .loading
    private(set) var isWorking: Bool = false
    private(set) var infoMessage: String?
    var errorMessage: String?

    init(
        modelContext: ModelContext,
        authService: AuthService? = AuthService(),
        firebaseConfigurationState: FirebaseConfigurationState
    ) {
        self.modelContext = modelContext
        self.authService = authService
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
        currentUser?.email.isEmpty == false ? currentUser?.email ?? "" : "Signed in user"
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
}
