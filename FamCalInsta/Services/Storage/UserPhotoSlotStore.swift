import Foundation

/// Per-slot Documents-relative file paths for a project's months. UserDefaults-backed
/// stopgap — persists across launches on the same device but not across devices.
/// Move to backend if we ever want cross-device draft resume.
enum UserPhotoSlotStore {
    private static func key(projectID: String, month: Int) -> String {
        // Bumped from "user_photo_slots_" (PHAsset local IDs) — old entries would
        // be garbage as file paths.
        "user_photo_slot_paths_\(projectID)_\(month)"
    }

    static func get(projectID: String, month: Int) -> [String] {
        UserDefaults.standard.stringArray(forKey: key(projectID: projectID, month: month)) ?? []
    }

    static func set(_ ids: [String], projectID: String, month: Int) {
        UserDefaults.standard.set(ids, forKey: key(projectID: projectID, month: month))
    }
}
