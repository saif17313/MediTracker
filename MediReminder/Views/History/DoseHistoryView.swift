//
//  DoseHistoryView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Displays dose history with filtering by date, medicine, and status.
/// Shows adherence statistics and a sectioned date-grouped list.
struct DoseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserSessionStore.self) private var session
    @State private var viewModel: DoseHistoryViewModel?

    @Query(sort: \Medicine.name) private var allMedicines: [Medicine]

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.allHistory.isEmpty && !vm.isLoading {
                        emptyStateView
                    } else {
                        historyContent(vm: vm)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Dose History")
            .onAppear {
                if viewModel == nil {
                    viewModel = DoseHistoryViewModel(modelContext: modelContext, session: session)
                }
                viewModel?.fetchHistory()
            }
            .refreshable {
                await session.refreshCurrentUserData()
                viewModel?.fetchHistory()
            }
        }
    }

    // MARK: - History Content

    @ViewBuilder
    private func historyContent(vm: DoseHistoryViewModel) -> some View {
        VStack(spacing: 0) {
            // MARK: - Adherence Summary Card
            adherenceSummaryCard(vm: vm)
                .padding()

            // MARK: - Filter Bar
            filterBar(vm: vm)

            // MARK: - History List
            if vm.filteredHistory.isEmpty {
                ContentUnavailableView {
                    Label("No Records", systemImage: "clock")
                } description: {
                    Text("No dose records match the selected filters.")
                }
            } else {
                List {
                    ForEach(vm.historyGroupedByDate, id: \.date) { group in
                        Section {
                            ForEach(group.records) { record in
                                doseHistoryRow(record)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Task {
                                                await vm.deleteRecord(record)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        // Quick status change
                                        if record.status != .taken {
                                            Button {
                                                Task {
                                                    await vm.updateDoseStatus(record, newStatus: .taken)
                                                }
                                            } label: {
                                                Label("Taken", systemImage: "checkmark")
                                            }
                                            .tint(.green)
                                        }

                                    }
                            }
                        } header: {
                            HStack {
                                Text(group.date.isToday ? "Today" : group.date.shortDateString)
                                Spacer()
                                let dayAdherence = group.records.adherencePercentage
                                Text(String(format: "%.0f%%", dayAdherence))
                                    .font(.caption)
                                    .foregroundStyle(
                                        dayAdherence >= 80 ? .green : dayAdherence >= 50 ? .orange : .red
                                    )
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    // MARK: - Adherence Summary Card

    private func adherenceSummaryCard(vm: DoseHistoryViewModel) -> some View {
        VStack(spacing: 12) {
            // Overall percentage
            HStack {
                VStack(alignment: .leading) {
                    Text("Adherence Rate")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f%%", vm.adherencePercentage))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            vm.adherencePercentage >= 80 ? .green :
                            vm.adherencePercentage >= 50 ? .orange : .red
                        )
                }
                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: vm.adherencePercentage / 100)
                        .stroke(
                            vm.adherencePercentage >= 80 ? Color.green :
                            vm.adherencePercentage >= 50 ? Color.orange : Color.red,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 60, height: 60)
            }

            // Status breakdown
            HStack(spacing: 16) {
                statPill(count: vm.takenCount, label: "Taken", color: .green, icon: "checkmark.circle.fill")
                statPill(count: vm.skippedCount, label: "Skipped", color: .orange, icon: "forward.fill")
                statPill(count: vm.missedCount, label: "Missed", color: .red, icon: "xmark.circle.fill")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private func statPill(count: Int, label: String, color: Color, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter Bar

    private func filterBar(vm: DoseHistoryViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Date filter
                Menu {
                    ForEach(DateFilter.allCases) { filter in
                        Button {
                            vm.selectedDateFilter = filter
                        } label: {
                            if vm.selectedDateFilter == filter {
                                Label(filter.rawValue, systemImage: "checkmark")
                            } else {
                                Text(filter.rawValue)
                            }
                        }
                    }
                } label: {
                    filterChip(
                        title: vm.selectedDateFilter.rawValue,
                        icon: "calendar",
                        isActive: vm.selectedDateFilter != .week
                    )
                }

                // Medicine filter
                Menu {
                    Button {
                        vm.selectedMedicineFilter = nil
                    } label: {
                        if vm.selectedMedicineFilter == nil {
                            Label("All Medicines", systemImage: "checkmark")
                        } else {
                            Text("All Medicines")
                        }
                    }
                    ForEach(allMedicines.filter { $0.ownerUserId == (session.currentUser?.uid ?? "") }) { medicine in
                        Button {
                            vm.selectedMedicineFilter = medicine
                        } label: {
                            if vm.selectedMedicineFilter?.id == medicine.id {
                                Label(medicine.name, systemImage: "checkmark")
                            } else {
                                Text(medicine.name)
                            }
                        }
                    }
                } label: {
                    filterChip(
                        title: vm.selectedMedicineFilter?.name ?? "All Medicines",
                        icon: "pill",
                        isActive: vm.selectedMedicineFilter != nil
                    )
                }

                // Status filter
                Menu {
                    Button {
                        vm.selectedStatusFilter = nil
                    } label: {
                        if vm.selectedStatusFilter == nil {
                            Label("All Status", systemImage: "checkmark")
                        } else {
                            Text("All Status")
                        }
                    }
                    ForEach(DoseStatus.allCases) { status in
                        Button {
                            vm.selectedStatusFilter = status
                        } label: {
                            if vm.selectedStatusFilter == status {
                                Label(status.displayName, systemImage: "checkmark")
                            } else {
                                Text(status.displayName)
                            }
                        }
                    }
                } label: {
                    filterChip(
                        title: vm.selectedStatusFilter?.displayName ?? "All Status",
                        icon: "line.3.horizontal.decrease",
                        isActive: vm.selectedStatusFilter != nil
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(title: String, icon: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.blue.opacity(0.15) : Color(.systemGray6))
        .foregroundStyle(isActive ? .blue : .primary)
        .clipShape(Capsule())
    }

    // MARK: - Dose History Row

    private func doseHistoryRow(_ record: DoseHistory) -> some View {
        HStack(spacing: 12) {
            DoseBadge(status: record.status)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.medicine?.name ?? "Unknown Medicine")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(record.scheduledTime.timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !record.notes.isEmpty {
                    Text(record.notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let actionTime = record.actionTime {
                VStack(alignment: .trailing) {
                    Text(record.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.forDoseStatus(record.status))
                    Text(actionTime.timeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Dose History", systemImage: "clock.fill")
        } description: {
            Text("Your dose history will appear here once you start taking or logging your medicines.")
        }
    }
}

// MARK: - Preview

#Preview {
    DoseHistoryView()
        .modelContainer(PersistenceController.preview.modelContainer)
        .environment(
            UserSessionStore(
                previewUser: AuthenticatedUser(uid: AppConstants.previewUserId, email: "preview@example.com"),
                modelContext: PersistenceController.preview.modelContainer.mainContext
            )
        )
}
