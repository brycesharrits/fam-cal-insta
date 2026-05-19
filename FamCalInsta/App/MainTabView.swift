import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            Tab("Create", systemImage: "sparkles") {
                HomeView()
            }

            Tab("Photos", systemImage: "photo.stack") {
                PhotosView()
            }

            Tab("Projects", systemImage: "folder") {
                ProjectsView()
            }
        }
        .tint(Color.brandPrimary)
    }
}
