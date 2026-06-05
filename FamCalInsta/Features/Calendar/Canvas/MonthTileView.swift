import SwiftUI

struct MonthTileView: View {
    let monthName: String
    let month: MonthResponse
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            imageArea

            // Month label overlay
            Text(monthName)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(8)
                .allowsHitTesting(false)

            // Status indicator
            if month.status == "generating" || month.status == "pending" {
                Color.black.opacity(0.3)
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    @ViewBuilder
    private var imageArea: some View {
        if let imageURL = month.generatedImageUrl, let url = URL(string: imageURL) {
            GeneratedImageView(
                imageURL: url,
                metadata: SavedCreationMetadata(
                    prompt: month.prompt,
                    monthLabel: monthName
                ),
                contentMode: .fill
            )
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
        } else {
            generatingPlaceholder
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
        }
    }

    private var generatingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(.systemGray6))
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    Text(monthName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
    }
}
