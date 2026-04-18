//
//  MediReminderApp.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Main entry point for the MediReminder application.
/// Configures the SwiftData ModelContainer and sets up notification handling.
@main
struct MediReminderApp: App {
    /// App delegate adaptor for handling notification callbacks
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// SwiftData model container for persistence
    let modelContainer: ModelContainer = PersistenceController.shared.modelContainer
    let sessionStore: UserSessionStore

    init() {
        let firebaseConfigurationState = FirebaseBootstrapper.configureIfNeeded()
        sessionStore = UserSessionStore(
            modelContext: modelContainer.mainContext,
            firebaseConfigurationState: firebaseConfigurationState
        )

        // Register notification categories on launch
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionStore)
        }
        .modelContainer(modelContainer)
    }
}
