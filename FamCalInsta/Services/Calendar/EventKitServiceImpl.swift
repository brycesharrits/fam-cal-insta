import Foundation
import EventKit

class EventKitServiceImpl: EventKitService {
    private let store = EKEventStore()

    func requestContactsAccess() async throws -> Bool {
        // Contacts birthdays come through EventKit's birthday calendar
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .event) { granted, error in
                    if let error { continuation.resume(throwing: error); return }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func requestCalendarAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .event) { granted, error in
                    if let error { continuation.resume(throwing: error); return }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func fetchBirthdays(for year: Int) async throws -> [FamilyDate] {
        let calendars = store.calendars(for: .event).filter { $0.type == .birthday }
        return try await fetchCalendarEvents(for: year, calendarIdentifiers: calendars.map { $0.calendarIdentifier })
    }

    func fetchCalendarEvents(for year: Int, calendarIdentifiers: [String]) async throws -> [FamilyDate] {
        let allCalendars = store.calendars(for: .event)
        let selectedCalendars = allCalendars.filter { calendarIdentifiers.contains($0.calendarIdentifier) }

        var startComps = DateComponents()
        startComps.year = year
        startComps.month = 1
        startComps.day = 1

        var endComps = DateComponents()
        endComps.year = year + 1
        endComps.month = 1
        endComps.day = 1

        let cal = Calendar.current
        guard let startDate = cal.date(from: startComps),
              let endDate = cal.date(from: endComps) else { return [] }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: selectedCalendars)
        let events = store.events(matching: predicate)

        return events.compactMap { event in
            guard let startDate = event.startDate else { return nil }
            let components = cal.dateComponents([.month, .day], from: startDate)
            return FamilyDate(
                id: UUID(),
                title: event.title ?? "Event",
                date: components,
                isAnnual: event.calendar?.type == .birthday,
                source: event.calendar?.type == .birthday ? .contacts : .calendar,
                calendarIdentifier: event.calendar?.calendarIdentifier
            )
        }
    }

    func fetchAvailableCalendars() async throws -> [EKCalendar] {
        return store.calendars(for: .event).filter { $0.type != .birthday }
    }
}
