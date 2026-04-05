import Foundation
import SwiftUI

struct Theme: Identifiable, Hashable {
    let id: String
    let displayName: String
    let description: String
    let previewImageName: String? // asset catalog name
    let gradientColors: [Color]

    static let catalog: [Theme] = [
        Theme(
            id: "goofy_holiday",
            displayName: "Goofy Holiday",
            description: "Playful and festive, with a whimsical illustrated style",
            previewImageName: nil,
            gradientColors: [.red, .green]
        ),
        Theme(
            id: "watercolor",
            displayName: "Watercolor",
            description: "Soft, delicate brushstrokes with a dreamy pastel palette",
            previewImageName: nil,
            gradientColors: [.blue, .purple]
        ),
        Theme(
            id: "vintage_film",
            displayName: "Vintage Film",
            description: "Warm grain and nostalgic tones, like a 1970s family album",
            previewImageName: nil,
            gradientColors: [.orange, .brown]
        ),
        Theme(
            id: "modern_minimal",
            displayName: "Modern Minimal",
            description: "Clean lines and bold colors with a Scandinavian design influence",
            previewImageName: nil,
            gradientColors: [.gray, .black]
        ),
        Theme(
            id: "cozy_illustrated",
            displayName: "Cozy Illustrated",
            description: "Warm, hand-drawn scenes that feel intimate and heartwarming",
            previewImageName: nil,
            gradientColors: [.orange, .yellow]
        ),
        Theme(
            id: "nature_botanical",
            displayName: "Nature & Botanical",
            description: "Elegant botanical illustrations with seasonal flora and fauna",
            previewImageName: nil,
            gradientColors: [.green, .mint]
        ),
    ]
}
