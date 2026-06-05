import Foundation
import SwiftData

@Model
class SavedCreationModel {
    @Attribute(.unique) var id: String
    var sourceImageURL: String
    var localFileName: String
    var prompt: String?
    var themeName: String?
    var monthLabel: String?
    var projectID: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        sourceImageURL: String,
        localFileName: String,
        prompt: String? = nil,
        themeName: String? = nil,
        monthLabel: String? = nil,
        projectID: String? = nil
    ) {
        self.id = id
        self.sourceImageURL = sourceImageURL
        self.localFileName = localFileName
        self.prompt = prompt
        self.themeName = themeName
        self.monthLabel = monthLabel
        self.projectID = projectID
        self.createdAt = Date()
    }
}
