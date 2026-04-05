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
    /// Returns the best candidate photos grouped by month (1-12) for a given year.
    func fetchPhotosByMonth(year: Int) async throws -> [Int: [PhotoAsset]]
    func fetchThumbnail(localIdentifier: String, size: CGSize) async throws -> UIImage
    func exportAssetForUpload(localIdentifier: String) async throws -> Data
}
