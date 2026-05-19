import Foundation
import Observation
import SwiftUI

struct Medium: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let iconName: String
    let isEnabled: Bool
    let isHero: Bool // hero brick is larger in masonry
}

@Observable
class HomeViewModel {
    var lockedMediumTapped: Medium? = nil

    let mediums: [Medium] = [
        Medium(id: "calendar", displayName: "Family Calendar", description: "12 months of AI-generated memories", iconName: "calendar", isEnabled: true, isHero: true),
        Medium(id: "photobook", displayName: "Photo Book", description: "Your year in a beautiful book", iconName: "book.closed", isEnabled: false, isHero: false),
        Medium(id: "cards", displayName: "Holiday Cards", description: "Share the magic with family", iconName: "envelope.open.fill", isEnabled: false, isHero: false),
        Medium(id: "scrapbook", displayName: "School Year", description: "Capture every milestone", iconName: "pencil.and.ruler.fill", isEnabled: false, isHero: false),
    ]
}
