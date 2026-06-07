import Foundation
import Observation

@Observable
class PhotoPickerViewModel {
    let projectID: String

    var allPhotos: [PhotoAsset] = []
    var selections: [Int: String] = [:] // month → PHAsset localIdentifier
    var isLoading = true
    var loadError: String? = nil

    init(projectID: String) {
        self.projectID = projectID
    }

    var allMonthsSelected: Bool {
        (1...12).allSatisfy { selections[$0] != nil }
    }

    @MainActor
    func load(photoService: any PhotoLibraryService) async {
        isLoading = true
        loadError = nil
        do {
            allPhotos = try await photoService.fetchAllPhotos()
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    func select(localID: String, for month: Int) {
        selections[month] = localID
    }

    func clearAll() {
        selections.removeAll()
    }
}
