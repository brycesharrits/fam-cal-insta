import SwiftUI

struct MagicalLoadingView: View {
    let viewModel: BuildDraftViewModel
    let onComplete: () -> Void

    @State private var pulseOpacity: Double = 0.5

    private let monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

    var body: some View {
        ZStack {
            // Pulsing brand gradient background
            LinearGradient(
                colors: viewModel.theme.gradientColors.map { $0.opacity(pulseOpacity) } + [Color.brandBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulseOpacity)

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Creating your calendar…")
                        .font(.brandTitle)

                    Text("\(viewModel.completedCount) of 12 months ready")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .animation(.default, value: viewModel.completedCount)
                }

                // 3x4 month grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(1...12, id: \.self) { month in
                        MonthGenerationTile(
                            monthName: monthNames[month - 1],
                            state: viewModel.monthStates[month] ?? .pending,
                            referencePhoto: viewModel.referencePhotos[month]
                        )
                    }
                }
                .padding(.horizontal, 20)

                if viewModel.isComplete {
                    Button {
                        onComplete()
                    } label: {
                        Label("View Your Calendar", systemImage: "arrow.right")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(BrandPrimaryButtonStyle())
                    .padding(.horizontal, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            pulseOpacity = 0.9
        }
    }
}

struct MonthGenerationTile: View {
    let monthName: String
    let state: MonthGenerationState
    let referencePhoto: PhotoAsset?

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.systemGray6))

            switch state {
            case .pending:
                Text(monthName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

            case .uploading:
                VStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(monthName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

            case .generating:
                // Shimmer effect
                ZStack {
                    Color(.systemGray5)
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.4), .clear],
                        startPoint: UnitPoint(x: shimmerOffset, y: 0),
                        endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 1)
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = 1.5
                    }
                }

                VStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(monthName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

            case .complete(let imageURL):
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .overlay(alignment: .bottomLeading) {
                    Text(monthName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(4)
                }

            case .failed:
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(monthName)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(height: 70)
        .animation(.spring(response: 0.5), value: state)
    }
}
