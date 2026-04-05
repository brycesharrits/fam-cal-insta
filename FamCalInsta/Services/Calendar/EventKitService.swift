import Foundation
import EventKit

enum FamilyDateSource {
    case contacts
    case calendar
    case manual
}

struct FamilyDate: Identifiable {
    let id: UUID
    var title: String
    var date: DateComponents
    var isAnnual: Bool
    var source: FamilyDateSource
    var calendarIdentifier: String?
}

protocol EventKitService: AnyObject {
    func requestContactsAccess() async throws -> Bool
    func requestCalendarAccess() async throws -> Bool
    func fetchBirthdays(for year: Int) async throws -> [FamilyDate]
    func fetchCalendarEvents(for year: Int, calendarIdentifiers: [String]) async throws -> [FamilyDate]
    func fetchAvailableCalendars() async throws -> [EKCalendar]
}
