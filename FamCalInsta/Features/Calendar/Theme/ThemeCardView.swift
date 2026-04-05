import SwiftUI

struct ThemeCardView: View {
    let theme: Theme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Preview gradient (placeholder until real preview images exist)
                LinearGradient(colors: theme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 100)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(theme.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(12)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 3)
            }
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.brandPrimary)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
