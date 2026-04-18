//
//  PrescriptionScanView.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI
import PhotosUI

/// Main view for the prescription scanning feature.
/// Allows the user to capture or upload one or more prescription pages,
/// then runs OCR and transitions to the review screen.
struct PrescriptionScanView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PrescriptionScanViewModel()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch viewModel.state {
                case .idle, .error:
                    idleContent
                case .scanning:
                    scanningContent
                case .done(let count):
                    doneContent(count: count)
                default:
                    idleContent
                }
            }
            .navigationTitle("Scan Rx")
            .sheet(isPresented: $viewModel.showCamera) {
                CameraPickerView { image in
                    viewModel.addImage(image)
                }
            }
            .sheet(isPresented: $viewModel.showReview) {
                ExtractedMedicineReviewView(viewModel: viewModel)
            }
            .alert(
                "Scan Error",
                isPresented: Binding(
                    get: { if case .error = viewModel.state { return true } else { return false } },
                    set: { if !$0 { viewModel.retryProcessing() } }
                )
            ) {
                Button("Try Again") { viewModel.retryProcessing() }
                Button("Cancel", role: .cancel) { viewModel.reset() }
            } message: {
                if case .error(let msg) = viewModel.state {
                    Text(msg)
                }
            }
        }
    }

    // MARK: - Idle State Content

    private var idleContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header illustration
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Import Prescription")
                        .font(.title2.bold())

                    Text("Take a photo or upload images of your prescription. The app will read and extract medicine details automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)

                // Action buttons
                HStack(spacing: 16) {
                    // Camera button
                    Button {
                        viewModel.showCamera = true
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.title)
                            Text("Camera")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                    }

                    // Upload button
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title)
                            Text("Upload")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                    }
                    .onChange(of: selectedPhotoItems) { _, newItems in
                        Task {
                            await loadPhotos(from: newItems)
                            selectedPhotoItems = []
                        }
                    }
                }
                .padding(.horizontal)

                // Image queue strip
                if viewModel.hasImages {
                    imageQueueSection
                }

                // Scan button
                if viewModel.hasImages {
                    Button {
                        Task {
                            await viewModel.processAllImages()
                        }
                    } label: {
                        Label(
                            "Scan \(viewModel.pageCount) Page\(viewModel.pageCount == 1 ? "" : "s")",
                            systemImage: "doc.text.magnifyingglass"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
    }

    // MARK: - Image Queue

    private var imageQueueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Prescription Pages")
                    .font(.headline)
                Spacer()
                Button("Clear All", role: .destructive) {
                    viewModel.selectedImages = []
                }
                .font(.caption)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )

                            // Page number
                            Text("\(index + 1)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(Circle().fill(.blue))
                                .offset(x: -4, y: 4)

                            // Remove button
                            Button {
                                withAnimation {
                                    viewModel.removeImage(at: index)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white, .red)
                            }
                            .offset(x: 6, y: -6)
                        }
                    }

                    // Add more button
                    Button {
                        viewModel.showCamera = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.title2)
                            Text("Add")
                                .font(.caption2)
                        }
                        .frame(width: 100, height: 130)
                        .background(Color.secondary.opacity(0.1))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .foregroundStyle(.secondary.opacity(0.5))
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Scanning State

    private var scanningContent: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Reading \(viewModel.pageCount) page\(viewModel.pageCount == 1 ? "" : "s")...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Using on-device text recognition")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    // MARK: - Done State

    private func doneContent(count: Int) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("\(count) Medicine\(count == 1 ? "" : "s") Added")
                .font(.title2.bold())
            Text("Check the Medicines tab to manage them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                viewModel.reset()
            } label: {
                Label("Scan Another", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
            }
            .padding(.top)
            Spacer()
        }
    }

    // MARK: - Photo Loading

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.addImage(image)
            }
        }
    }
}

// MARK: - Camera Picker (UIImagePickerController Wrapper)

/// UIViewControllerRepresentable wrapper for UIImagePickerController (camera).
struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    PrescriptionScanView()
        .modelContainer(PersistenceController.preview.modelContainer)
}
