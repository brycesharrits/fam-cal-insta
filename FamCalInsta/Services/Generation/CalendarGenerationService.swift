import Foundation

struct MonthPhotoSelection {
    let month: Int
    let localIdentifier: String
    let uploadedURL: String // S3 URL after upload
}

enum GenerationJobStatus: String {
    case queued
    case processing
    case complete
    case failed
}

struct DraftBuildResponse {
    let jobIDs: [String]
    let estimatedSeconds: Int
}

protocol CalendarGenerationService: AnyObject {
    func buildDraft(projectID: String, monthSelections: [MonthPhotoSelection]) async throws -> DraftBuildResponse
    func regenerateMonth(projectID: String, month: Int, referenceImageURL: String?, prompt: String?) async throws -> String // returns jobID
    func pollJobStatus(jobID: String) async throws -> GenerationJobResponse
}
