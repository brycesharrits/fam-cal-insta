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
    var layoutShuffleSeed: Int = 0
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var months: [CalendarMonthModel]

    init(id: String, userID: String, name: String, year: Int, theme: String, layoutShuffleSeed: Int = Int.random(in: Int.min...Int.max)) {
        self.id = id
        self.userID = userID
        self.name = name
        self.year = year
        self.theme = theme
        self.status = "draft"
        self.layoutShuffleSeed = layoutShuffleSeed
        self.createdAt = Date()
        self.updatedAt = Date()
        self.months = []
    }
}
