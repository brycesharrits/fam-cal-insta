import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PlaygroundViewModel {
    var prompt: String = ""
    var selectedImage: UIImage? = nil
    var isGenerating: Bool = false
    var isUploadingReference: Bool = false
    var errorMessage: String? = nil
    var lastCreation: CreationResponse? = nil

    private let service: any CreationsService
    private let uploadService: PhotoUploadService

    init(service: any CreationsService, uploadService: PhotoUploadService) {
        self.service = service
        self.uploadService = uploadService
    }

    var canGenerate: Bool {
        !isGenerating && !isUploadingReference && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func setReferenceImage(_ image: UIImage) {
        selectedImage = image
    }

    func clearReferenceImage() {
        selectedImage = nil
    }

    func generate() async {
        guard canGenerate else { return }
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        var referenceKey: String? = nil
        if let image = selectedImage, let data = image.jpegData(compressionQuality: 0.85) {
            isUploadingReference = true
            do {
                referenceKey = try await uploadService.uploadCreationReference(data: data)
            } catch {
                errorMessage = "Failed to upload reference image: \(error.localizedDescription)"
                isUploadingReference = false
                return
            }
            isUploadingReference = false
        }

        do {
            lastCreation = try await service.create(
                prompt: prompt,
                theme: nil,
                referenceImageURL: referenceKey
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        prompt = ""
        selectedImage = nil
        lastCreation = nil
        errorMessage = nil
    }
}
