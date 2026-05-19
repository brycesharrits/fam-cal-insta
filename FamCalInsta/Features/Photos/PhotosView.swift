import SwiftUI
import PhotosUI
import Photos

struct PhotosView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel = PhotosViewModel()
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.authorizationStatus {
                case .authorized, .limited:
                    authorizedBody
                case .denied, .restricted:
                    deniedBody
                default:
                    permissionPromptBody
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: 20,
                        matching: .images
                    ) {
                        Label("Add Photos", systemImage: "plus")
                    }
                }
            }
        }
        .task {
            viewModel.checkAuthorization()
            if viewModel.authorizationStatus == .authorized || viewModel.authorizationStatus == .limited {
                await viewModel.loadAlbums()
            }
        }
    }

    // MARK: - Authorized state

    private var authorizedBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if viewModel.isLoadingAlbums {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    albumsSection
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
        }
        .background(Color.brandBackground.ignoresSafeArea())
    }

    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Albums")
                .font(.brandHeadline)
                .padding(.horizontal, 20)

            if viewModel.albums.isEmpty {
                Text("No albums found.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 16
                ) {
                    ForEach(viewModel.albums) { album in
                        AlbumTileView(
                            album: album,
                            photoService: services.photoLibraryService
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Permission prompt

    private var permissionPromptBody: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary)

            VStack(spacing: 8) {
                Text("Let us browse your albums")
                    .font(.brandTitle)
                    .multilineTextAlignment(.center)
                Text("Grant access so you can pick photos and albums as source material for your creations.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Allow Photo Access") {
                Task { await viewModel.requestAuthorization() }
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(Color.brandBackground.ignoresSafeArea())
    }

    // MARK: - Denied state

    private var deniedBody: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Photo access is off")
                    .font(.brandTitle)
                Text("Enable it in Settings to browse your albums.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(Color.brandBackground.ignoresSafeArea())
    }
}

// MARK: - Album tile

struct AlbumTileView: View {
    let album: PhotoAlbum
    let photoService: any PhotoLibraryService

    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.brandPrimary.opacity(0.1))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundStyle(Color.brandPrimary.opacity(0.5))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(album.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Text("\(album.photoCount) photos")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .task {
            guard let id = album.thumbnailID else { return }
            thumbnail = try? await photoService.fetchThumbnail(
                localIdentifier: id,
                size: CGSize(width: 200, height: 200)
            )
        }
    }
}
