import Foundation
import Photos
import UIKit

struct PhotoAsset: Identifiable {
    let id: String // PHAsset localIdentifier
    let creationDate: Date?
    let thumbnailImage: UIImage?
    let month: Int? // 1-12, derived from creationDate
}

protocol PhotoLibraryService: AnyObject {
    var authorizationStatus: PHAuthorizationStatus { get }
    func requestAuthorization() async -> PHAuthorizationStatus
    /// Returns every accessible image asset, newest first.
    func fetchAllPhotos() async throws -> [PhotoAsset]
    /// Returns all image assets in an album, newest first.
    func fetchPhotos(inAlbum localIdentifier: String) async throws -> [PhotoAsset]
    func fetchThumbnail(localIdentifier: String, size: CGSize) async throws -> UIImage
    func exportAssetForUpload(localIdentifier: String) async throws -> Data
}
