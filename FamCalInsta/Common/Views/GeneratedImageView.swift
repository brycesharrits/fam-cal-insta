import SwiftUI
import UIKit

struct GeneratedImageView: View {
    let imageURL: URL?
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 0

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        imageBody
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .task(id: imageURL) {
                await loadImage()
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
}
