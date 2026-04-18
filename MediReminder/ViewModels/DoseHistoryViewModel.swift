//
//  DoseHistoryViewModel.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import SwiftData
import Observation

/// ViewModel for the dose history screen.
/// Tracks dose records, calculates adherence statistics, and filters history by date/medicine.
@Observable
final class DoseHistoryViewModel {
    // MARK: - State
    var allHistory: [DoseHistory] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Filters
    var selectedDateFilter: DateFilter = .week
    var selectedMedicineFilter: Medicine?
    var selectedStatusFilter: DoseStatus?

    private let modelContext: ModelContext
    private let session: UserSessionStore

    init(modelContext: ModelContext, session: UserSessionStore) {
        self.modelContext = modelContext
        self.session = session
    }

    // MARK: - Computed Properties

    /// Filtered history based on current filters
    var filteredHistory: [DoseHistory] {
        var result = allHistory

        // Filter by date range
        let startDate = selectedDateFilter.startDate
        result = result.filter { $0.scheduledTime >= startDate }

        // Filter by medicine
        if let medicine = selectedMedicineFilter {
            result = result.filter { $0.medicine?.id == medicine.id }
        }

        // Filter by status
        if let status = selectedStatusFilter {
            result = result.filter { $0.status == status }
        }

        return result.sorted { $0.scheduledTime > $1.scheduledTime }
    }

    /// History grouped by date (for sectioned list display)
    var historyGroupedByDate: [(date: Date, records: [DoseHistory])] {
        let grouped = Dictionary(grouping: filteredHistory) { $0.scheduledTime.startOfDay }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, records: $0.value.sorted { $0.scheduledTime > $1.scheduledTime }) }
    }

    /// Overall adherence percentage for filtered results
    var adherencePercentage: Double {
        filteredHistory.adherencePercentage
    }

    /// Count of taken doses
    var takenCount: Int {
        filteredHistory.filter { $0.status == .taken }.count
    }

    /// Count of skipped doses
    var skippedCount: Int {
        filteredHistory.filter { $0.status == .skipped }.count
    }

    /// Count of missed doses
    var missedCount: Int {
        filteredHistory.filter { $0.status == .missed }.count
    }

    /// Total number of records in the current filter
    var totalCount: Int {
        filteredHistory.count
    }

    // MARK: - Actions

    /// Fetches all dose history from the data store.
    func fetchHistory() {
        isLoading = true
        errorMessage = nil

        guard let userId = session.currentUser?.uid else {
            allHistory = []
            isLoading = false
            return
        }

        do {
            let descriptor = FetchDescriptor<DoseHistory>(
                predicate: #Predicate { $0.ownerUserId == userId },
                sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
            )
            allHistory = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load dose history: \(error.localizedDescription)"
            allHistory = []
        }

        isLoading = false
    }

    /// Records a dose action for a medicine at the current time.
    func recordDose(
        medicine: Medicine,
        status: DoseStatus,
        scheduledTime: Date = .now,
        notes: String = ""
    ) async {
        errorMessage = nil

        do {
            _ = try await session.recordDose(
                medicine: medicine,
                status: status,
                scheduledTime: scheduledTime,
                actionTime: .now,
                notes: notes
            )
            fetchHistory()
        } catch {
            errorMessage = "Failed to record dose: \(error.localizedDescription)"
        }
    }

    /// Updates an existing dose record's status.
    func updateDoseStatus(_ record: DoseHistory, newStatus: DoseStatus) async {
        errorMessage = nil

        do {
            try await session.updateDoseRecord(record, newStatus: newStatus)
            fetchHistory()
        } catch {
            errorMessage = "Failed to update dose history: \(error.localizedDescription)"
        }
    }

    /// Deletes a dose history record.
    func deleteRecord(_ record: DoseHistory) async {
        errorMessage = nil

        do {
            try await session.deleteDoseRecord(record)
            fetchHistory()
        } catch {
            errorMessage = "Failed to delete record: \(error.localizedDescription)"
        }
    }

    /// Fetches daily adherence data for the calendar view.
    /// Returns a dictionary mapping dates to adherence percentage for that day.
    func dailyAdherence(for month: Date) -> [Date: Double] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: month),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [:] }

        var result: [Date: Double] = [:]

        for day in monthRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { continue }
            let dayRecords = allHistory.filter {
                calendar.isDate($0.scheduledTime, inSameDayAs: date)
            }
            if !dayRecords.isEmpty {
                result[date.startOfDay] = dayRecords.adherencePercentage
            }
        }

        return result
    }
}

// MARK: - Date Filter Enum

/// Predefined date range filters for dose history
enum DateFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case threeMonths = "3 Months"
    case all = "All Time"

    var id: String { rawValue }

    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .today:
            return Date.now.startOfDay
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: .now) ?? .now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: .now) ?? .now
        case .all:
            return .distantPast
        }
    }
}
