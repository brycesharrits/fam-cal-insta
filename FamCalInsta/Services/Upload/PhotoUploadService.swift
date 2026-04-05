import Foundation
import UIKit

class PhotoUploadService {
    private let apiClient: APIClient
    private let photoService: PHPhotoLibraryService

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.photoService = PHPhotoLibraryService()
    }

    /// Uploads a photo asset to S3 via a presigned URL and returns the S3 object key.
    func upload(localIdentifier: String, projectID: String, month: Int) async throws -> String {
        // Export the asset as JPEG data
        let imageData = try await photoService.exportAssetForUpload(localIdentifier: localIdentifier)

        // Get presigned URL from backend
        let presign: PresignResponse = try await apiClient.request(
            .presignUpload,
            body: PresignRequest(
                filename: "month_\(month).jpg",
                contentType: "image/jpeg",
                projectId: projectID,
                month: month
            )
        )

        // Upload directly to S3
        guard let uploadURL = URL(string: presign.uploadUrl) else {
            throw APIError.invalidURL
        }
        try await apiClient.upload(to: uploadURL, data: imageData, contentType: "image/jpeg")

        return presign.objectKey
    }

    /// Uploads all 12 months in parallel and returns a map of month → S3 object key.
    func uploadAll(
        selections: [(month: Int, localIdentifier: String)],
        projectID: String,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws -> [Int: String] {
        var results: [Int: String] = [:]
        var completed = 0

        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for selection in selections {
                group.addTask {
                    let key = try await self.upload(
                        localIdentifier: selection.localIdentifier,
                        projectID: projectID,
                        month: selection.month
                    )
                    return (selection.month, key)
                }
            }

            for try await (month, key) in group {
                results[month] = key
                completed += 1
                progressCallback?(completed, selections.count)
            }
        }

        return results
    }
}
