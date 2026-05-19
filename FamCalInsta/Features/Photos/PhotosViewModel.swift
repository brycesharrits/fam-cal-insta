import Foundation
import Observation
import Photos
import PhotosUI

struct PhotoAlbum: Identifiable {
    let id: String // PHAssetCollection localIdentifier
    let title: String
    let photoCount: Int
    let thumbnailID: String? // localIdentifier of the cover photo
}

@Observable
class PhotosViewModel {
    var albums: [PhotoAlbum] = []
    var isLoadingAlbums = false
    var authorizationStatus: PHAuthorizationStatus = .notDetermined

    // Photos the user has starred/pinned for use in creations
    // Stored as localIdentifiers in UserDefaults
    var starredPhotoIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "starredPhotoIDs") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "starredPhotoIDs") }
    }

    func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async {
        authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        if authorizationStatus == .authorized || authorizationStatus == .limited {
            await loadAlbums()
        }
    }

    func loadAlbums() async {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else { return }
        isLoadingAlbums = true

        let loaded = await Task.detached(priority: .userInitiated) {
            var result: [PhotoAlbum] = []

            // Smart albums first (Recents, Favorites, etc.)
            let smartTypes: [PHAssetCollectionSubtype] = [
                .smartAlbumUserLibrary,
                .smartAlbumFavorites,
                .smartAlbumRecentlyAdded,
            ]
            for subtype in smartTypes {
                let collections = PHAssetCollection.fetchAssetCollections(
                    with: .smartAlbum, subtype: subtype, options: nil
                )
                collections.enumerateObjects { collection, _, _ in
                    let count = PHAsset.fetchAssets(in: collection, options: nil).count
                    guard count > 0 else { return }
                    let cover = PHAsset.fetchAssets(in: collection, options: nil).lastObject
                    result.append(PhotoAlbum(
                        id: collection.localIdentifier,
                        title: collection.localizedTitle ?? "Album",
                        photoCount: count,
                        thumbnailID: cover?.localIdentifier
                    ))
                }
            }

            // User-created albums
            let userAlbums = PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .albumRegular, options: nil
            )
            userAlbums.enumerateObjects { collection, _, _ in
                let count = PHAsset.fetchAssets(in: collection, options: nil).count
                guard count > 0 else { return }
                let cover = PHAsset.fetchAssets(in: collection, options: nil).lastObject
                result.append(PhotoAlbum(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "Album",
                    photoCount: count,
                    thumbnailID: cover?.localIdentifier
                ))
            }

            return result
        }.value

        isLoadingAlbums = false
        albums = loaded
    }

    func toggleStar(photoID: String) {
        var current = starredPhotoIDs
        if current.contains(photoID) {
            current.remove(photoID)
        } else {
            current.insert(photoID)
        }
        starredPhotoIDs = current
    }
}
