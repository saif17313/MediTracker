//
//  MedicineListView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Displays the list of all medicines with search, filter, and swipe-to-delete.
/// Organized into Active and Completed sections.
struct MedicineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UserSessionStore.self) private var session
    @State private var viewModel: MedicineListViewModel?
    @State private var showingAddMedicine = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        ProgressView("Loading medicines...")
                    } else if vm.medicines.isEmpty {
                        emptyStateView
                    } else {
                        medicineListContent(vm: vm)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("My Medicines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMedicine = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ), prompt: "Search medicines...")
            .sheet(isPresented: $showingAddMedicine) {
                AddMedicineView {
                    viewModel?.fetchMedicines()
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = MedicineListViewModel(modelContext: modelContext, session: session)
                }
                viewModel?.fetchMedicines()
            }
            .refreshable {
                await session.refreshCurrentUserData()
                viewModel?.fetchMedicines()
            }
        }
    }

    // MARK: - Medicine List Content

    @ViewBuilder
    private func medicineListContent(vm: MedicineListViewModel) -> some View {
        List {
            // Active Medicines Section
            if !vm.activeMedicines.isEmpty {
                Section {
                    ForEach(vm.activeMedicines) { medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                            MedicineRowView(medicine: medicine)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await vm.deleteMedicine(medicine)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                Task {
                                    await vm.toggleMedicineActive(medicine)
                                }
                            } label: {
                                Label("Complete", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
                } header: {
                    HStack {
                        Text("Active")
                        Spacer()
                        Text("\(vm.activeMedicines.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Inactive (Completed) Medicines Section
            if !vm.inactiveMedicines.isEmpty {
                Section {
                    ForEach(vm.inactiveMedicines) { medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                            MedicineRowView(medicine: medicine)
                                .opacity(0.6)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await vm.deleteMedicine(medicine)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                Task {
                                    await vm.toggleMedicineActive(medicine)
                                }
                            } label: {
                                Label("Reactivate", systemImage: "arrow.counterclockwise")
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    HStack {
                        Text("Completed")
                        Spacer()
                        Text("\(vm.inactiveMedicines.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut, value: vm.searchText)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Medicines", systemImage: "pill.fill")
        } description: {
            Text("Tap the + button to add your first medicine and set up reminders.")
        } actions: {
            Button {
                showingAddMedicine = true
            } label: {
                Text("Add Medicine")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Preview

#Preview {
    MedicineListView()
        .modelContainer(PersistenceController.preview.modelContainer)
        .environment(
            UserSessionStore(
                previewUser: AuthenticatedUser(uid: AppConstants.previewUserId, email: "preview@example.com"),
                modelContext: PersistenceController.preview.modelContainer.mainContext
            )
        )
}
