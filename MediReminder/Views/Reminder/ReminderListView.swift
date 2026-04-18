//
//  ReminderListView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Displays all reminders for a specific medicine.
/// Allows adding, toggling, and deleting reminders.
struct ReminderListView: View {
    @Environment(\.modelContext) private var modelContext
    let medicine: Medicine

    @State private var viewModel: ReminderViewModel?
    @State private var showingAddReminder = false

    var body: some View {
        Group {
            if let vm = viewModel {
                List {
                    // MARK: - Quick Add Presets
                    Section("Quick Add") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ReminderPreset.allCases) { preset in
                                    Button {
                                        vm.addPreset(preset)
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: preset.iconName)
                                                .font(.title3)
                                            Text(preset.rawValue)
                                                .font(.caption2)
                                        }
                                        .frame(width: 80, height: 60)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // MARK: - Reminders List
                    if vm.reminders.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No Reminders", systemImage: "bell.slash")
                            } description: {
                                Text("Add a reminder to get notified when it's time to take \(medicine.name).")
                            }
                        }
                    } else {
                        Section("Scheduled Reminders") {
                            ForEach(vm.reminders) { reminder in
                                reminderRow(reminder, vm: vm)
                            }
                            .onDelete { offsets in
                                vm.deleteReminders(at: offsets)
                            }
                        }
                    }

                    // MARK: - Permission Warning
                    if !vm.notificationPermissionGranted {
                        Section {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading) {
                                    Text("Notifications Disabled")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Enable notifications to receive medicine reminders.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Button("Enable Notifications") {
                                Task {
                                    await vm.requestNotificationPermission()
                                }
                            }
                        }
                    }

                    // MARK: - Error
                    if let error = vm.errorMessage {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddReminder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            if let vm = viewModel {
                AddReminderView(viewModel: vm)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ReminderViewModel(medicine: medicine, modelContext: modelContext)
            }
            viewModel?.loadReminders()
            Task {
                await viewModel?.checkNotificationPermission()
            }
        }
    }

    // MARK: - Reminder Row

    private func reminderRow(_ reminder: Reminder, vm: ReminderViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.formattedTime)
                    .font(.headline)
                Text(reminder.scheduleDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { _ in vm.toggleReminder(reminder) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReminderListView(
            medicine: Medicine(name: "Aspirin", dosage: "500mg", form: .tablet)
        )
    }
    .modelContainer(PersistenceController.preview.modelContainer)
}
