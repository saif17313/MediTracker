//
//  DrugSearchView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI

/// Drug information search screen using the OpenFDA API.
/// Allows users to search by drug name and view detailed information.
struct DrugSearchView: View {
    @State private var viewModel = DrugSearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search results or initial state
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.hasSearched && viewModel.results.isEmpty {
                    noResultsView
                } else if !viewModel.results.isEmpty {
                    resultsList
                } else {
                    initialState
                }
            }
            .navigationTitle("Drug Search")
            .searchable(
                text: $viewModel.searchText,
                prompt: "Search drug name (e.g., Aspirin, Ibuprofen)"
            )
            .onSubmit(of: .search) {
                Task {
                    await viewModel.search()
                }
            }
            .sheet(item: $viewModel.selectedDrug) { drug in
                DrugDetailSheet(drug: drug)
            }
        }
    }

    // MARK: - Initial State

    private var initialState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("Search Drug Information")
                .font(.title3)
                .fontWeight(.medium)

            Text("Enter a medicine name to find dosage information, warnings, side effects, and drug interactions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Recent Searches
            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Searches")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button("Clear") {
                            viewModel.clearRecentSearches()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.recentSearches, id: \.self) { query in
                                Button {
                                    Task {
                                        await viewModel.search(query: query)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.caption2)
                                        Text(query)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
            }

            // Common Drug Suggestions
            VStack(alignment: .leading, spacing: 8) {
                Text("Common Searches")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal)

                let suggestions = ["Aspirin", "Ibuprofen", "Amoxicillin", "Metformin", "Lisinopril", "Acetaminophen"]

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(suggestions, id: \.self) { drug in
                        Button {
                            Task {
                                await viewModel.search(query: drug)
                            }
                        } label: {
                            Text(drug)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 10)

            Spacer()
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            Section {
                Text("\(viewModel.results.count) result(s) found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(viewModel.results) { drug in
                Button {
                    viewModel.selectedDrug = drug
                } label: {
                    drugResultRow(drug)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func drugResultRow(_ drug: DrugResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(drug.brandName)
                .font(.headline)

            Text(drug.genericName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(drug.summary)
                .font(.caption)
                .foregroundStyle(.blue)

            if let purpose = drug.purpose {
                Text(purpose.truncated(to: 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Search Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.search()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
        } description: {
            Text("No drugs found matching \"\(viewModel.searchText)\". Try a different spelling or the generic name.")
        }
    }
}

// MARK: - Drug Detail Sheet

/// Detailed view of a drug's information from OpenFDA.
struct DrugDetailSheet: View {
    let drug: DrugResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(drug.brandName)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(drug.genericName)
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        if let manufacturer = drug.manufacturer {
                            Text("By \(manufacturer)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            if let form = drug.dosageForm {
                                infoBadge(form, icon: "pill.fill")
                            }
                            if let route = drug.route {
                                infoBadge(route, icon: "arrow.right.circle.fill")
                            }
                        }
                        .padding(.top, 4)
                    }

                    Divider()

                    // Information Sections
                    if let activeIngredient = drug.activeIngredient {
                        infoSection(title: "Active Ingredient", icon: "flask.fill", content: activeIngredient)
                    }

                    if let purpose = drug.purpose {
                        infoSection(title: "Purpose", icon: "target", content: purpose)
                    }

                    if let indications = drug.indicationsAndUsage {
                        infoSection(title: "Indications & Usage", icon: "heart.text.square.fill", content: indications)
                    }

                    if let dosage = drug.dosageInstructions {
                        infoSection(title: "Dosage & Administration", icon: "clock.fill", content: dosage)
                    }

                    if let warnings = drug.warnings {
                        infoSection(title: "⚠️ Warnings", icon: "exclamationmark.triangle.fill", content: warnings, isWarning: true)
                    }

                    if let adverseReactions = drug.adverseReactions {
                        infoSection(title: "Adverse Reactions", icon: "xmark.shield.fill", content: adverseReactions)
                    }

                    if let interactions = drug.drugInteractions {
                        infoSection(title: "Drug Interactions", icon: "arrow.triangle.merge", content: interactions)
                    }

                    // Disclaimer
                    Text("Information provided by OpenFDA. This is for informational purposes only and should not replace professional medical advice.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Drug Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func infoBadge(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }

    private func infoSection(title: String, icon: String, content: String, isWarning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(isWarning ? .red : .blue)
                Text(title)
                    .font(.headline)
            }

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isWarning ? Color.red.opacity(0.05) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Preview

#Preview {
    DrugSearchView()
}
