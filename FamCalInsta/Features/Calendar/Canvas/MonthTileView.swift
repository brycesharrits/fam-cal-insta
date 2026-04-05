import SwiftUI

struct MonthTileView: View {
    let monthName: String
    let month: MonthResponse
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let imageURL = month.generatedImageUrl, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color(.systemGray5)
                        }
                    } else {
                        generatingPlaceholder
                    }
                }
                .frame(height: 130)
                .clipped()

                // Month label overlay
                Text(monthName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(8)

                // Status indicator
                if month.status == "generating" || month.status == "pending" {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .tint(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
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
