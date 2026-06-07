import Foundation
import Photos
import UIKit

class PHPhotoLibraryService: PhotoLibraryService {
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func fetchAllPhotos() async throws -> [PhotoAsset] {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw APIError.unauthorized
        }

        return await Task.detached(priority: .userInitiated) {
            let calendar = Calendar.current
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(
                format: "mediaType == %d", PHAssetMediaType.image.rawValue
            )
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let assets = PHAsset.fetchAssets(with: fetchOptions)
            var result: [PhotoAsset] = []
            result.reserveCapacity(assets.count)
            assets.enumerateObjects { asset, _, _ in
                let month = asset.creationDate.map { calendar.component(.month, from: $0) }
                result.append(PhotoAsset(
                    id: asset.localIdentifier,
                    creationDate: asset.creationDate,
                    thumbnailImage: nil,
                    month: month
                ))
            }
            return result
        }.value
    }

    func fetchPhotos(inAlbum localIdentifier: String) async throws -> [PhotoAsset] {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw APIError.unauthorized
        }

        return await Task.detached(priority: .userInitiated) {
            let collections = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [localIdentifier], options: nil
            )
            guard let collection = collections.firstObject else { return [] }

            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            var result: [PhotoAsset] = []
            let calendar = Calendar.current
            assets.enumerateObjects { asset, _, _ in
                let month = asset.creationDate.map { calendar.component(.month, from: $0) }
                result.append(PhotoAsset(
                    id: asset.localIdentifier,
                    creationDate: asset.creationDate,
                    thumbnailImage: nil,
                    month: month
                ))
            }
            return result
        }.value
    }

    func fetchThumbnail(localIdentifier: String, size: CGSize) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            guard let asset = result.firstObject else {
                continuation.resume(throwing: APIError.noData)
                return
            }

            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: APIError.noData)
                }
            }
        }
    }

    func exportAssetForUpload(localIdentifier: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            guard let asset = result.firstObject else {
                continuation.resume(throwing: APIError.noData)
                return
            }

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            // Export at a reasonable size for upload — full resolution is too large
            let targetSize = CGSize(width: 1200, height: 1200)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                if let image, let data = image.jpegData(compressionQuality: 0.85) {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: APIError.noData)
                }
            }
        }
    }
}
