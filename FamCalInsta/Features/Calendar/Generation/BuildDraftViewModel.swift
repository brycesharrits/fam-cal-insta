import Foundation
import Observation

enum MonthGenerationState: Equatable {
    case pending
    case uploading
    case generating
    case complete(imageURL: String)
    case failed(error: String)

    var isTerminal: Bool {
        switch self {
        case .complete, .failed: return true
        default: return false
        }
    }
}

@Observable
class BuildDraftViewModel {
    let projectID: String
    let theme: Theme
    var year: Int

    /// Map of month (1-12) → PHAsset localIdentifier chosen in the picker.
    let photoLocalIDs: [Int: String]

    var monthStates: [Int: MonthGenerationState] = [:]
    var referencePhotos: [Int: PhotoAsset] = [:] // month → selected photo (for display)
    var jobIDs: [String] = []
    var isBuilding = false
    var buildError: String? = nil
    var isComplete = false

    var completedCount: Int {
        monthStates.values.filter { if case .complete = $0 { return true }; return false }.count
    }

    init(projectID: String, theme: Theme, photoLocalIDs: [Int: String]) {
        self.projectID = projectID
        self.theme = theme
        self.photoLocalIDs = photoLocalIDs
        self.year = Calendar.current.component(.year, from: Date())

        for month in 1...12 {
            monthStates[month] = .pending
        }
    }

    @MainActor
    func build(
        photoService: any PhotoLibraryService,
        uploadService: PhotoUploadService,
        generationService: any CalendarGenerationService,
        apiClient: APIClient
    ) async {
        isBuilding = true
        buildError = nil

        // Phase 1: upload reference photos in parallel
        let selections = (1...12).compactMap { month -> (month: Int, localIdentifier: String)? in
            guard let id = photoLocalIDs[month] else { return nil }
            monthStates[month] = .uploading
            return (month: month, localIdentifier: id)
        }

        guard !selections.isEmpty else {
            buildError = "No reference photos selected."
            isBuilding = false
            return
        }

        let objectKeys: [Int: String]
        do {
            objectKeys = try await uploadService.uploadAll(
                selections: selections,
                projectID: projectID
            )
        } catch {
            buildError = "Upload failed: \(error.localizedDescription)"
            isBuilding = false
            return
        }

        // Phase 2: submit real generation request
        let monthSelections = objectKeys.map { (month, key) in
            MonthPhotoSelection(month: month, localIdentifier: photoLocalIDs[month] ?? "", uploadedURL: key)
        }

        let draft: DraftBuildResponse
        do {
            draft = try await generationService.buildDraft(
                projectID: projectID,
                monthSelections: monthSelections
            )
        } catch {
            buildError = "Generation failed: \(error.localizedDescription)"
            isBuilding = false
            return
        }

        jobIDs = draft.jobIDs
        for month in objectKeys.keys {
            monthStates[month] = .generating
        }

        // Phase 3: poll all jobs in parallel until terminal
        await withTaskGroup(of: Void.self) { group in
            for jobID in draft.jobIDs {
                group.addTask { [weak self] in
                    await self?.pollUntilTerminal(jobID: jobID, generationService: generationService)
                }
            }
        }

        isBuilding = false
        isComplete = true
    }

    private func pollUntilTerminal(
        jobID: String,
        generationService: any CalendarGenerationService
    ) async {
        // Exponential backoff: 2s → 10s, up to ~5 min total
        var delaySeconds: Double = 2
        for _ in 0..<60 {
            try? await Task.sleep(for: .seconds(delaySeconds))

            let response: GenerationJobResponse
            do {
                response = try await generationService.pollJobStatus(jobID: jobID)
            } catch {
                continue // transient — retry
            }

            await MainActor.run {
                switch response.status {
                case "complete":
                    if let url = response.resultImageUrl {
                        monthStates[response.month] = .complete(imageURL: url)
                    } else {
                        monthStates[response.month] = .failed(error: "missing result url")
                    }
                case "failed":
                    monthStates[response.month] = .failed(error: response.error ?? "generation failed")
                default:
                    break // still queued/processing
                }
            }

            if response.status == "complete" || response.status == "failed" {
                return
            }

            if delaySeconds < 10 { delaySeconds += 1 }
        }
    }
}
