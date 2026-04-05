import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services

    @State private var viewModel: OnboardingViewModel

    init() {
        _viewModel = State(wrappedValue: OnboardingViewModel())
    }

    var body: some View {
        VStack {
            switch viewModel.step {
            case .photoPermission:
                PhotoPermissionView(onGranted: { viewModel.step = .signIn })
            case .signIn:
                SignInView(viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.signedInUser) { _, user in
            guard let user else { return }
            appState.currentUser = user
            appState.tokenBalance = user.tokenBalance
            appState.authState = .authenticated
        }
    }
}
