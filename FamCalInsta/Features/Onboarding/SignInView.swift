import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(ServiceContainer.self) private var services
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("Let's get started")
                    .font(.brandTitle)

                Text("Sign in to save your calendars and purchases across devices.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
            }

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { _ in
                // Handled by AppleAuthService delegate
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .cornerRadius(12)
            .padding(.horizontal, 32)
            .overlay {
                // Overlay a tap handler that calls our service
                Button("") {
                    Task { await signIn() }
                }
                .opacity(0.01) // Invisible — real button above handles UI, this triggers our service
            }

            #if DEBUG
            Button("Continue with dev account") {
                Task { await signInAsDev() }
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
            #endif
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
    }

    private func signIn() async {
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        do {
            let user = try await services.authService.signInWithApple()
            viewModel.signedInUser = user
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        viewModel.isLoading = false
    }

    private func signInAsDev() async {
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        do {
            let user = try await services.authService.signInAsDevUser()
            viewModel.signedInUser = user
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        viewModel.isLoading = false
    }
}
