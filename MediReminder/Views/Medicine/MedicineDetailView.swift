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
    @Environment(\.dismiss) private var dismiss
    @Environment(UserSessionStore.self) private var session

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
                Task {
                    do {
                        try await session.deleteMedicine(medicine)
                        dismiss()
                    } catch {
                        print("Failed to delete medicine: \(error.localizedDescription)")
                    }
                }
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
        VStack(alignment: .leading, spacing: 8) {
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

            Text(takeNowStatusText)
                .font(.caption2)
                .foregroundStyle(canTakeNow ? .green : .secondary)
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
        .disabled(title == "Take Now" && !canTakeNow)
        .opacity(title == "Take Now" && !canTakeNow ? 0.45 : 1.0)
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
        var scheduledTime = Date.now
        var notes = ""

        if status == .taken {
            guard let activeWindow = selectedActiveTakeNowWindow else { return }
            scheduledTime = activeWindow.occurrenceStart
            notes = "take_now_reminder:\(activeWindow.reminder.id.uuidString)"
        }

        Task {
            do {
                _ = try await session.recordDose(
                    medicine: medicine,
                    status: status,
                    scheduledTime: scheduledTime,
                    actionTime: .now,
                    notes: notes
                )
            } catch {
                print("Failed to record dose: \(error.localizedDescription)")
            }
        }
    }

    private var takeNowStatusText: String {
        if canTakeNow {
            if let activeWindow = selectedActiveTakeNowWindow {
                let end = activeWindow.windowEnd.fullString
                return "Take Now is active for this reminder until \(end)."
            }
            return "Take Now is active for an available reminder window."
        }
        return "Take Now is enabled only during each reminder's configured time window and can be used once per reminder occurrence."
    }

    private var canTakeNow: Bool {
        selectedActiveTakeNowWindow != nil
    }

    private var selectedActiveTakeNowWindow: ActiveReminderWindow? {
        activeTakeNowWindows.sorted { $0.windowEnd < $1.windowEnd }.first
    }

    private var activeTakeNowWindows: [ActiveReminderWindow] {
        let now = Date.now
        return medicine.reminders
            .filter { $0.isEnabled }
            .compactMap { reminder in
                guard let occurrenceStart = mostRecentOccurrenceStart(for: reminder, now: now) else {
                    return nil
                }

                let windowHours = max(reminder.takeNowWindowHours, 1)
                guard let windowEnd = Calendar.current.date(byAdding: .hour, value: windowHours, to: occurrenceStart) else {
                    return nil
                }

                guard now >= occurrenceStart, now <= windowEnd else {
                    return nil
                }

                guard !hasTakenRecord(for: reminder, occurrenceStart: occurrenceStart) else {
                    return nil
                }

                return ActiveReminderWindow(reminder: reminder, occurrenceStart: occurrenceStart, windowEnd: windowEnd)
            }
    }

    private func hasTakenRecord(for reminder: Reminder, occurrenceStart: Date) -> Bool {
        let marker = "take_now_reminder:\(reminder.id.uuidString)"
        return medicine.doseHistory.contains { record in
            guard record.status == .taken else { return false }
            guard record.notes.contains(marker) else { return false }
            return abs(record.scheduledTime.timeIntervalSince(occurrenceStart)) < 60
        }
    }

    private func mostRecentOccurrenceStart(for reminder: Reminder, now: Date) -> Date? {
        switch reminder.frequency {
        case .daily:
            return mostRecentDailyOccurrence(reminder: reminder, now: now)
        case .everyOtherDay:
            return mostRecentIntervalOccurrence(reminder: reminder, now: now, intervalDays: 15)
        case .weekly:
            return mostRecentWeeklyOccurrence(reminder: reminder, now: now)
        case .custom:
            return mostRecentIntervalOccurrence(reminder: reminder, now: now, intervalDays: max(reminder.customIntervalDays ?? 1, 1))
        }
    }

    private func mostRecentDailyOccurrence(reminder: Reminder, now: Date) -> Date? {
        let calendar = Calendar.current
        guard let todayCandidate = reminderTime(on: now, reminder: reminder) else { return nil }

        let candidate = todayCandidate <= now
            ? todayCandidate
            : (calendar.date(byAdding: .day, value: -1, to: todayCandidate) ?? todayCandidate)

        guard candidate >= medicine.startDate else { return nil }
        return candidate
    }

    private func mostRecentIntervalOccurrence(reminder: Reminder, now: Date, intervalDays: Int) -> Date? {
        let calendar = Calendar.current
        let safeInterval = max(intervalDays, 1)

        guard var anchor = reminderTime(on: medicine.startDate, reminder: reminder) else {
            return nil
        }

        if anchor < medicine.startDate {
            anchor = calendar.date(byAdding: .day, value: 1, to: anchor) ?? anchor
        }

        if now < anchor { return nil }

        let dayDistance = calendar.dateComponents([.day], from: anchor.startOfDay, to: now.startOfDay).day ?? 0
        let steps = dayDistance / safeInterval
        guard let candidate = calendar.date(byAdding: .day, value: steps * safeInterval, to: anchor) else {
            return nil
        }

        if candidate <= now {
            return candidate
        }

        return calendar.date(byAdding: .day, value: -safeInterval, to: candidate)
    }

    private func mostRecentWeeklyOccurrence(reminder: Reminder, now: Date) -> Date? {
        let calendar = Calendar.current
        let allowedWeekdays = Set(reminder.daysOfWeek)
        guard !allowedWeekdays.isEmpty else { return nil }

        for dayOffset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            guard allowedWeekdays.contains(weekday) else { continue }
            guard let candidate = reminderTime(on: day, reminder: reminder) else { continue }
            guard candidate <= now, candidate >= medicine.startDate else { continue }
            return candidate
        }

        return nil
    }

    private func reminderTime(on date: Date, reminder: Reminder) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminder.time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = 0
        return calendar.date(from: components)
    }

    private struct ActiveReminderWindow {
        let reminder: Reminder
        let occurrenceStart: Date
        let windowEnd: Date
    }
}

// MARK: - Edit Medicine Sheet

struct EditMedicineSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserSessionStore.self) private var session

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
                        Task {
                            if await (viewModel?.save() ?? false) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!(viewModel?.isValid ?? false) || (viewModel?.isSaving ?? false))
                }
            }
            .onAppear {
                viewModel = MedicineDetailViewModel(medicine: medicine, session: session)
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
                instructions: "Take after food with water",
                ownerUserId: AppConstants.previewUserId
            )
        )
    }
    .modelContainer(PersistenceController.preview.modelContainer)
    .environment(
        UserSessionStore(
            previewUser: AuthenticatedUser(uid: AppConstants.previewUserId, email: "preview@example.com"),
            modelContext: PersistenceController.preview.modelContainer.mainContext
        )
    )
}
