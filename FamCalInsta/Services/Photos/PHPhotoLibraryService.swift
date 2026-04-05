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

    func fetchPhotosByMonth(year: Int) async throws -> [Int: [PhotoAsset]] {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw APIError.unauthorized
        }

        return await Task.detached(priority: .userInitiated) {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current

            var result: [Int: [PhotoAsset]] = [:]

            for month in 1...12 {
                var startComponents = DateComponents()
                startComponents.year = year
                startComponents.month = month
                startComponents.day = 1
                guard let startDate = calendar.date(from: startComponents),
                      let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else { continue }

                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(
                    format: "creationDate >= %@ AND creationDate < %@ AND mediaType == %d",
                    startDate as NSDate, endDate as NSDate, PHAssetMediaType.image.rawValue
                )
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                fetchOptions.fetchLimit = 50

                let assets = PHAsset.fetchAssets(with: fetchOptions)
                var photoAssets: [PhotoAsset] = []

                assets.enumerateObjects { asset, _, _ in
                    photoAssets.append(PhotoAsset(
                        id: asset.localIdentifier,
                        creationDate: asset.creationDate,
                        thumbnailImage: nil, // loaded lazily
                        month: month
                    ))
                }

                result[month] = photoAssets
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
