import Foundation
import SwiftData

@Model
class CalendarMonthModel {
    @Attribute(.unique) var id: String
    var projectID: String
    var month: Int // 1-12
    var referencePhotoAssetID: String?
    var referenceImageURL: String?
    var prompt: String?
    var generatedImageURL: String?
    var status: String // pending | generating | complete | failed
    var familyDatesJSON: Data? // [FamilyDate] encoded as JSON
    var createdAt: Date
    var updatedAt: Date

    var project: CalendarProjectModel?

    init(id: String, projectID: String, month: Int) {
        self.id = id
        self.projectID = projectID
        self.month = month
        self.status = "pending"
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
