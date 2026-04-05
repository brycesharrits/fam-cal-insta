import Foundation
import Observation

@Observable
class ThemeSelectionViewModel {
    var selectedTheme: Theme? = nil
    var isCreating = false
    var errorMessage: String? = nil
}
