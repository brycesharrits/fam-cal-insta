import Foundation
import Observation

@Observable
class AppState {
    var authState: AuthState = .unknown
    var currentUser: UserModel?
    var tokenBalance: Int = 0

    enum AuthState {
        case unknown
        case unauthenticated
        case authenticated
    }
}
