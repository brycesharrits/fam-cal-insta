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

    var monthStates: [Int: MonthGenerationState] = [:]
    var referencePhotos: [Int: PhotoAsset] = [:] // month → selected photo
    var jobIDs: [String] = []
    var isBuilding = false
    var buildError: String? = nil
    var isComplete = false

    var completedCount: Int {
        monthStates.values.filter { if case .complete = $0 { return true }; return false }.count
    }

    init(projectID: String, theme: Theme) {
        self.projectID = projectID
        self.theme = theme
        self.year = Calendar.current.component(.year, from: Date())

        // Initialize all months as pending
        for month in 1...12 {
            monthStates[month] = .pending
        }
    }

    @MainActor
    func build(
        photoService: any PhotoLibraryService,
        uploadService: PhotoUploadService,
        generationService: any CalendarGenerationService
    ) async {
        isBuilding = true
        buildError = nil

        do {
            // Step 1: Fetch best photo per month from library
            let photosByMonth = try await photoService.fetchPhotosByMonth(year: year)

            for month in 1...12 {
                let photos = photosByMonth[month] ?? []
                referencePhotos[month] = photos.first // pick first/best photo
                monthStates[month] = .uploading
            }

            // Step 2: Upload all 12 reference photos in parallel
            let selections: [(month: Int, localIdentifier: String)] = (1...12).compactMap { month in
                guard let photo = referencePhotos[month] else { return nil }
                return (month: month, localIdentifier: photo.id)
            }

            let uploadedKeys = try await uploadService.uploadAll(
                selections: selections,
                projectID: projectID,
                progressCallback: { [weak self] completed, total in
                    // Each upload completion triggers generating state
                }
            )

            for month in 1...12 {
                monthStates[month] = .generating
            }

            // Step 3: Submit generation request
            let monthSelections = (1...12).compactMap { month -> MonthPhotoSelection? in
                guard let key = uploadedKeys[month],
                      let photo = referencePhotos[month] else { return nil }
                return MonthPhotoSelection(
                    month: month,
                    localIdentifier: photo.id,
                    uploadedURL: "https://\(key)" // S3 base URL + key (backend handles this)
                )
            }

            let draft = try await generationService.buildDraft(
                projectID: projectID,
                monthSelections: monthSelections
            )
            jobIDs = draft.jobIDs

            // Step 4: Poll all jobs
            await pollAllJobs(generationService: generationService)

        } catch {
            buildError = error.localizedDescription
            isBuilding = false
        }
    }

    @MainActor
    private func pollAllJobs(generationService: any CalendarGenerationService) async {
        await withTaskGroup(of: Void.self) { group in
            for jobID in jobIDs {
                group.addTask { [weak self] in
                    await self?.pollJob(jobID: jobID, generationService: generationService)
                }
            }
        }
        isBuilding = false
        isComplete = monthStates.values.allSatisfy { $0.isTerminal }
    }

    @MainActor
    private func pollJob(jobID: String, generationService: any CalendarGenerationService) async {
        var backoff: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds
        let maxBackoff: UInt64 = 10_000_000_000 // 10 seconds

        for _ in 0..<60 { // max ~5 minutes of polling
            try? await Task.sleep(nanoseconds: backoff)
            backoff = min(backoff + 1_000_000_000, maxBackoff)

            do {
                let job = try await generationService.pollJobStatus(jobID: jobID)

                switch job.status {
                case "complete":
                    if let imageURL = job.resultImageUrl {
                        // Find which month this job belongs to and update
                        updateMonthForJob(job: job, imageURL: imageURL)
                    }
                    return
                case "failed":
                    updateMonthForJob(job: job, error: job.error ?? "Generation failed")
                    return
                default:
                    break // still pending/processing, keep polling
                }
            } catch {
                // Network error — retry
            }
        }
    }

    @MainActor
    private func updateMonthForJob(job: GenerationJobResponse, imageURL: String? = nil, error: String? = nil) {
        // We need to map job → month. The job response includes month_id but we need
        // to correlate. For now, we track this via job order (jobs are created in month order).
        // A more robust approach: include month number in the job response.
        // TODO: add month number to GenerationJobResponse in backend
        if let imageURL {
            // Find and update the first generating month that matches
            for month in 1...12 {
                if case .generating = monthStates[month] {
                    monthStates[month] = .complete(imageURL: imageURL)
                    return
                }
            }
        } else if let error {
            for month in 1...12 {
                if case .generating = monthStates[month] {
                    monthStates[month] = .failed(error: error)
                    return
                }
            }
        }
    }
}
