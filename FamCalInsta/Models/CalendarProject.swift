import Foundation
import SwiftData

@Model
class CalendarProjectModel {
    @Attribute(.unique) var id: String
    var userID: String
    var name: String
    var year: Int
    var theme: String
    var status: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var months: [CalendarMonthModel]

    init(id: String, userID: String, name: String, year: Int, theme: String) {
        self.id = id
        self.userID = userID
        self.name = name
        self.year = year
        self.theme = theme
        self.status = "draft"
        self.createdAt = Date()
        self.updatedAt = Date()
        self.months = []
    }
}
