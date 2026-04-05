import Foundation
import Observation

@Observable
class DatesLayerViewModel {
    var familyDates: [FamilyDate] = []
    var showManualEntry = false
    var showCalendarPicker = false
    var isLoading = false

    func importBirthdays(eventKitService: any EventKitService) async {
        isLoading = true
        do {
            _ = try await eventKitService.requestContactsAccess()
            let year = Calendar.current.component(.year, from: Date())
            let birthdays = try await eventKitService.fetchBirthdays(for: year)
            familyDates.append(contentsOf: birthdays.filter { new in
                !familyDates.contains(where: { $0.title == new.title })
            })
        } catch { }
        isLoading = false
    }
}
