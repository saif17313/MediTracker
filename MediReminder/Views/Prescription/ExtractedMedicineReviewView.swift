//
//  ExtractedMedicineReviewView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import SwiftData

/// Review screen shown after OCR extraction.
/// Displays detected medicine candidates with editable fields and checkboxes.
/// User confirms selections before medicines are created in SwiftData.
struct ExtractedMedicineReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: PrescriptionScanViewModel

    /// Shown when user taps "Add Manually" from the empty state
    @State private var showAddMedicine = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.candidates.isEmpty {
                    emptyState
                } else {
                    candidateList
                }
            }
            .navigationTitle("Review Medicines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        viewModel.retryProcessing()
                    }
                }

                if !viewModel.candidates.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            viewModel.saveSelected(modelContext: modelContext)
                            dismiss()
                        } label: {
                            Text("Add \(viewModel.selectedCount)")
                                .fontWeight(.semibold)
                        }
                        .disabled(viewModel.selectedCount == 0)
                    }
                }
            }
            .sheet(isPresented: $showAddMedicine) {
                AddMedicineView()
            }
        }
    }

    // MARK: - Candidate List

    private var candidateList: some View {
        List {
            // Summary header
            Section {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.blue)
                    Text("Found \(viewModel.candidates.count) medicine\(viewModel.candidates.count == 1 ? "" : "s")")
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.selectedCount) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Select/Deselect All
            Section {
                Button {
                    let allSelected = viewModel.candidates.allSatisfy(\.isSelected)
                    for i in viewModel.candidates.indices {
                        viewModel.candidates[i].isSelected = !allSelected
                    }
                } label: {
                    let allSelected = viewModel.candidates.allSatisfy(\.isSelected)
                    Label(
                        allSelected ? "Deselect All" : "Select All",
                        systemImage: allSelected ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.subheadline)
                }
            }

            // Candidate rows
            Section("Detected Medicines") {
                ForEach($viewModel.candidates) { $candidate in
                    CandidateRowView(candidate: $candidate)
                }
            }

            // Raw OCR text (collapsed)
            if !viewModel.rawOCRText.isEmpty {
                Section("Raw OCR Text") {
                    DisclosureGroup("View extracted text") {
                        Text(viewModel.rawOCRText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "doc.questionmark")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Medicines Detected")
                .font(.title3.bold())

            Text("The scan couldn't identify any medicine names and dosages in the image. You can try again with a clearer photo or add medicines manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    dismiss()
                    viewModel.retryProcessing()
                } label: {
                    Label("Try Again", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                }

                Button {
                    showAddMedicine = true
                } label: {
                    Label("Add Manually", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

// MARK: - Candidate Row

/// A single row in the review list representing one extracted medicine candidate.
/// Shows a toggle, editable name/dosage fields, and the original OCR line.
struct CandidateRowView: View {
    @Binding var candidate: ExtractedMedicineCandidate

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Selection toggle
            Button {
                candidate.isSelected.toggle()
            } label: {
                Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(candidate.isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                // Editable name
                TextField("Medicine Name", text: $candidate.name)
                    .font(.headline)
                    .textContentType(.name)

                // Editable dosage
                TextField("Dosage", text: $candidate.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.blue)

                // Form picker
                Picker("Form", selection: $candidate.form) {
                    ForEach(MedicineForm.allCases) { form in
                        Label(form.displayName, systemImage: form.iconName)
                            .tag(form)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)

                // Original OCR line
                Text(candidate.originalLine)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .opacity(candidate.isSelected ? 1.0 : 0.5)
    }
}

// MARK: - Preview

#Preview {
    let vm = PrescriptionScanViewModel()

    ExtractedMedicineReviewView(viewModel: vm)
        .modelContainer(PersistenceController.preview.modelContainer)
        .onAppear {
            vm.candidates = [
                ExtractedMedicineCandidate(
                    name: "Amoxicillin",
                    dosage: "500mg",
                    form: .capsule,
                    originalLine: "1. Amoxicillin 500mg capsule - twice daily"
                ),
                ExtractedMedicineCandidate(
                    name: "Ibuprofen",
                    dosage: "200mg",
                    form: .tablet,
                    originalLine: "2. Ibuprofen 200mg tablet - as needed"
                ),
                ExtractedMedicineCandidate(
                    name: "Cough Syrup",
                    dosage: "10ml",
                    form: .syrup,
                    originalLine: "3. Cough Syrup 10ml - before sleep"
                ),
            ]
            vm.rawOCRText = "Dr. Smith Clinic\n1. Amoxicillin 500mg capsule - twice daily\n2. Ibuprofen 200mg tablet - as needed\n3. Cough Syrup 10ml - before sleep"
        }
}
