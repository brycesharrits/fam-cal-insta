import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct FamCalInstaApp: App {
    @State private var appState = AppState()
    @State private var serviceContainer: ServiceContainer

    init() {
        let container = ServiceContainer(modelContext: PersistenceController.shared.container.mainContext)
        _serviceContainer = State(wrappedValue: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(serviceContainer)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    GIDSignIn.sharedInstance.restorePreviousSignIn()
                }
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
