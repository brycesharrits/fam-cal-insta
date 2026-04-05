import SwiftUI
import SwiftData

@main
struct FamCalInstaApp: App {
    @State private var appState = AppState()
    @State private var serviceContainer: ServiceContainer

    init() {
        let container = ServiceContainer()
        _serviceContainer = State(wrappedValue: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(serviceContainer)
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
