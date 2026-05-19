import Foundation
import Observation

@Observable
class ProjectsViewModel {
    var projects: [ProjectResponse] = []
    var isLoading = false
    var errorMessage: String?

    func load(apiClient: APIClient) async {
        isLoading = true
        errorMessage = nil
        do {
            projects = try await apiClient.request(.listProjects)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
