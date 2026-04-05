import SwiftData
import Foundation

@MainActor
class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            CalendarProjectModel.self,
            CalendarMonthModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController()
        return controller
    }()
}
