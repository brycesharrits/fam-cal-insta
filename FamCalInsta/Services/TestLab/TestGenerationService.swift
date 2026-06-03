// Disposable service for the Test Lab medium. Backed by POST /api/v1/test/generate
// which calls OpenAI inline and returns the image as base64. Delete this file
// when the spike concludes.

import Foundation

enum TestGenerationMode: String, Codable {
    case text
    case edit
}

struct TestGenerationRequest: Encodable {
    let mode: String
    let prompt: String
    let inputImageBase64: String?
    let inputImageMime: String?
}

struct TestGenerationResponse: Decodable {
    let id: String
    let mode: String
    let prompt: String
    let status: String
    let outputImageBase64: String?
    let outputImageMime: String?
    let errorMessage: String?
    let durationMs: Int
    let createdAt: String
}

protocol TestGenerationService {
    func generate(mode: TestGenerationMode,
                  prompt: String,
                  imageData: Data?,
                  imageMime: String?) async throws -> TestGenerationResponse
}

final class BackendTestGenerationService: TestGenerationService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func generate(mode: TestGenerationMode,
                  prompt: String,
                  imageData: Data?,
                  imageMime: String?) async throws -> TestGenerationResponse {
        let body = TestGenerationRequest(
            mode: mode.rawValue,
            prompt: prompt,
            inputImageBase64: imageData?.base64EncodedString(),
            inputImageMime: imageMime
        )
        return try await apiClient.request(.testGenerate, body: body)
    }
}
