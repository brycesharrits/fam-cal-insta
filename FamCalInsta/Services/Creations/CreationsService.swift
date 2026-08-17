import Foundation

// Cross-medium Creations library — every generated image is persisted here
// and can be reused by any medium. Backed by /api/v1/creations.

struct CreationResponse: Decodable, Hashable, Identifiable {
    let id: String
    let imageUrl: String
    let thumbnailUrl: String?
    let referenceImageUrl: String?
    let prompt: String
    let provider: String
    let theme: String?
    let createdAt: Date
}

struct CreationListResponse: Decodable {
    let creations: [CreationResponse]
    let nextCursor: String?
}

struct CreateCreationRequest: Encodable {
    let prompt: String
    let theme: String?
    let referenceImageUrl: String?
}

protocol CreationsService {
    func create(prompt: String, theme: String?, referenceImageURL: String?) async throws -> CreationResponse
    func list(limit: Int, cursor: String?) async throws -> CreationListResponse
    func get(id: String) async throws -> CreationResponse
    func delete(id: String) async throws
    /// Links a creation into a calendar month slot. Pass nil creationID to unlink.
    /// Returns the freshly-loaded month with generated_image_url denormalized
    /// from the linked creation.
    func linkToMonth(monthID: String, creationID: String?) async throws -> MonthResponse
}

final class BackendCreationsService: CreationsService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func create(prompt: String, theme: String?, referenceImageURL: String?) async throws -> CreationResponse {
        try await apiClient.request(
            .createCreation,
            body: CreateCreationRequest(prompt: prompt, theme: theme, referenceImageUrl: referenceImageURL)
        )
    }

    func list(limit: Int, cursor: String?) async throws -> CreationListResponse {
        try await apiClient.request(.listCreations(limit: limit, cursor: cursor))
    }

    func get(id: String) async throws -> CreationResponse {
        try await apiClient.request(.getCreation(id: id))
    }

    func delete(id: String) async throws {
        try await apiClient.requestNoContent(.deleteCreation(id: id))
    }

    func linkToMonth(monthID: String, creationID: String?) async throws -> MonthResponse {
        try await apiClient.request(
            .patchMonth(id: monthID),
            body: PatchMonthRequest(creationId: creationID)
        )
    }
}
