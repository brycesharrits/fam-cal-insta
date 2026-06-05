import SwiftUI
import Photos
import UIKit

struct GeneratedImageView: View {
    let imageURL: URL?
    var metadata: SavedCreationMetadata = SavedCreationMetadata()
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 0
    var menuPlacement: Alignment = .topTrailing

    @Environment(ServiceContainer.self) private var services
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var toastMessage: String?
    @State private var shareItem: ShareItem?

    var body: some View {
        ZStack(alignment: menuPlacement) {
            imageBody
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            if imageURL != nil {
                menuButton
                    .padding(8)
            }

            if let toastMessage {
                toastView(toastMessage)
            }
        }
        .task(id: imageURL) {
            await loadImage()
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.image])
        }
    }

    @ViewBuilder
    private var imageBody: some View {
        if let loadedImage {
            Image(uiImage: loadedImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if isLoading {
            Color(.systemGray6)
                .overlay { ProgressView() }
        } else {
            Color(.systemGray6)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.tertiary)
                }
        }
    }

    private var menuButton: some View {
        Menu {
            Button {
                Task { await saveToLibrary() }
            } label: {
                Label("Save to Library", systemImage: "square.and.arrow.down")
            }

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
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.black.opacity(0.45), in: Circle())
        }
    }

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 44)
            .padding(.trailing, 8)
            .transition(.opacity)
    }

    // MARK: - Actions

    private func loadImage() async {
        guard let imageURL else {
            loadedImage = nil
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            if let image = UIImage(data: data) {
                loadedImage = image
            }
        } catch {
            // Leave placeholder visible
        }
    }

    private func saveToLibrary() async {
        guard let imageURL else { return }
        do {
            _ = try await services.savedCreationsService.save(imageURL: imageURL, metadata: metadata)
            await showToast("Saved")
        } catch {
            await showToast("Save failed")
        }
    }

    private func saveToCameraRoll() async {
        guard let image = loadedImage else { return }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            await showToast("Photos access denied")
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            await showToast("Saved to Photos")
        } catch {
            await showToast("Save failed")
        }
    }

    private func share() {
        guard let image = loadedImage else { return }
        shareItem = ShareItem(image: image)
    }

    @MainActor
    private func showToast(_ message: String) async {
        withAnimation { toastMessage = message }
        try? await Task.sleep(for: .seconds(1.6))
        withAnimation { toastMessage = nil }
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
