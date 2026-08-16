import Foundation
import Observation
import SwiftUI

enum MediumStyle {
    case filled    // brandPrimary background, white text — default hero look
    case outlined  // system background, brandPrimary stroke + text — secondary emphasis
}

struct Medium: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let iconName: String
    let isEnabled: Bool
    var style: MediumStyle = .filled
}

@Observable
class HomeViewModel {
    var lockedMediumTapped: Medium? = nil
    var recentProjects: [ProjectResponse] = []

    let mediums: [Medium] = [
        Medium(id: "creations", displayName: "Creations", description: "Your AI-generated image library", iconName: "sparkles", isEnabled: true, style: .outlined),
        Medium(id: "calendar", displayName: "Family Calendar", description: "12 months of AI-generated memories", iconName: "calendar", isEnabled: true),
        Medium(id: "photobook", displayName: "Photo Book", description: "Your year in a beautiful book", iconName: "book.closed", isEnabled: false),
        Medium(id: "cards", displayName: "Holiday Cards", description: "Share the magic with family", iconName: "envelope.open.fill", isEnabled: false),
        Medium(id: "scrapbook", displayName: "School Year", description: "Capture every milestone", iconName: "pencil.and.ruler.fill", isEnabled: false),
    ]

    /// Loads up to 2 most-recent projects for the home screen quick-access row.
    /// Backend already sorts by created_at DESC.
    @MainActor
    func loadRecentProjects(apiClient: APIClient) async {
        do {
            let all: [ProjectResponse] = try await apiClient.request(.listProjects)
            recentProjects = Array(all.prefix(2))
        } catch {
            recentProjects = []
        }
    }
}
