//
//  PrescriptionScanService.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import Vision
import UIKit

// MARK: - Extracted Medicine Candidate

/// A medicine candidate extracted from prescription OCR text.
/// Used in the review screen before creating actual Medicine records.
struct ExtractedMedicineCandidate: Identifiable {
    let id = UUID()
    var name: String
    var dosage: String
    var form: MedicineForm
    var isSelected: Bool = true
    let originalLine: String
}

// MARK: - Prescription Scan Service

/// Handles on-device OCR via Apple Vision framework and parses
/// extracted text to identify medicine name + dosage candidates.
struct PrescriptionScanService {

    // MARK: - OCR

    /// Performs text recognition on a single CGImage using Vision framework.
    /// Uses `.accurate` recognition level with language correction enabled.
    /// - Parameter image: The CGImage to process.
    /// - Returns: The full recognized text as a single string (lines joined by newlines).
    func recognizeText(from image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let lines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: lines.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Performs OCR on multiple images in parallel and returns the combined text.
    /// - Parameter images: Array of UIImages (prescription pages).
    /// - Returns: Combined recognized text from all pages, separated by newlines.
    func recognizeText(from images: [UIImage]) async throws -> String {
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    guard let cgImage = image.cgImage else {
                        return (index, "")
                    }
                    let text = try await self.recognizeText(from: cgImage)
                    return (index, text)
                }
            }

            var results: [(Int, String)] = []
            for try await result in group {
                results.append(result)
            }

            // Sort by original page order and join
            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
                .joined(separator: "\n")
        }
    }

    // MARK: - Medicine Extraction

    /// Parses raw OCR text and extracts medicine candidates using pattern matching.
    /// Looks for lines containing a drug name followed by a dosage (e.g., "Amoxicillin 500mg").
    /// - Parameter text: The full OCR text string.
    /// - Returns: Array of extracted medicine candidates.
    func extractCandidates(from text: String) -> [ExtractedMedicineCandidate] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var candidates: [ExtractedMedicineCandidate] = []
        var seenNames: Set<String> = []

        // Pattern: Medicine name (letters, spaces, hyphens) followed by dosage (number + unit)
        let pattern = #"([A-Za-z][A-Za-z\s\-]{2,}?)\s+(\d+(?:\.\d+)?\s*(?:mg|ml|g|mcg|IU|tabs?|caps?|units?))"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        for line in lines {
            // Strip common numbered-list prefixes: "1.", "2)", "1 -", "•", "-"
            let cleaned = line.replacingOccurrences(
                of: #"^[\d]+[.):\-]?\s*|^[•\-]\s*"#,
                with: "",
                options: .regularExpression
            )

            let range = NSRange(cleaned.startIndex..., in: cleaned)
            guard let match = regex.firstMatch(in: cleaned, options: [], range: range) else {
                continue
            }

            guard let nameRange = Range(match.range(at: 1), in: cleaned),
                  let dosageRange = Range(match.range(at: 2), in: cleaned) else {
                continue
            }

            let name = String(cleaned[nameRange]).trimmingCharacters(in: .whitespaces)
            let dosage = String(cleaned[dosageRange]).trimmingCharacters(in: .whitespaces)

            // Skip very short or obviously wrong names
            guard name.count >= 3 else { continue }

            // Deduplicate by lowercased name
            let key = name.lowercased()
            guard !seenNames.contains(key) else { continue }
            seenNames.insert(key)

            let form = inferMedicineForm(from: line, dosage: dosage)

            candidates.append(ExtractedMedicineCandidate(
                name: name,
                dosage: dosage,
                form: form,
                originalLine: line
            ))
        }

        return candidates
    }

    // MARK: - Form Inference

    /// Infers the MedicineForm from context clues in the prescription line and dosage string.
    private func inferMedicineForm(from line: String, dosage: String) -> MedicineForm {
        let lower = line.lowercased()
        let dosageLower = dosage.lowercased()

        if lower.contains("tab") || lower.contains("tablet") {
            return .tablet
        } else if lower.contains("cap") || lower.contains("capsule") {
            return .capsule
        } else if lower.contains("syrup") || lower.contains("suspension") {
            return .syrup
        } else if lower.contains("injection") || lower.contains("inject") || lower.contains("vial") {
            return .injection
        } else if lower.contains("inhaler") || lower.contains("puff") {
            return .inhaler
        } else if lower.contains("drop") {
            return .drops
        } else if lower.contains("cream") || lower.contains("ointment") || lower.contains("gel") || lower.contains("topical") {
            return .topical
        } else if lower.contains("patch") {
            return .patch
        } else if dosageLower.contains("ml") {
            return .liquid
        } else if dosageLower.contains("mg") || dosageLower.contains("g") {
            return .tablet // default for mg/g
        }

        return .other
    }
}
