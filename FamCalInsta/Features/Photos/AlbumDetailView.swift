import SwiftUI
import Photos

struct AlbumDetailView: View {
    let album: PhotoAlbum
    @Bindable var photosViewModel: PhotosViewModel
    @Environment(ServiceContainer.self) private var services

    @State private var photos: [PhotoAsset] = []
    @State private var isLoading = true

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
    ]

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if photos.isEmpty {
                Text("No photos in this album.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(photos) { photo in
                            PhotoCellView(
                                photo: photo,
                                isStarred: photosViewModel.starredPhotoIDs.contains(photo.id),
                                photoService: services.photoLibraryService
                            )
                            .onTapGesture {
                                photosViewModel.toggleStar(photoID: photo.id)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            photos = try await services.photoLibraryService.fetchPhotos(inAlbum: album.id)
        } catch {
            photos = []
        }
    }
}

private struct PhotoCellView: View {
    let photo: PhotoAsset
    let isStarred: Bool
    let photoService: any PhotoLibraryService

    @State private var thumbnail: UIImage?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.brandPrimary.opacity(0.08))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }

                if isStarred {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.brandPrimary, in: Circle())
                        .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .task {
            thumbnail = try? await photoService.fetchThumbnail(
                localIdentifier: photo.id,
                size: CGSize(width: 300, height: 300)
            )
        }
    }
}
