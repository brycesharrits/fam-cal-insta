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

        // TODO: re-enable when backend + photo/upload services are ready
        // Real flow:
        //   1. photoService.fetchPhotosByMonth(year:) → referencePhotos
        //   2. uploadService.uploadAll(...) → uploadedKeys
        //   3. generationService.buildDraft(...) → jobIDs
        //   4. pollAllJobs(generationService:) → monthStates .complete / .failed

        // STUB: simulate the upload → generating → complete progression
        await stubBuild()
    }

    @MainActor
    private func stubBuild() async {
        // Phase 1: uploading (staggered per month)
        for month in 1...12 {
            monthStates[month] = .uploading
            try? await Task.sleep(for: .milliseconds(80))
        }

        // Phase 2: all generating
        for month in 1...12 {
            monthStates[month] = .generating
        }

        // Phase 3: complete one by one with random-ish delays
        for month in 1...12 {
            let delay = Int.random(in: 600...2000)
            try? await Task.sleep(for: .milliseconds(delay))
            monthStates[month] = .complete(imageURL: "https://picsum.photos/seed/month\(month)/400/500")
        }

        isBuilding = false
        isComplete = true
    }
}
