import Foundation
import Observation
import SwiftUI
import UIKit

@Observable
class CustomThemeConfigViewModel {
    var name: String = "My Theme"
    var primary: Color = .indigo
    var secondary: Color = .pink
    var tertiary: Color = .yellow
    var styleDescriptor: String = ""

    /// Builds a Theme value that carries the user's custom config through the flow.
    func makeTheme() -> Theme? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescriptor = styleDescriptor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedDescriptor.isEmpty else { return nil }

        let config = CustomThemeConfig(
            name: trimmedName,
            primaryHex: primary.toHex(),
            secondaryHex: secondary.toHex(),
            tertiaryHex: tertiary.toHex(),
            styleDescriptor: trimmedDescriptor
        )

        return Theme(
            id: "custom",
            displayName: trimmedName,
            description: trimmedDescriptor,
            gradientColors: [primary, secondary, tertiary],
            customConfig: config
        )
    }
}

private extension Color {
    /// Serialize to "#RRGGBB". Falls back to black on failure.
    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return "#000000" }
        return String(format: "#%02X%02X%02X",
                      Int(round(r * 255)),
                      Int(round(g * 255)),
                      Int(round(b * 255)))
    }
}
