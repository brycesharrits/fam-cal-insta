import Foundation

protocol AuthService: AnyObject {
    var isAuthenticated: Bool { get }
    var currentUser: UserModel? { get }
    func signInWithApple() async throws -> UserModel
    func signOut() async throws
}
