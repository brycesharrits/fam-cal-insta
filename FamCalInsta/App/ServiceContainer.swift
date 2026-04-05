import Foundation
import Observation

/// ServiceContainer holds all service instances and is injected via SwiftUI environment.
/// Protocol-based — swap any implementation without changing consumers.
@Observable
class ServiceContainer {
    let apiClient: APIClient
    let authService: any AuthService
    let photoLibraryService: any PhotoLibraryService
    let generationService: any CalendarGenerationService
    let purchaseService: any PurchaseService
    let printService: any PrintService
    let eventKitService: any EventKitService
    let uploadService: PhotoUploadService

    init() {
        let apiClient = APIClient(baseURL: URL(string: "https://api.famcalinsta.com")!)
        self.apiClient = apiClient
        self.authService = AppleAuthService(apiClient: apiClient)
        self.photoLibraryService = PHPhotoLibraryService()
        self.generationService = BackendGenerationService(apiClient: apiClient)
        self.purchaseService = StoreKitPurchaseService(apiClient: apiClient)
        self.printService = BackendPrintService(apiClient: apiClient)
        self.eventKitService = EventKitServiceImpl()
        self.uploadService = PhotoUploadService(apiClient: apiClient)
    }
}
