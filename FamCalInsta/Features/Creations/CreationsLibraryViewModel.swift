import Foundation
import Observation

@MainActor
@Observable
final class CreationsLibraryViewModel {
    var creations: [CreationResponse] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let service: any CreationsService
    private let pageSize = 50

    init(service: any CreationsService) {
        self.service = service
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await service.list(limit: pageSize, cursor: nil)
            creations = response.creations
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async { await loadInitial() }

    func insert(_ creation: CreationResponse) {
        // Playground-just-created — put at top optimistically so the user
        // sees their new creation without waiting for a refresh.
        if !creations.contains(where: { $0.id == creation.id }) {
            creations.insert(creation, at: 0)
        }
    }

    func delete(_ creation: CreationResponse) async {
        do {
            try await service.delete(id: creation.id)
            creations.removeAll { $0.id == creation.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
