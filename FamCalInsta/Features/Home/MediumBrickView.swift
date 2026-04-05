import SwiftUI

struct MediumBrickView: View {
    let medium: Medium
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(medium.isEnabled ? Color.brandPrimary : Color(.systemGray5))

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()
                    Image(systemName: medium.iconName)
                        .font(.title2)
                        .foregroundStyle(medium.isEnabled ? .white : .secondary)

                    Text(medium.displayName)
                        .font(.brandHeadline)
                        .foregroundStyle(medium.isEnabled ? .white : .secondary)

                    if medium.isEnabled {
                        Text(medium.description)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    } else {
                        Label("Coming soon", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .frame(height: medium.isHero ? 200 : 140)
        }
        .buttonStyle(.plain)
    }
}
