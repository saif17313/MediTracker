//
//  OpenFDAServiceTests.swift
//  MediReminderTests
//
//  Created for MediReminder App
//

import Testing
import Foundation
@testable import MediReminder

/// Tests for OpenFDA API service and response parsing.
struct OpenFDAServiceTests {

    // MARK: - Response Parsing Tests

    @Test func testOpenFDAResponseDecoding() throws {
        let json = """
        {
            "results": [
                {
                    "openfda": {
                        "brand_name": ["Aspirin"],
                        "generic_name": ["Acetylsalicylic acid"],
                        "manufacturer_name": ["Bayer"],
                        "dosage_form": ["TABLET"],
                        "route": ["ORAL"]
                    },
                    "purpose": ["Pain reliever"],
                    "indications_and_usage": ["For temporary relief of headache"],
                    "dosage_and_administration": ["Take 1-2 tablets every 4-6 hours"],
                    "warnings": ["Do not use if allergic to aspirin"],
                    "adverse_reactions": ["Stomach upset may occur"],
                    "drug_interactions": ["Consult a doctor before use with other drugs"],
                    "active_ingredient": ["Aspirin 500mg"]
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenFDAResponse.self, from: data)

        #expect(response.results.count == 1)

        let result = response.results[0]
        #expect(result.openfda?.brandName?.first == "Aspirin")
        #expect(result.openfda?.genericName?.first == "Acetylsalicylic acid")
        #expect(result.openfda?.manufacturerName?.first == "Bayer")
        #expect(result.openfda?.dosageForm?.first == "TABLET")
        #expect(result.openfda?.route?.first == "ORAL")
        #expect(result.purpose?.first == "Pain reliever")
        #expect(result.warnings?.first == "Do not use if allergic to aspirin")
        #expect(result.dosageAndAdministration?.first == "Take 1-2 tablets every 4-6 hours")
    }

    @Test func testOpenFDAResponseWithMissingFields() throws {
        let json = """
        {
            "results": [
                {
                    "openfda": {
                        "brand_name": ["SomeDrug"]
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenFDAResponse.self, from: data)

        #expect(response.results.count == 1)
        let result = response.results[0]
        #expect(result.openfda?.brandName?.first == "SomeDrug")
        #expect(result.openfda?.genericName == nil)
        #expect(result.warnings == nil)
        #expect(result.dosageAndAdministration == nil)
    }

    @Test func testEmptyResponse() throws {
        let json = """
        {
            "results": []
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(OpenFDAResponse.self, from: data)
        #expect(response.results.isEmpty)
    }

    // MARK: - DrugResult Tests

    @Test func testDrugResultSummary() {
        let drug = DrugResult(
            brandName: "Aspirin",
            genericName: "ASA",
            manufacturer: "Bayer",
            dosageForm: "TABLET",
            route: "ORAL",
            purpose: "Pain reliever",
            indicationsAndUsage: nil,
            dosageInstructions: nil,
            warnings: nil,
            adverseReactions: nil,
            drugInteractions: nil,
            activeIngredient: nil
        )

        #expect(drug.summary.contains("TABLET"))
        #expect(drug.summary.contains("ORAL"))
        #expect(drug.summary.contains("Bayer"))
    }

    @Test func testDrugResultEmptySummary() {
        let drug = DrugResult(
            brandName: "Test",
            genericName: "TestGeneric",
            manufacturer: nil,
            dosageForm: nil,
            route: nil,
            purpose: nil,
            indicationsAndUsage: nil,
            dosageInstructions: nil,
            warnings: nil,
            adverseReactions: nil,
            drugInteractions: nil,
            activeIngredient: nil
        )

        #expect(drug.summary == "TestGeneric")
    }

    // MARK: - Error Tests

    @Test func testOpenFDAErrorDescriptions() {
        let errors: [OpenFDAError] = [
            .invalidURL,
            .invalidResponse,
            .rateLimited,
            .serverError(statusCode: 500),
            .decodingError
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}
