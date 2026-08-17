import SwiftUI

struct MonthTileView: View {
    let monthName: String
    let month: MonthResponse
    let layout: MonthLayout
    let userSlotFilledCount: Int
    let onTap: () -> Void

    private var aiFilled: Bool {
        month.generatedImageUrl != nil
    }

    private var totalFilled: Int {
        (aiFilled ? 1 : 0) + min(userSlotFilledCount, layout.userSlotCount)
    }

    private var isComplete: Bool {
        totalFilled >= layout.slotCount
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            imageArea

            Text(monthName)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(8)
                .allowsHitTesting(false)

            if !isComplete {
                Color.black.opacity(0.35)
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                progressDots
                    .padding(.bottom, 6)
                    .padding(.trailing, 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .allowsHitTesting(false)
            }

            if month.status == "generating" {
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
                contentMode: .fill
            )
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
        } else {
            emptyPlaceholder
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
        }
    }

    private var emptyPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(.systemGray6))
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor.opacity(0.7))
                    Text("Tap to fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
    }

    private var progressDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<layout.slotCount, id: \.self) { i in
                Circle()
                    .fill(i < totalFilled ? Color.white : Color.white.opacity(0.35))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
