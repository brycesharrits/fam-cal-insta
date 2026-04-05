import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.authState {
            case .unknown:
                SplashView()
            case .unauthenticated:
                OnboardingView()
            case .authenticated:
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.authState)
    }
}
