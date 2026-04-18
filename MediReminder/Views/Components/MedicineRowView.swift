//
//  MedicineRowView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI

/// Reusable row component for displaying a medicine in a list.
/// Shows the medicine icon, name, dosage, form, and next reminder time.
struct MedicineRowView: View {
    let medicine: Medicine

    var body: some View {
        // Guard against accessing properties on a deleted/detached SwiftData model.
        // During async delete, SwiftUI may still try to render this row.
        if medicine.isDeleted {
            EmptyView()
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            // Medicine form icon
            Image(systemName: medicine.form.iconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: UIConstants.medicineIconSize + 8, height: UIConstants.medicineIconSize + 8)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Medicine info
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(medicine.dosage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(medicine.form.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Next reminder time
                if let nextReminder = nextReminderText {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(nextReminder)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            // Reminder count badge
            if !medicine.reminders.isEmpty {
                VStack {
                    Text("\(medicine.reminders.filter(\.isEnabled).count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.blue)
                        .clipShape(Circle())

                    Text("reminders")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Computed Properties

    /// Color for the medicine icon based on form type
    private var iconColor: Color {
        switch medicine.form {
        case .tablet:    return .blue
        case .capsule:   return .purple
        case .liquid:    return .cyan
        case .syrup:     return .teal
        case .injection: return .red
        case .topical:   return .green
        case .inhaler:   return .indigo
        case .drops:     return .mint
        case .patch:     return .orange
        case .other:     return .gray
        }
    }

    /// Text showing the next reminder time
    private var nextReminderText: String? {
        let enabledReminders = medicine.reminders.filter(\.isEnabled)
        guard !enabledReminders.isEmpty else { return nil }

        // Find the next upcoming reminder time
        let now = Date.now
        let calendar = Calendar.current
        let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (currentTimeComponents.hour ?? 0) * 60 + (currentTimeComponents.minute ?? 0)

        var nextReminder: Reminder?
        var smallestDiff = Int.max

        for reminder in enabledReminders {
            let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminder.time)
            let reminderMinutes = (reminderComponents.hour ?? 0) * 60 + (reminderComponents.minute ?? 0)

            var diff = reminderMinutes - currentMinutes
            if diff < 0 { diff += 1440 } // Add 24 hours if past today

            if diff < smallestDiff {
                smallestDiff = diff
                nextReminder = reminder
            }
        }

        if let next = nextReminder {
            return "Next: \(next.formattedTime)"
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    List {
        MedicineRowView(
            medicine: Medicine(
                name: "Aspirin",
                dosage: "500mg",
                form: .tablet,
                instructions: "Take after food"
            )
        )
        MedicineRowView(
            medicine: Medicine(
                name: "Amoxicillin",
                dosage: "250mg",
                form: .capsule,
                instructions: "Take before meals"
            )
        )
        MedicineRowView(
            medicine: Medicine(
                name: "Cough Syrup",
                dosage: "10ml",
                form: .syrup,
                instructions: "Take before sleep"
            )
        )
    }
}
