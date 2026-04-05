import Foundation
import Observation

@Observable
class OnboardingViewModel {
    enum Step { case photoPermission, signIn }

    var step: Step = .photoPermission
    var signedInUser: UserModel? = nil
    var isLoading = false
    var errorMessage: String? = nil
}
