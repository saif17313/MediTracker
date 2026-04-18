//
//  OpenFDAService.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation

/// Service for searching drug information via the OpenFDA API.
/// Fetches drug labels including usage, warnings, side effects, and dosage guidance.
struct OpenFDAService {
    private let baseURL = AppConstants.openFDABaseURL

    // MARK: - Public API

    /// Searches for a drug by name (either brand or generic name).
    /// Returns an array of `DrugResult` with parsed information.
    func searchDrug(query: String) async throws -> [DrugResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }

        let encodedQuery = query
            .trimmingCharacters(in: .whitespaces)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        // Search both brand name and generic name using OR
        let urlString = "\(baseURL)?search=openfda.brand_name:\"\(encodedQuery)\"+openfda.generic_name:\"\(encodedQuery)\"&limit=10"

        guard let url = URL(string: urlString) else {
            throw OpenFDAError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFDAError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            // No results found — not an error, just empty
            return []
        case 429:
            throw OpenFDAError.rateLimited
        default:
            throw OpenFDAError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenFDAResponse.self, from: data)

        return decoded.results.compactMap { result in
            DrugResult(
                brandName: result.openfda?.brandName?.first ?? "Unknown",
                genericName: result.openfda?.genericName?.first ?? "Unknown",
                manufacturer: result.openfda?.manufacturerName?.first,
                dosageForm: result.openfda?.dosageForm?.first,
                route: result.openfda?.route?.first,
                purpose: result.purpose?.first,
                indicationsAndUsage: result.indicationsAndUsage?.first,
                dosageInstructions: result.dosageAndAdministration?.first,
                warnings: result.warnings?.first,
                adverseReactions: result.adverseReactions?.first,
                drugInteractions: result.drugInteractions?.first,
                activeIngredient: result.activeIngredient?.first
            )
        }
    }
}

// MARK: - API Response Models

/// Root response from OpenFDA API
struct OpenFDAResponse: Codable {
    let results: [OpenFDAResult]
}

/// A single drug label result from the API
struct OpenFDAResult: Codable {
    let openfda: OpenFDAInfo?
    let purpose: [String]?
    let indicationsAndUsage: [String]?
    let dosageAndAdministration: [String]?
    let warnings: [String]?
    let adverseReactions: [String]?
    let drugInteractions: [String]?
    let activeIngredient: [String]?

    enum CodingKeys: String, CodingKey {
        case openfda
        case purpose
        case indicationsAndUsage = "indications_and_usage"
        case dosageAndAdministration = "dosage_and_administration"
        case warnings
        case adverseReactions = "adverse_reactions"
        case drugInteractions = "drug_interactions"
        case activeIngredient = "active_ingredient"
    }
}

/// Nested OpenFDA information within each result
struct OpenFDAInfo: Codable {
    let brandName: [String]?
    let genericName: [String]?
    let manufacturerName: [String]?
    let dosageForm: [String]?
    let route: [String]?
    let productType: [String]?

    enum CodingKeys: String, CodingKey {
        case brandName = "brand_name"
        case genericName = "generic_name"
        case manufacturerName = "manufacturer_name"
        case dosageForm = "dosage_form"
        case route
        case productType = "product_type"
    }
}

// MARK: - Parsed Drug Result

/// A clean, parsed drug result ready for display in the UI.
struct DrugResult: Identifiable {
    let id = UUID()
    let brandName: String
    let genericName: String
    let manufacturer: String?
    let dosageForm: String?
    let route: String?
    let purpose: String?
    let indicationsAndUsage: String?
    let dosageInstructions: String?
    let warnings: String?
    let adverseReactions: String?
    let drugInteractions: String?
    let activeIngredient: String?

    /// Returns a brief summary string
    var summary: String {
        var parts: [String] = []
        if let form = dosageForm { parts.append(form) }
        if let route = route { parts.append(route) }
        if let mfg = manufacturer { parts.append("by \(mfg)") }
        return parts.isEmpty ? genericName : parts.joined(separator: " • ")
    }
}

// MARK: - Errors

/// Errors that can occur during OpenFDA API calls
enum OpenFDAError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case serverError(statusCode: Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(let code):
            return "Server error (HTTP \(code))"
        case .decodingError:
            return "Failed to parse drug information"
        }
    }
}
