//
//  MedicineDetailView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Displays detailed information for a single medicine.
/// Shows medicine info, reminders list, recent dose history, and quick actions.
struct MedicineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let medicine: Medicine

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingReminderList = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Medicine Info Card
                medicineInfoCard

                // MARK: - Quick Actions
                quickActionsSection

                // MARK: - Reminders Section
                remindersSection

                // MARK: - Recent Dose History
                recentHistorySection

                // MARK: - Adherence Stats
                if !medicine.doseHistory.isEmpty {
                    adherenceCard
                }
            }
            .padding()
        }
        .navigationTitle(medicine.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditMedicineSheet(medicine: medicine)
        }
        .alert("Delete Medicine", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                NotificationService.shared.cancelAllReminders(for: medicine)
                modelContext.delete(medicine)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("This will permanently delete \(medicine.name) and all its reminders and history. This cannot be undone.")
        }
    }

    // MARK: - Medicine Info Card

    private var medicineInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: medicine.form.iconName)
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(medicine.dosage) • \(medicine.form.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Active status badge
                Text(medicine.isActive ? "Active" : "Completed")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(medicine.isActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundStyle(medicine.isActive ? .green : .gray)
                    .clipShape(Capsule())
            }

            if !medicine.instructions.isEmpty {
                Divider()
                Label(medicine.instructions, systemImage: "note.text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(medicine.startDate.shortDateString)
                        .font(.subheadline)
                }

                Spacer()

                if let endDate = medicine.endDate {
                    VStack(alignment: .trailing) {
                        Text("End Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(endDate.shortDateString)
                            .font(.subheadline)
                    }
                } else {
                    VStack(alignment: .trailing) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Ongoing")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Record Taken
            quickActionButton(
                title: "Take Now",
                icon: "checkmark.circle.fill",
                color: .green
            ) {
                recordDose(.taken)
            }

            // Record Skipped
            quickActionButton(
                title: "Skip",
                icon: "forward.fill",
                color: .orange
            ) {
                recordDose(.skipped)
            }

            // Manage Reminders
            NavigationLink {
                ReminderListView(medicine: medicine)
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Reminders")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reminders")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    ReminderListView(medicine: medicine)
                }
                .font(.subheadline)
            }

            if medicine.reminders.isEmpty {
                Text("No reminders set")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(medicine.reminders.prefix(3)) { reminder in
                    HStack {
                        Image(systemName: reminder.isEnabled ? "bell.fill" : "bell.slash.fill")
                            .foregroundStyle(reminder.isEnabled ? .blue : .gray)
                        Text(reminder.formattedTime)
                            .font(.subheadline)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(reminder.frequency.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Recent History

    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent History")
                .font(.headline)

            let recentDoses = medicine.doseHistory
                .sorted { $0.scheduledTime > $1.scheduledTime }
                .prefix(5)

            if recentDoses.isEmpty {
                Text("No dose history yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(recentDoses)) { dose in
                    HStack {
                        Image(systemName: dose.status.iconName)
                            .foregroundStyle(Color.forDoseStatus(dose.status))
                        VStack(alignment: .leading) {
                            Text(dose.status.displayName)
                                .font(.subheadline)
                            Text(dose.scheduledTime.fullString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Adherence Card

    private var adherenceCard: some View {
        let percentage = medicine.doseHistory.adherencePercentage

        return VStack(spacing: 8) {
            Text("Adherence")
                .font(.headline)

            Text(String(format: "%.0f%%", percentage))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(percentage >= 80 ? .green : percentage >= 50 ? .orange : .red)

            HStack(spacing: 16) {
                statBadge(count: medicine.doseHistory.filter { $0.status == .taken }.count, label: "Taken", color: .green)
                statBadge(count: medicine.doseHistory.filter { $0.status == .skipped }.count, label: "Skipped", color: .orange)
                statBadge(count: medicine.doseHistory.filter { $0.status == .missed }.count, label: "Missed", color: .red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func recordDose(_ status: DoseStatus) {
        let record = DoseHistory(
            status: status,
            scheduledTime: .now,
            actionTime: .now,
            medicine: medicine
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}

// MARK: - Edit Medicine Sheet

struct EditMedicineSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let medicine: Medicine
    @State private var viewModel: MedicineDetailViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    MedicineFormContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Edit Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel?.save() != nil {
                            dismiss()
                        }
                    }
                    .disabled(!(viewModel?.isValid ?? false))
                }
            }
            .onAppear {
                viewModel = MedicineDetailViewModel(medicine: medicine, modelContext: modelContext)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MedicineDetailView(
            medicine: Medicine(
                name: "Aspirin",
                dosage: "500mg",
                form: .tablet,
                instructions: "Take after food with water"
            )
        )
    }
    .modelContainer(PersistenceController.preview.modelContainer)
}
