//
//  CalendarView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Displays a monthly calendar view showing dose adherence for each day.
/// Days are color-coded: green (high adherence), orange (medium), red (low), gray (no data).
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserSessionStore.self) private var session
    @State private var viewModel: DoseHistoryViewModel?
    @State private var currentMonth: Date = .now
    @State private var dailyAdherence: [Date: Double] = [:]

    private let calendar = Calendar.current
    private let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        return formatter.veryShortWeekdaySymbols
    }()

    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Month Navigation
            monthNavigationHeader

            // MARK: - Weekday Headers
            weekdayHeaderRow

            // MARK: - Calendar Grid
            calendarGrid

            // MARK: - Legend
            legendRow
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .onAppear {
            if viewModel == nil {
                viewModel = DoseHistoryViewModel(modelContext: modelContext, session: session)
                viewModel?.fetchHistory()
            }
            updateAdherence()
        }
        .onChange(of: currentMonth) { _, _ in
            updateAdherence()
        }
    }

    // MARK: - Month Navigation Header

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(monthYearString(for: currentMonth))
                .font(.headline)

            Spacer()

            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
            .disabled(calendar.isDate(currentMonth, equalTo: .now, toGranularity: .month))
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaderRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(height: 20)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth(for: currentMonth)

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            // Empty cells for offset
            ForEach(0..<firstWeekdayOffset(for: currentMonth), id: \.self) { _ in
                Color.clear
                    .frame(width: UIConstants.calendarCellSize, height: UIConstants.calendarCellSize)
            }

            // Day cells
            ForEach(days, id: \.self) { date in
                dayCell(for: date)
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date.now
        let adherence = dailyAdherence[date.startOfDay]

        return VStack(spacing: 2) {
            Text("\(day)")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isFuture ? .secondary : .primary)
        }
        .frame(width: UIConstants.calendarCellSize, height: UIConstants.calendarCellSize)
        .background(
            Group {
                if isToday {
                    Circle().fill(Color.blue.opacity(0.3))
                } else if let adherence = adherence {
                    Circle().fill(adherenceColor(adherence).opacity(0.3))
                } else if !isFuture {
                    Circle().fill(Color.clear)
                }
            }
        )
        .overlay(
            Group {
                if isToday {
                    Circle().stroke(Color.blue, lineWidth: 2)
                }
            }
        )
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 16) {
            legendItem(color: .green, label: "≥ 80%")
            legendItem(color: .orange, label: "50-79%")
            legendItem(color: .red, label: "< 50%")
            legendItem(color: .gray.opacity(0.3), label: "No data")
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func daysInMonth(for date: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private func firstWeekdayOffset(for date: Date) -> Int {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return 0 }
        return calendar.component(.weekday, from: startOfMonth) - 1
    }

    private func adherenceColor(_ percentage: Double) -> Color {
        if percentage >= 80 { return .green }
        if percentage >= 50 { return .orange }
        return .red
    }

    private func updateAdherence() {
        dailyAdherence = viewModel?.dailyAdherence(for: currentMonth) ?? [:]
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .padding()
        .modelContainer(PersistenceController.preview.modelContainer)
        .environment(
            UserSessionStore(
                previewUser: AuthenticatedUser(uid: AppConstants.previewUserId, email: "preview@example.com"),
                modelContext: PersistenceController.preview.modelContainer.mainContext
            )
        )
}
