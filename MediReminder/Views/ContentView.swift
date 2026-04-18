//
//  ContentView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Root view of the app.
/// Shows the authentication flow until a user signs in.
struct ContentView: View {
    @Environment(UserSessionStore.self) private var session

    var body: some View {
        Group {
            switch session.authState {
            case .loading:
                ProgressView("Checking account...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .signedOut:
                AuthGateView()

            case .signedIn:
                AuthenticatedHomeView()
            }
        }
    }
}

/// Main signed-in application shell with the tab navigation.
struct AuthenticatedHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserSessionStore.self) private var session
    @State private var selectedTab: AppTab = .medicines
    @State private var navigateToMedicineId: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            MedicineListView()
                .tabItem {
                    Label(AppTab.medicines.rawValue, systemImage: AppTab.medicines.iconName)
                }
                .tag(AppTab.medicines)

            DoseHistoryView()
                .tabItem {
                    Label(AppTab.history.rawValue, systemImage: AppTab.history.iconName)
                }
                .tag(AppTab.history)

            DrugSearchView()
                .tabItem {
                    Label(AppTab.search.rawValue, systemImage: AppTab.search.iconName)
                }
                .tag(AppTab.search)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.iconName)
                }
                .tag(AppTab.settings)
        }
        .tint(.blue)
        .onReceive(NotificationCenter.default.publisher(for: .openMedicineDetail)) { notification in
            if let medicineId = notification.userInfo?["medicineId"] as? UUID {
                navigateToMedicineId = medicineId
                selectedTab = .medicines
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .doseActionReceived)) { notification in
            handleDoseAction(from: notification)
        }
        .task {
            try? await NotificationService.shared.requestAuthorization()
        }
    }

    private func handleDoseAction(from notification: Foundation.Notification) {
        guard let medicineIdString = notification.userInfo?["medicineId"] as? UUID,
              let statusString = notification.userInfo?["status"] as? String,
              let status = DoseStatus(rawValue: statusString),
              let scheduledTime = notification.userInfo?["scheduledTime"] as? Date
        else { return }

        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.id == medicineIdString }
        )
        guard let medicine = try? modelContext.fetch(descriptor).first else { return }

        Task {
            do {
                _ = try await session.recordDose(
                    medicine: medicine,
                    status: status,
                    scheduledTime: scheduledTime,
                    actionTime: .now
                )
            } catch {
                print("Failed to sync dose action: \(error.localizedDescription)")
            }
        }
    }
}

/// Settings screen for notification and account actions.
struct SettingsView: View {
    @Environment(UserSessionStore.self) private var session

    @State private var notificationStatus: String = "Checking..."
    @State private var pendingCount: Int = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    HStack {
                        Label("Signed In", systemImage: "person.crop.circle.fill")
                        Spacer()
                        Text(session.currentUserEmail)
                            .foregroundStyle(.secondary)
                    }

                    Button("Sign Out", role: .destructive) {
                        session.signOut()
                    }
                }

                Section("Notifications") {
                    HStack {
                        Label("Permission", systemImage: "bell.fill")
                        Spacer()
                        Text(notificationStatus)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Pending Reminders", systemImage: "clock.badge")
                        Spacer()
                        Text("\(pendingCount)")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task {
                            try? await NotificationService.shared.requestAuthorization()
                            await checkStatus()
                        }
                    } label: {
                        Label("Request Permission", systemImage: "bell.badge.fill")
                    }
                }

                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("iOS Requirement", systemImage: "iphone")
                        Spacer()
                        Text("iOS 17.0+")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Data Source", systemImage: "globe")
                        Spacer()
                        Text("OpenFDA")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    Label("Authentication now gates the app. Firebase sync comes next in this branch.", systemImage: "person.badge.key.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .task {
                await checkStatus()
            }
        }
    }

    private func checkStatus() async {
        let status = await NotificationService.shared.checkAuthorizationStatus()
        switch status {
        case .authorized: notificationStatus = "Granted ✅"
        case .denied:     notificationStatus = "Denied ❌"
        case .notDetermined: notificationStatus = "Not Asked"
        case .provisional: notificationStatus = "Provisional"
        case .ephemeral:   notificationStatus = "Ephemeral"
        @unknown default:  notificationStatus = "Unknown"
        }
        pendingCount = await NotificationService.shared.pendingNotificationCount()
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview.modelContainer)
        .environment(
            UserSessionStore(
                previewUser: AuthenticatedUser(uid: "preview-user", email: "preview@example.com"),
                modelContext: PersistenceController.preview.modelContainer.mainContext
            )
        )
}
