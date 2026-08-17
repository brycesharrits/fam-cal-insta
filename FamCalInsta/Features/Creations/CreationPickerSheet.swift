import SwiftUI

/// Presents the Creations library in pick mode — tapping a creation calls
/// onPick with the selection instead of pushing to detail. Reuses
/// CreationsLibraryViewModel so pagination + fetch logic is shared.
struct CreationPickerSheet: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreationsLibraryViewModel?

    let onPick: (CreationResponse) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    content(vm: vm)
                } else {
                    ProgressView()
                        .onAppear {
                            viewModel = CreationsLibraryViewModel(service: services.creationsService)
                            Task { await viewModel?.loadInitial() }
                        }
                }
            }
            .navigationTitle("Pick from Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .background(Color.brandBackground.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func content(vm: CreationsLibraryViewModel) -> some View {
        if vm.creations.isEmpty && !vm.isLoading {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(vm.creations) { creation in
                        Button {
                            onPick(creation)
                            dismiss()
                        } label: {
                            PickerTile(creation: creation)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .refreshable { await vm.refresh() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.brandPrimary.opacity(0.6))
            Text("No creations yet")
                .font(.headline)
            Text("Generate one from the Creations screen first.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PickerTile: View {
    let creation: CreationResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: URL(string: creation.thumbnailUrl ?? creation.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.gray.opacity(0.15).overlay(
                        Image(systemName: "photo").foregroundStyle(.secondary)
                    )
                default:
                    Color.gray.opacity(0.15).overlay(ProgressView())
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(creation.prompt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
