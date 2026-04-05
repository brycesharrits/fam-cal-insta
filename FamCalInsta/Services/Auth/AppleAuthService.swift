import Foundation
import AuthenticationServices

@Observable
class AppleAuthService: NSObject, AuthService, ASAuthorizationControllerDelegate {
    private(set) var isAuthenticated: Bool = false
    private(set) var currentUser: UserModel?
    private let apiClient: APIClient
    private var authContinuation: CheckedContinuation<UserModel, Error>?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        super.init()
        restoreSession()
    }

    func signInWithApple() async throws -> UserModel {
        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    func signOut() async throws {
        await apiClient.clearToken()
        UserDefaults.standard.removeObject(forKey: "jwt_token")
        UserDefaults.standard.removeObject(forKey: "current_user")
        isAuthenticated = false
        currentUser = nil
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              let authCodeData = credential.authorizationCode,
              let authCode = String(data: authCodeData, encoding: .utf8) else {
            authContinuation?.resume(throwing: APIError.unauthorized)
            authContinuation = nil
            return
        }

        Task {
            do {
                let response: AuthResponse = try await apiClient.request(
                    .appleAuth,
                    body: AppleAuthRequest(identityToken: identityToken, authorizationCode: authCode)
                )
                await apiClient.setToken(response.token)
                persistSession(token: response.token, user: response.user)

                let user = UserModel(
                    id: response.user.id,
                    email: response.user.email,
                    tokenBalance: response.user.tokenBalance
                )
                self.currentUser = user
                self.isAuthenticated = true
                authContinuation?.resume(returning: user)
            } catch {
                authContinuation?.resume(throwing: error)
            }
            authContinuation = nil
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        authContinuation?.resume(throwing: error)
        authContinuation = nil
    }

    // MARK: - Session persistence

    private func persistSession(token: String, user: UserResponse) {
        UserDefaults.standard.set(token, forKey: "jwt_token")
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "current_user")
        }
    }

    private func restoreSession() {
        guard let token = UserDefaults.standard.string(forKey: "jwt_token"),
              let data = UserDefaults.standard.data(forKey: "current_user"),
              let userResponse = try? JSONDecoder().decode(UserResponse.self, from: data) else {
            return
        }
        Task { await apiClient.setToken(token) }
        currentUser = UserModel(id: userResponse.id, email: userResponse.email, tokenBalance: userResponse.tokenBalance)
        isAuthenticated = true
    }
}
