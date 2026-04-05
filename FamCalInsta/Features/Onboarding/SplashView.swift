import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Color.brandPrimary)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("fam-cal-insta")
                    .font(.brandTitle)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            Task { await checkAuthAndTransition() }
        }
    }

    private func checkAuthAndTransition() async {
        // Brief brand moment
        try? await Task.sleep(for: .seconds(1.2))

        if services.authService.isAuthenticated {
            appState.authState = .authenticated
            if let user = services.authService.currentUser {
                appState.currentUser = user
                appState.tokenBalance = user.tokenBalance
            }
        } else {
            appState.authState = .unauthenticated
        }
    }
}
