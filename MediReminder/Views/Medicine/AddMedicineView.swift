//
//  AddMedicineView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// A sheet view for adding a new medicine.
/// Contains a form with all medicine fields and validation.
struct AddMedicineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserSessionStore.self) private var session

    @State private var viewModel: MedicineDetailViewModel?

    /// Callback when a medicine is successfully added
    var onSaved: (() -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    MedicineFormContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await (viewModel?.save() ?? false) {
                                onSaved?()
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!(viewModel?.isValid ?? false) || (viewModel?.isSaving ?? false))
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = MedicineDetailViewModel(session: session)
                }
            }
        }
    }
}

// MARK: - Medicine Form Content (Shared between Add and Edit)

/// Reusable form content for both adding and editing a medicine.
struct MedicineFormContent: View {
    @Bindable var viewModel: MedicineDetailViewModel

    var body: some View {
        Form {
            // MARK: - Basic Information
            Section("Medicine Information") {
                TextField("Medicine Name", text: $viewModel.name)
                    .textContentType(.name)
                    .autocorrectionDisabled()

                TextField("Dosage (e.g., 500mg, 10ml)", text: $viewModel.dosage)
                    .autocorrectionDisabled()

                Picker("Form", selection: $viewModel.form) {
                    ForEach(MedicineForm.allCases) { form in
                        Label(form.displayName, systemImage: form.iconName)
                            .tag(form)
                    }
                }
            }

            // MARK: - Instructions
            Section("Instructions") {
                TextField("e.g., Take after food, before sleep", text: $viewModel.instructions, axis: .vertical)
                    .lineLimit(2...4)
            }

            // MARK: - Schedule
            Section("Schedule") {
                DatePicker(
                    "Start Date",
                    selection: $viewModel.startDate,
                    displayedComponents: .date
                )

                Toggle("Has End Date", isOn: $viewModel.hasEndDate.animation())

                if viewModel.hasEndDate {
                    DatePicker(
                        "End Date",
                        selection: Binding(
                            get: { viewModel.endDate ?? Calendar.current.date(byAdding: .day, value: 7, to: viewModel.startDate) ?? .now },
                            set: { viewModel.endDate = $0 }
                        ),
                        in: viewModel.startDate...,
                        displayedComponents: .date
                    )
                }
            }

            // MARK: - Quick Duration Presets
            if !viewModel.hasEndDate {
                Section("Quick Duration") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            durationPresetButton("3 Days", days: 3)
                            durationPresetButton("1 Week", days: 7)
                            durationPresetButton("2 Weeks", days: 14)
                            durationPresetButton("1 Month", days: 30)
                            durationPresetButton("Ongoing", days: nil)
                        }
                    }
                }
            }

            // MARK: - Error Message
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Duration Preset Button

    private func durationPresetButton(_ title: String, days: Int?) -> some View {
        Button {
            withAnimation {
                if let days = days {
                    viewModel.hasEndDate = true
                    viewModel.endDate = Calendar.current.date(
                        byAdding: .day, value: days, to: viewModel.startDate
                    )
                } else {
                    viewModel.hasEndDate = false
                    viewModel.endDate = nil
                }
            }
        } label: {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AddMedicineView()
        .modelContainer(PersistenceController.preview.modelContainer)
        .environment(
            UserSessionStore(
                previewUser: AuthenticatedUser(uid: AppConstants.previewUserId, email: "preview@example.com"),
                modelContext: PersistenceController.preview.modelContainer.mainContext
            )
        )
}
