//
//  AddReminderView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI

/// Sheet view for creating a new reminder.
/// Includes time picker, frequency selection, and day-of-week picker.
struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ReminderViewModel

    /// Day of week labels (Sun=1 through Sat=7)
    private let weekdays: [(id: Int, short: String, full: String)] = {
        let formatter = DateFormatter()
        return (1...7).map { day in
            (id: day,
             short: formatter.shortWeekdaySymbols[day - 1],
             full: formatter.weekdaySymbols[day - 1])
        }
    }()

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Time Selection
                Section("Time") {
                    DatePicker(
                        "Reminder Time",
                        selection: $viewModel.selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                // MARK: - Frequency Selection
                Section("Frequency") {
                    Picker("Repeat", selection: $viewModel.selectedFrequency) {
                        ForEach(ReminderFrequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - Day of Week Picker (for Weekly frequency)
                if viewModel.selectedFrequency == .weekly {
                    Section("Days of Week") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(weekdays, id: \.id) { day in
                                dayButton(day: day)
                            }
                        }
                        .padding(.vertical, 4)

                        if viewModel.selectedDaysOfWeek.isEmpty {
                            Text("Select at least one day")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                if viewModel.selectedFrequency == .custom {
                    Section("Custom Interval") {
                        Stepper(value: $viewModel.selectedCustomIntervalDays, in: 1...30) {
                            let interval = viewModel.selectedCustomIntervalDays
                            Text(interval == 1 ? "Every 1 day" : "Every \(interval) days")
                        }

                        Text("Choose how many days to wait between reminders.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Snooze Duration
                Section("Snooze") {
                    Picker("Snooze Duration", selection: $viewModel.snoozeDuration) {
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                    }
                }

                // MARK: - Summary
                Section("Summary") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Reminder for \(viewModel.medicine.name)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(summaryText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addReminder()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
        }
    }

    // MARK: - Day Button

    private func dayButton(day: (id: Int, short: String, full: String)) -> some View {
        let isSelected = viewModel.selectedDaysOfWeek.contains(day.id)

        return Button {
            if isSelected {
                viewModel.selectedDaysOfWeek.remove(day.id)
            } else {
                viewModel.selectedDaysOfWeek.insert(day.id)
            }
        } label: {
            Text(day.short)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .blue)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        if viewModel.selectedFrequency == .weekly && viewModel.selectedDaysOfWeek.isEmpty {
            return false
        }
        if viewModel.selectedFrequency == .custom && viewModel.selectedCustomIntervalDays < 1 {
            return false
        }
        return true
    }

    // MARK: - Summary Text

    private var summaryText: String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeStr = timeFormatter.string(from: viewModel.selectedTime)

        switch viewModel.selectedFrequency {
        case .daily:
            return "Every day at \(timeStr)"
        case .everyOtherDay:
            return "Every 15 days at \(timeStr)"
        case .weekly:
            let dayNames = viewModel.selectedDaysOfWeek.sorted().compactMap { day -> String? in
                guard day >= 1, day <= 7 else { return nil }
                return DateFormatter().shortWeekdaySymbols[day - 1]
            }
            return "Every \(dayNames.joined(separator: ", ")) at \(timeStr)"
        case .custom:
            let interval = viewModel.selectedCustomIntervalDays
            let dayLabel = interval == 1 ? "day" : "days"
            return "Every \(interval) \(dayLabel) at \(timeStr)"
        }
    }
}

// MARK: - Preview

#Preview {
    AddReminderView(
        viewModel: ReminderViewModel(
            medicine: Medicine(
                name: "Aspirin",
                dosage: "500mg",
                form: .tablet,
                ownerUserId: AppConstants.previewUserId
            ),
            session: UserSessionStore(
                previewUser: AuthenticatedUser(uid: AppConstants.previewUserId, email: "preview@example.com"),
                modelContext: PersistenceController.preview.modelContainer.mainContext
            )
        )
    )
}
