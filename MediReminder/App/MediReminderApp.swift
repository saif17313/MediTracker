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
    let modelContainer: ModelContainer
    let sessionStore: UserSessionStore

    init() {
        do {
            let schema = Schema([
                Medicine.self,
                Reminder.self,
                DoseHistory.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }

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
