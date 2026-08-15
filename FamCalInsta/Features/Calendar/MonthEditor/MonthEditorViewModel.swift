import Foundation
import _PhotosUI_SwiftUI
import Observation
import PhotosUI

@Observable
class MonthEditorViewModel {
    var generatedImageURL: String?
    var referenceImageURL: String?
    /// Documents-relative path to a locally-cached reference photo the user
    /// just picked. Used for immediate visual feedback before the S3 upload
    /// wiring runs (still a TODO — handlePhotoSelection is a placeholder).
    var referenceLocalPath: String?
    var promptNudge: String = ""
    var isRegenerating = false
    var isUploadingReference = false
    var regenJobID: String? = nil
    var errorMessage: String? = nil

    private let month: MonthResponse

    init(month: MonthResponse) {
        self.month = month
        self.generatedImageURL = month.generatedImageUrl
        self.referenceImageURL = month.referenceImageUrl
        self.promptNudge = month.prompt ?? ""
    }

    /// Uploads the picked reference photo bytes to S3 and stores the resulting
    /// object key on referenceImageURL — that key is what the Generate flow uses.
    @MainActor
    func uploadReference(jpegData: Data, projectID: String, month: Int, uploadService: PhotoUploadService) async {
        isUploadingReference = true
        errorMessage = nil
        defer { isUploadingReference = false }
        do {
            referenceImageURL = try await uploadService.upload(data: jpegData, projectID: projectID, month: month)
        } catch {
            errorMessage = "Couldn't upload reference: \(error.localizedDescription)"
        }
    }

    func regenerate(projectID: String, generationService: any CalendarGenerationService) async {
        isRegenerating = true
        errorMessage = nil
        do {
            let jobID = try await generationService.regenerateMonth(
                projectID: projectID,
                month: month.month,
                referenceImageURL: referenceImageURL,
                prompt: promptNudge.isEmpty ? nil : promptNudge
            )
            regenJobID = jobID
            await pollForResult(jobID: jobID, generationService: generationService)
        } catch {
            errorMessage = error.localizedDescription
        }
        isRegenerating = false
    }

    private func pollForResult(jobID: String, generationService: any CalendarGenerationService) async {
        var backoff: UInt64 = 2_000_000_000
        for _ in 0..<30 {
            try? await Task.sleep(nanoseconds: backoff)
            backoff = min(backoff + 1_000_000_000, 8_000_000_000)
            do {
                let job = try await generationService.pollJobStatus(jobID: jobID)
                if job.status == "complete", let url = job.resultImageUrl {
                    generatedImageURL = url
                    return
                } else if job.status == "failed" {
                    errorMessage = job.error ?? "Regeneration failed"
                    return
                }
            } catch { }
        }
    }
}
