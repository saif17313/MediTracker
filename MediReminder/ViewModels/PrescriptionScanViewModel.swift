//
//  PrescriptionScanViewModel.swift
//  MediReminder
//
//  Created for MediReminder App
//

import Foundation
import SwiftUI
import SwiftData
import Observation

// MARK: - Scan State

/// Represents the current state of the prescription scanning flow.
enum PrescriptionScanState: Equatable {
    case idle
    case scanning
    case reviewing
    case saving
    case done(count: Int)
    case error(String)

    static func == (lhs: PrescriptionScanState, rhs: PrescriptionScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning),
             (.reviewing, .reviewing), (.saving, .saving):
            return true
        case (.done(let a), .done(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - ViewModel

/// ViewModel managing the prescription scan flow: image collection, OCR processing,
/// candidate review, and saving to SwiftData.
@Observable
@MainActor
final class PrescriptionScanViewModel {

    // MARK: - State

    var state: PrescriptionScanState = .idle
    var selectedImages: [UIImage] = []
    var candidates: [ExtractedMedicineCandidate] = []
    var rawOCRText: String = ""

    /// Whether the camera picker sheet is showing
    var showCamera: Bool = false
    /// Whether the photo library picker is showing
    var showPhotoPicker: Bool = false
    /// Whether the review sheet is showing
    var showReview: Bool = false

    // MARK: - Computed

    var selectedCount: Int {
        candidates.filter(\.isSelected).count
    }

    var hasImages: Bool {
        !selectedImages.isEmpty
    }

    var pageCount: Int {
        selectedImages.count
    }

    // MARK: - Private

    private let scanService = PrescriptionScanService()

    // MARK: - Image Management

    /// Adds an image (page) to the scan queue.
    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }

    /// Removes an image at the given index from the scan queue.
    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
    }

    // MARK: - Processing

    /// Runs OCR on all queued images in parallel, then extracts medicine candidates.
    func processAllImages() async {
        guard !selectedImages.isEmpty else { return }

        state = .scanning

        do {
            let text = try await scanService.recognizeText(from: selectedImages)
            rawOCRText = text

            let extracted = scanService.extractCandidates(from: text)
            candidates = extracted
            state = .reviewing
            showReview = true
        } catch {
            state = .error("Failed to read prescription: \(error.localizedDescription)")
        }
    }

    // MARK: - Saving

    /// Saves all selected candidates as Medicine records via UserSessionStore,
    /// which handles both local SwiftData persistence and Firebase sync.
    /// - Parameter session: The app's UserSessionStore instance.
    func saveSelected(session: UserSessionStore) async {
        let selected = candidates.filter(\.isSelected)
        guard !selected.isEmpty else { return }

        state = .saving

        do {
            for candidate in selected {
                try await session.saveMedicine(
                    name: candidate.name,
                    dosage: candidate.dosage,
                    form: candidate.form,
                    instructions: "",
                    startDate: .now,
                    endDate: nil
                )
            }
            state = .done(count: selected.count)
        } catch {
            state = .error("Failed to save medicines: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset

    /// Resets the entire scan flow back to idle.
    func reset() {
        state = .idle
        selectedImages = []
        candidates = []
        rawOCRText = ""
        showReview = false
    }

    /// Resets only the results, keeping images for a retry.
    func retryProcessing() {
        state = .idle
        candidates = []
        rawOCRText = ""
        showReview = false
    }
}
