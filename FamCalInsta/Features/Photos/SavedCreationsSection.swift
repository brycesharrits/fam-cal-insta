import SwiftUI
import Photos
import UIKit

struct SavedCreationsSection: View {
    @Environment(ServiceContainer.self) private var services
    @State private var creations: [SavedCreationModel] = []
    @State private var hasLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Creations")
                .font(.brandHeadline)
                .padding(.horizontal, 20)

            if !hasLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if creations.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(creations) { creation in
                            SavedCreationTileView(
                                creation: creation,
                                onDelete: { await reload() }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .task { await reload() }
    }

    private var emptyState: some View {
        Text("Tap the “…” on any generated image to save it here.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
    }

    private func reload() async {
        creations = await services.savedCreationsService.loadAll()
        hasLoaded = true
    }
}

private struct SavedCreationTileView: View {
    let creation: SavedCreationModel
    let onDelete: () async -> Void

    @Environment(ServiceContainer.self) private var services
    @State private var image: UIImage?
    @State private var shareItem: ShareItem?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            tileImage
                .frame(width: 130, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Menu {
                Button {
                    Task { await saveToCameraRoll() }
                } label: {
                    Label("Save to Photos", systemImage: "photo.badge.plus")
                }
                Button {
                    share()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    Task {
                        try? await services.savedCreationsService.delete(creation)
                        await onDelete()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .padding(6)
        }
        .task(id: creation.id) {
            image = services.savedCreationsService.loadImage(for: creation)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.image])
        }
    }

    @ViewBuilder
    private var tileImage: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color(.systemGray5)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.tertiary)
                }
        }
    }

    private func saveToCameraRoll() async {
        guard let image else { return }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return }
        try? await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    private func share() {
        guard let image else { return }
        shareItem = ShareItem(image: image)
    }
}

private struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
