//
//  TimePickerField.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI

/// A styled time picker component for selecting reminder times.
/// Wraps DatePicker in hour-and-minute mode with a clean card style.
struct TimePickerField: View {
    let title: String
    @Binding var selectedTime: Date
    var style: TimePickerStyle = .compact

    var body: some View {
        switch style {
        case .compact:
            compactPicker
        case .wheel:
            wheelPicker
        case .inline:
            inlinePicker
        }
    }

    // MARK: - Compact Style

    private var compactPicker: some View {
        HStack {
            Label(title, systemImage: "clock.fill")
                .font(.subheadline)

            Spacer()

            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
    }

    // MARK: - Wheel Style

    private var wheelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Inline Style (Card)

    private var inlinePicker: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(selectedTime.timeString)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }

            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 120)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
    }
}

// MARK: - Time Picker Style

enum TimePickerStyle {
    case compact
    case wheel
    case inline
}

// MARK: - Multi-Time Selector

/// Allows selecting multiple times of day (for medicines taken 2-3 times daily).
struct MultiTimeSelector: View {
    @Binding var times: [Date]
    var maxTimes: Int = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(times.indices, id: \.self) { index in
                HStack {
                    Text("Dose \(index + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50)

                    DatePicker(
                        "",
                        selection: $times[index],
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()

                    if times.count > 1 {
                        Button {
                            withAnimation {
                                times.remove(atOffsets: IndexSet(integer: index))
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            if times.count < maxTimes {
                Button {
                    withAnimation {
                        // Default new time: 2 hours after the last one
                        let lastTime = times.last ?? .now
                        let newTime = Calendar.current.date(byAdding: .hour, value: 2, to: lastTime) ?? .now
                        times.append(newTime)
                    }
                } label: {
                    Label("Add Time", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        TimePickerField(
            title: "Morning Dose",
            selectedTime: .constant(.now),
            style: .compact
        )

        Divider()

        TimePickerField(
            title: "Select Time",
            selectedTime: .constant(.now),
            style: .inline
        )

        Divider()

        MultiTimeSelector(
            times: .constant([
                Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now,
                Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: .now) ?? .now,
                Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now
            ])
        )
    }
    .padding()
}
