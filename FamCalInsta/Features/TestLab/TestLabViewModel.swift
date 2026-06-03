// Disposable Test Lab medium. Calls /api/v1/test/generate and renders the
// result inline. Delete when the spike concludes.

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class TestLabViewModel {
    enum Mode: String, CaseIterable, Identifiable {
        case text = "Prompt only"
        case edit = "Photo + Prompt"
        var id: String { rawValue }

        var apiMode: TestGenerationMode {
            switch self {
            case .text: return .text
            case .edit: return .edit
            }
        }
    }

    var mode: Mode = .text
    var prompt: String = ""
    var selectedImageData: Data? = nil
    var selectedImageMime: String? = nil

    var isGenerating: Bool = false
    var resultImage: UIImage? = nil
    var lastDurationMs: Int? = nil
    var errorMessage: String? = nil

    private let service: any TestGenerationService

    init(service: any TestGenerationService) {
        self.service = service
    }

    var canGenerate: Bool {
        guard !isGenerating else { return false }
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if mode == .edit { return selectedImageData != nil }
        return true
    }

    func setSelectedImage(data: Data, mime: String) {
        selectedImageData = data
        selectedImageMime = mime
    }

    func clearSelectedImage() {
        selectedImageData = nil
        selectedImageMime = nil
    }

    func generate() async {
        guard canGenerate else { return }
        isGenerating = true
        errorMessage = nil
        resultImage = nil
        lastDurationMs = nil
        defer { isGenerating = false }

        do {
            let response = try await service.generate(
                mode: mode.apiMode,
                prompt: prompt,
                imageData: mode == .edit ? selectedImageData : nil,
                imageMime: mode == .edit ? selectedImageMime : nil
            )
            lastDurationMs = response.durationMs

            if response.status == "complete",
               let b64 = response.outputImageBase64,
               let data = Data(base64Encoded: b64),
               let image = UIImage(data: data) {
                resultImage = image
            } else {
                errorMessage = response.errorMessage ?? "Generation failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
