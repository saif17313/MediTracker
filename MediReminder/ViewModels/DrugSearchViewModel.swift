//
//  DrugSearchViewModel.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import Observation

/// ViewModel for the drug information search screen.
/// Uses OpenFDA API to search and display drug details.
@Observable
final class DrugSearchViewModel {
    // MARK: - State
    var searchText: String = ""
    var results: [DrugResult] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var hasSearched: Bool = false
    var selectedDrug: DrugResult?

    /// Recent search queries (persisted in UserDefaults)
    var recentSearches: [String] = []

    private let service = OpenFDAService()
    private let recentSearchesKey = "recentDrugSearches"
    private let maxRecentSearches = 10

    // MARK: - Initialization

    init() {
        loadRecentSearches()
    }

    // MARK: - Actions

    /// Performs a drug search with the current search text.
    @MainActor
    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        hasSearched = true

        do {
            results = try await service.searchDrug(query: query)
            saveToRecentSearches(query)
        } catch let error as OpenFDAError {
            errorMessage = error.errorDescription
            results = []
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            results = []
        }

        isLoading = false
    }

    /// Performs a search with a specific query (e.g., from recent searches).
    @MainActor
    func search(query: String) async {
        searchText = query
        await search()
    }

    /// Clears the current search results.
    func clearResults() {
        results = []
        searchText = ""
        hasSearched = false
        errorMessage = nil
        selectedDrug = nil
    }

    /// Removes a specific recent search.
    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearchesToDisk()
    }

    /// Clears all recent searches.
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearchesToDisk()
    }

    // MARK: - Recent Searches Persistence

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    private func saveToRecentSearches(_ query: String) {
        // Remove duplicate if exists
        recentSearches.removeAll { $0.lowercased() == query.lowercased() }

        // Add to front
        recentSearches.insert(query, at: 0)

        // Trim to max
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }

        saveRecentSearchesToDisk()
    }

    private func saveRecentSearchesToDisk() {
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
}
