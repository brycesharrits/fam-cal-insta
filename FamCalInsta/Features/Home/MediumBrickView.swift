import SwiftUI

struct MediumBrickView: View {
    let medium: Medium
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                background

                VStack(alignment: .leading, spacing: 6) {
                    Spacer()
                    Image(systemName: medium.iconName)
                        .font(.title2)
                        .foregroundStyle(foregroundColor)

                    Text(medium.displayName)
                        .font(.brandHeadline)
                        .foregroundStyle(foregroundColor)

                    if medium.isEnabled {
                        Text(medium.description)
                            .font(.caption)
                            .foregroundStyle(descriptionColor)
                    } else {
                        Label("Coming soon", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .frame(height: 140)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        if !medium.isEnabled {
            shape.fill(Color(.systemGray5))
        } else {
            switch medium.style {
            case .filled:
                shape.fill(Color.brandPrimary)
            case .outlined:
                shape
                    .fill(Color(.systemBackground))
                    .overlay(shape.stroke(Color.brandPrimary, lineWidth: 2))
            }
        }
    }

    private var foregroundColor: Color {
        guard medium.isEnabled else { return .secondary }
        switch medium.style {
        case .filled: return .white
        case .outlined: return .brandPrimary
        }
    }

    private var descriptionColor: Color {
        switch medium.style {
        case .filled: return .white.opacity(0.85)
        case .outlined: return .brandPrimary.opacity(0.75)
        }
    }
}
