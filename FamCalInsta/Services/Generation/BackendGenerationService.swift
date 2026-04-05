import Foundation

class BackendGenerationService: CalendarGenerationService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func buildDraft(projectID: String, monthSelections: [MonthPhotoSelection]) async throws -> DraftBuildResponse {
        let months = monthSelections.map {
            MonthGenerationInput(month: $0.month, referenceImageUrl: $0.uploadedURL, assetId: $0.localIdentifier)
        }
        let response: GenerateCalendarResponse = try await apiClient.request(
            .generateCalendar(projectID: projectID),
            body: GenerateCalendarRequest(months: months)
        )
        return DraftBuildResponse(jobIDs: response.jobIds, estimatedSeconds: response.estimatedSeconds)
    }

    func regenerateMonth(projectID: String, month: Int, referenceImageURL: String?, prompt: String?) async throws -> String {
        let response: RegenerateResponse = try await apiClient.request(
            .regenerateMonth(projectID: projectID, month: month),
            body: RegenerateMonthRequest(referenceImageUrl: referenceImageURL, prompt: prompt)
        )
        return response.jobId
    }

    func pollJobStatus(jobID: String) async throws -> GenerationJobResponse {
        return try await apiClient.request(.getJob(id: jobID))
    }
}
