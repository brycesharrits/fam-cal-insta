import Foundation
import Observation

@Observable
class CalendarCanvasViewModel {
    let projectID: String
    var project: ProjectResponse? = nil
    var isLoading = false

    init(projectID: String) {
        self.projectID = projectID
    }

    func load(apiClient: APIClient) async {
        isLoading = true
        do {
            project = try await apiClient.request(.getProject(id: projectID))
        } catch {
            // TODO: show error
        }
        isLoading = false
    }

    func updateMonth(_ updated: MonthResponse) {
        guard var p = project, var months = p.months else { return }
        if let idx = months.firstIndex(where: { $0.id == updated.id }) {
            months[idx] = updated
        }
        // Re-assign (ProjectResponse is a struct, immutable)
        project = ProjectResponse(
            id: p.id, name: p.name, year: p.year, theme: p.theme,
            status: p.status, createdAt: p.createdAt, updatedAt: p.updatedAt,
            months: months
        )
    }
}
