//
//  ContentView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Root view of the app containing the main tab navigation.
/// Provides four tabs: Medicines, History, Drug Search, and Settings.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .medicines
    @State private var navigateToMedicineId: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Medicines Tab
            MedicineListView()
                .tabItem {
                    Label(AppTab.medicines.rawValue, systemImage: AppTab.medicines.iconName)
                }
                .tag(AppTab.medicines)

            // MARK: - History Tab
            DoseHistoryView()
                .tabItem {
                    Label(AppTab.history.rawValue, systemImage: AppTab.history.iconName)
                }
                .tag(AppTab.history)

            // MARK: - Drug Search Tab
            DrugSearchView()
                .tabItem {
                    Label(AppTab.search.rawValue, systemImage: AppTab.search.iconName)
                }
                .tag(AppTab.search)

            // MARK: - Settings Tab
            SettingsView()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.iconName)
                }
                .tag(AppTab.settings)
        }
        .tint(.blue)
        .onReceive(NotificationCenter.default.publisher(for: .openMedicineDetail)) { notification in
            // When user taps a notification, navigate to the medicine
            if let medicineId = notification.userInfo?["medicineId"] as? UUID {
                navigateToMedicineId = medicineId
                selectedTab = .medicines
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .doseActionReceived)) { notification in
            // Handle dose action from notification
            handleDoseAction(from: notification)
        }
        .task {
            // Request notification permission on first launch
            try? await NotificationService.shared.requestAuthorization()
        }
    }

    // MARK: - Notification Handling

    private func handleDoseAction(from notification: Foundation.Notification) {
        guard let medicineIdString = notification.userInfo?["medicineId"] as? UUID,
              let statusString = notification.userInfo?["status"] as? String,
              let status = DoseStatus(rawValue: statusString),
              let scheduledTime = notification.userInfo?["scheduledTime"] as? Date
        else { return }

        // Find the medicine and record the dose
        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.id == medicineIdString }
        )
        guard let medicine = try? modelContext.fetch(descriptor).first else { return }

        let record = DoseHistory(
            status: status,
            scheduledTime: scheduledTime,
            actionTime: .now,
            medicine: medicine
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}

// MARK: - Settings View

/// Basic settings view with notification and app info
struct SettingsView: View {
    @State private var notificationStatus: String = "Checking..."
    @State private var pendingCount: Int = 0

    var body: some View {
        NavigationStack {
            List {
                // MARK: Notifications Section
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

                // MARK: About Section
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

                // MARK: Data Section
                Section("Data") {
                    Label("All data is stored locally on your device.", systemImage: "lock.shield.fill")
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

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview.modelContainer)
}
