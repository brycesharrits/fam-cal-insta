import Foundation
import UIKit

/// Disk-backed cache for user-selected slot photos. Bypasses the Photos-permission
/// requirement of PHAsset lookup by owning the bytes ourselves. Files live under
/// Documents/ so they survive app relaunches; relative paths are what we store,
/// resolved to absolute URLs at read time.
enum UserPhotoCache {
    private static let rootFolderName = "user_photos"

    /// Persist JPEG data for a given slot; returns the stored relative path.
    /// Overwrites any existing file for the slot.
    @discardableResult
    static func save(_ data: Data, projectID: String, month: Int, slot: Int) throws -> String {
        try saveAt(relativePath: "\(rootFolderName)/\(projectID)/\(month)/\(slot).jpg", data: data)
    }

    /// Persist the AI reference photo for a month.
    @discardableResult
    static func saveReference(_ data: Data, projectID: String, month: Int) throws -> String {
        try saveAt(relativePath: referencePath(projectID: projectID, month: month), data: data)
    }

    private static func saveAt(relativePath: String, data: Data) throws -> String {
        let absoluteURL = documentsURL().appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: absoluteURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: absoluteURL, options: .atomic)
        return relativePath
    }

    static func loadImage(relativePath: String) -> UIImage? {
        let absoluteURL = documentsURL().appendingPathComponent(relativePath)
        return UIImage(contentsOfFile: absoluteURL.path)
    }

    static func exists(relativePath: String) -> Bool {
        let absoluteURL = documentsURL().appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: absoluteURL.path)
    }

    /// Best-effort delete; missing files are treated as success.
    static func remove(relativePath: String) {
        let absoluteURL = documentsURL().appendingPathComponent(relativePath)
        try? FileManager.default.removeItem(at: absoluteURL)
    }

    /// Deterministic relative path for the AI reference photo of a given month.
    static func referencePath(projectID: String, month: Int) -> String {
        "\(rootFolderName)/\(projectID)/\(month)/ref.jpg"
    }

    private static func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
