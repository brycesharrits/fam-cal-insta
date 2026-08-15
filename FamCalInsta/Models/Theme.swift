import Foundation
import SwiftUI

struct Theme: Identifiable, Hashable {
    let id: String
    let displayName: String
    let description: String
    let previewImageName: String? // asset catalog name
    let gradientColors: [Color]
    let customConfig: CustomThemeConfig?

    var isCustom: Bool { customConfig != nil }

    init(
        id: String,
        displayName: String,
        description: String,
        previewImageName: String? = nil,
        gradientColors: [Color],
        customConfig: CustomThemeConfig? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.previewImageName = previewImageName
        self.gradientColors = gradientColors
        self.customConfig = customConfig
    }

    static let catalog: [Theme] = [
        Theme(
            id: "holiday",
            displayName: "Holiday",
            description: "Each month centers on its holiday — New Year, Valentine's, Halloween, Christmas, and more",
            gradientColors: [.red, .green]
        ),
        Theme(
            id: "clean",
            displayName: "Clean & Simple",
            description: "Minimal black-and-white photography with quiet, uncluttered composition",
            gradientColors: [.black, .gray]
        ),
        Theme(
            id: "vintage",
            displayName: "Vintage Photo Album",
            description: "Warm sepia and film grain — like flipping through your grandmother's photo album",
            gradientColors: [.brown, .orange]
        ),
    ]

    /// Sentinel value for the "Custom" card in ThemeSelection. Tapping it routes
    /// to the config screen rather than straight into LayoutPreview.
    static let customPlaceholder = Theme(
        id: "custom_placeholder",
        displayName: "Custom",
        description: "Design your own — pick your colors and describe the vibe",
        gradientColors: [.purple, .pink, .orange]
    )

    /// Used when the user continues without picking a theme. Backend receives
    /// theme="none"; prompt builder falls back to photo-only styling.
    static let noTheme = Theme(
        id: "none",
        displayName: "No theme",
        description: "Just your photos, no added styling",
        gradientColors: [.gray, Color(.systemGray4)]
    )
}

struct CustomThemeConfig: Hashable, Codable {
    var name: String
    var primaryHex: String
    var secondaryHex: String
    var tertiaryHex: String
    var styleDescriptor: String
}
