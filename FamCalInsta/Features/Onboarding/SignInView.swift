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

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    // Handled by IdentityAuthService delegate
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(12)
                .overlay {
                    Button("") {
                        Task { await signIn(with: .apple) }
                    }
                    .opacity(0.01)
                }

                Button {
                    Task { await signIn(with: .google) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                        Text("Continue with Google")
                            .font(.body.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.primary)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)

            #if DEBUG
            Button("Continue with dev account") {
                Task { await signInAsDev() }
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
            #else
            Spacer().frame(height: 32)
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

    private enum Provider { case apple, google }

    private func signIn(with provider: Provider) async {
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        do {
            let user: UserModel
            switch provider {
            case .apple:  user = try await services.authService.signInWithApple()
            case .google: user = try await services.authService.signInWithGoogle()
            }
            viewModel.signedInUser = user
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        viewModel.isLoading = false
    }

    #if DEBUG
    private func signInAsDev() async {
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        do {
            viewModel.signedInUser = try await services.authService.signInAsDevUser()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        viewModel.isLoading = false
    }
    #endif
}
