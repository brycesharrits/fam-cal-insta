import Foundation
import Observation

/// Coordinates state across the three-step calendar creation pager plus the
/// Finalize section. Owns the draft state for a not-yet-created project and
/// the loaded ProjectResponse once the backend row exists.
@Observable
class CalendarProjectHubViewModel {
    // MARK: - Loaded state
    var projectID: String? = nil
    var project: ProjectResponse? = nil

    // MARK: - Draft state (Theme step)
    var draftName: String
    var draftTheme: Theme? = nil

    // MARK: - Layout step working state
    var layoutSeed: Int

    // MARK: - Transient
    var errorMessage: String? = nil
    var isBusy = false

    /// 0 = nothing done, 1 = theme done, 2 = layout done, 3 = ≥1 month generated.
    var progressStage: Int { project?.progressStage ?? 0 }

    /// Highest pager index the user can navigate to.
    /// 0 = Theme only; 1 = + Layout; 2 = + Canvas.
    var maxUnlockedIndex: Int {
        guard projectID != nil else { return 0 }
        return min(progressStage, 2)
    }

    init() {
        self.draftName = "My \(Calendar.current.component(.year, from: Date())) Calendar"
        self.layoutSeed = Int.random(in: Int.min...Int.max)
    }

    /// Called from CalendarProjectView.task. If projectID is provided, hydrate
    /// from the backend. Otherwise stay in draft mode.
    @MainActor
    func bootstrap(projectID: String?, apiClient: APIClient) async {
        self.projectID = projectID
        guard let projectID else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let p: ProjectResponse = try await apiClient.request(.getProject(id: projectID))
            self.project = p
            self.draftName = p.name
            self.draftTheme = Theme.catalog.first(where: { $0.id == p.theme }) ?? Theme.noTheme
            self.layoutSeed = Int(truncatingIfNeeded: p.layoutShuffleSeed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Creates the backend project once Theme+Name are chosen.
    @MainActor
    func confirmTheme(apiClient: APIClient) async -> Bool {
        let theme = draftTheme ?? Theme.noTheme
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Give your calendar a name."
            return false
        }
        isBusy = true
        defer { isBusy = false }
        let year = project?.year ?? Calendar.current.component(.year, from: Date())
        let request = CreateProjectRequest(
            name: trimmedName,
            year: year,
            theme: theme.id,
            prompt: customPromptFragment(for: theme)
        )
        do {
            let created: ProjectResponse = try await apiClient.request(.createProject, body: request)
            self.projectID = created.id
            self.project = created
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Persists the layout seed and bumps progress_stage to ≥2.
    @MainActor
    func confirmLayout(apiClient: APIClient) async -> Bool {
        guard let id = projectID else {
            errorMessage = "Project isn't created yet."
            return false
        }
        isBusy = true
        defer { isBusy = false }
        let request = UpdateProjectRequest(
            name: nil,
            theme: nil,
            layoutShuffleSeed: Int64(layoutSeed)
        )
        do {
            let updated: ProjectResponse = try await apiClient.request(.updateProject(id: id), body: request)
            self.project = updated
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    func reloadProject(apiClient: APIClient) async {
        guard let id = projectID else { return }
        if let p: ProjectResponse = try? await apiClient.request(.getProject(id: id)) {
            self.project = p
        }
    }

    private func customPromptFragment(for theme: Theme) -> String? {
        guard let cfg = theme.customConfig else { return nil }
        return "Custom palette — primary \(cfg.primaryHex), secondary \(cfg.secondaryHex), tertiary \(cfg.tertiaryHex). Style: \(cfg.styleDescriptor)"
    }
}
