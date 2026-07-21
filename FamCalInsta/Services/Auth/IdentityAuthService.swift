import Foundation
import UIKit
import AuthenticationServices
import GoogleSignIn

@Observable
class IdentityAuthService: NSObject, AuthService, ASAuthorizationControllerDelegate {
    private(set) var isAuthenticated: Bool = false
    private(set) var currentUser: UserModel?
    private let apiClient: APIClient
    private var authContinuation: CheckedContinuation<UserModel, Error>?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        super.init()
        restoreSession()
    }

    // MARK: - Apple

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

    // MARK: - Google

    func signInWithGoogle() async throws -> UserModel {
        guard let presentingVC = Self.topPresentingViewController() else {
            throw APIError.unauthorized
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw APIError.unauthorized
        }

        let response: AuthResponse = try await apiClient.request(
            .googleAuth,
            body: OIDCSignInRequest(idToken: idToken)
        )
        return await completeSignIn(with: response)
    }

    // MARK: - Sign out

    func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
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
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            authContinuation?.resume(throwing: APIError.unauthorized)
            authContinuation = nil
            return
        }

        Task {
            do {
                let response: AuthResponse = try await apiClient.request(
                    .appleAuth,
                    body: OIDCSignInRequest(idToken: identityToken)
                )
                let user = await completeSignIn(with: response)
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

    private func completeSignIn(with response: AuthResponse) async -> UserModel {
        await apiClient.setToken(response.token)
        persistSession(token: response.token, user: response.user)

        let user = UserModel(
            id: response.user.id,
            email: response.user.email,
            tokenBalance: response.user.tokenBalance
        )
        currentUser = user
        isAuthenticated = true
        return user
    }

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

    // MARK: - Presenting VC helper

    private static func topPresentingViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where window.isKeyWindow {
                var vc = window.rootViewController
                while let presented = vc?.presentedViewController {
                    vc = presented
                }
                return vc
            }
        }
        return nil
    }
}
