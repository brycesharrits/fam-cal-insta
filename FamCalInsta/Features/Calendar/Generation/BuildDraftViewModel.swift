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
        generationService: any CalendarGenerationService,
        apiClient: APIClient
    ) async {
        isBuilding = true
        buildError = nil

        // Phase 1: show uploading state (staggered per month)
        for month in 1...12 {
            monthStates[month] = .uploading
            try? await Task.sleep(for: .milliseconds(80))
        }

        // Phase 2: round-trip to local backend dev stub. No real photo upload
        // or imagegen yet — just proves the network plumbing works.
        let stubMonths = (1...12).map {
            MonthGenerationInput(month: $0, referenceImageUrl: "stub://\($0)", assetId: nil)
        }
        let response: GenerateCalendarResponse
        do {
            response = try await apiClient.request(
                .devGenerate,
                body: GenerateCalendarRequest(months: stubMonths)
            )
        } catch {
            buildError = error.localizedDescription
            isBuilding = false
            return
        }

        jobIDs = response.jobIds
        for month in 1...12 {
            monthStates[month] = .generating
        }

        // Phase 3: fake completion progression so the magical loading UI still
        // has something to show. Real polling lands when imagegen wires up.
        for month in 1...12 {
            let delay = Int.random(in: 600...2000)
            try? await Task.sleep(for: .milliseconds(delay))
            monthStates[month] = .complete(imageURL: "https://picsum.photos/seed/month\(month)/400/500")
        }

        isBuilding = false
        isComplete = true
    }
}
