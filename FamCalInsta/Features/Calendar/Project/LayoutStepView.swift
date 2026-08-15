import SwiftUI

/// Step 2 of the calendar pager. User shuffles until happy with the layout rhythm.
/// On Continue, PATCHes the seed to the backend (bumps progress_stage to ≥2).
struct LayoutStepView: View {
    @Bindable var hub: CalendarProjectHubViewModel
    let onCompleted: () -> Void

    @Environment(ServiceContainer.self) private var services

    private let monthAbbrev = ["Jan","Feb","Mar","Apr","May","Jun",
                               "Jul","Aug","Sep","Oct","Nov","Dec"]

    private var layouts: [MonthLayout] {
        MonthLayout.distribute(seed: hub.layoutSeed)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Layout rhythm")
                            .font(.brandTitle)
                        Text("We mix layouts across the year for visual variety. Shuffle if you want a different feel.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(Array(layouts.enumerated()), id: \.offset) { index, layout in
                            LayoutThumbnail(monthLabel: monthAbbrev[index], layout: layout)
                        }
                    }
                    .padding(.horizontal, 16)

                    if let error = hub.errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
            }

            HStack(spacing: 12) {
                Button {
                    hub.layoutSeed = Int.random(in: Int.min...Int.max)
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(hub.isBusy)

                Button {
                    Task { await confirm() }
                } label: {
                    if hub.isBusy {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .disabled(hub.isBusy)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.brandBackground.ignoresSafeArea())
    }

    private func confirm() async {
        let ok = await hub.confirmLayout(apiClient: services.apiClient)
        if ok { onCompleted() }
    }
}

private struct LayoutThumbnail: View {
    let monthLabel: String
    let layout: MonthLayout

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemGray6))

                LayoutSkeleton(layout: layout)
                    .padding(6)
            }
            .aspectRatio(1, contentMode: .fit)

            Text(monthLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LayoutSkeleton: View {
    let layout: MonthLayout

    var body: some View {
        switch layout {
        case .single:
            aiCell
        case .double:
            HStack(spacing: 3) {
                aiCell
                plainCell
            }
        case .grid:
            VStack(spacing: 3) {
                HStack(spacing: 3) { aiCell; plainCell }
                HStack(spacing: 3) { plainCell; plainCell }
            }
        }
    }

    private var aiCell: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.accentColor.opacity(0.35))
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            )
    }

    private var plainCell: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.3))
    }
}
