import Foundation
import Observation
import SwiftData

/// ServiceContainer holds all service instances and is injected via SwiftUI environment.
/// Protocol-based — swap any implementation without changing consumers.
@Observable
@MainActor
class ServiceContainer {
    let apiClient: APIClient
    let authService: any AuthService
    let photoLibraryService: any PhotoLibraryService
    let generationService: any CalendarGenerationService
    let purchaseService: any PurchaseService
    let printService: any PrintService
    let eventKitService: any EventKitService
    let uploadService: PhotoUploadService
    let creationsService: any CreationsService
    let savedCreationsService: any SavedCreationsService

    init(modelContext: ModelContext) {
        #if DEBUG
        let baseURL = URL(string: "http://localhost:8080")!
        #else
        let baseURL = URL(string: "https://api.famcalinsta.com")!
        #endif
        let apiClient = APIClient(baseURL: baseURL)
        self.apiClient = apiClient
        self.authService = IdentityAuthService(apiClient: apiClient)
        self.photoLibraryService = PHPhotoLibraryService()
        self.generationService = BackendGenerationService(apiClient: apiClient)
        self.purchaseService = StoreKitPurchaseService(apiClient: apiClient)
        self.printService = BackendPrintService(apiClient: apiClient)
        self.eventKitService = EventKitServiceImpl()
        self.uploadService = PhotoUploadService(apiClient: apiClient)
        self.creationsService = BackendCreationsService(apiClient: apiClient)
        self.savedCreationsService = SavedCreationsServiceImpl(context: modelContext)
    }
}
