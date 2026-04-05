import Foundation

// MARK: - Auth

struct AppleAuthRequest: Encodable {
    let identityToken: String
    let authorizationCode: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: UserResponse
}

struct UserResponse: Codable {
    let id: String
    let email: String
    let tokenBalance: Int
    let createdAt: Date
}

// MARK: - Projects

struct CreateProjectRequest: Encodable {
    let name: String
    let year: Int
    let theme: String
}

struct UpdateProjectRequest: Encodable {
    let name: String?
    let theme: String?
}

struct ProjectResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let year: Int
    let theme: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
    let months: [MonthResponse]?
}

struct MonthResponse: Decodable, Identifiable {
    let id: String
    let month: Int
    let referencePhotoAssetId: String?
    let referenceImageUrl: String?
    let prompt: String?
    let generatedImageUrl: String?
    let status: String
}

// MARK: - Generation

struct MonthGenerationInput: Encodable {
    let month: Int
    let referenceImageUrl: String
    let assetId: String?
}

struct GenerateCalendarRequest: Encodable {
    let months: [MonthGenerationInput]
}

struct GenerateCalendarResponse: Decodable {
    let jobIds: [String]
    let estimatedSeconds: Int
}

struct GenerationJobResponse: Decodable {
    let id: String
    let status: String // queued | processing | complete | failed
    let resultImageUrl: String?
    let error: String?
    let monthId: String
    let calendarId: String
}

struct RegenerateMonthRequest: Encodable {
    let referenceImageUrl: String?
    let prompt: String?
}

struct RegenerateResponse: Decodable {
    let jobId: String
}

// MARK: - Uploads

struct PresignRequest: Encodable {
    let filename: String
    let contentType: String
    let projectId: String
    let month: Int
}

struct PresignResponse: Decodable {
    let uploadUrl: String
    let objectKey: String
    let expiresAt: String
}

// MARK: - Tokens

struct TokenProduct: Decodable, Identifiable {
    var id: String { productId }
    let productId: String
    let tokenAmount: Int
    let displayName: String
    let displayPrice: String
}

struct VerifyPurchaseRequest: Encodable {
    let transactionId: String
    let productId: String
}

struct VerifyPurchaseResponse: Decodable {
    let tokenBalance: Int
    let credited: Int
}

struct TokenBalanceResponse: Decodable {
    let balance: Int
}

// MARK: - Orders

struct AddressRequest: Encodable {
    let name: String
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let postalCode: String
    let country: String
}

struct PrintOrderRequest: Encodable {
    let shippingAddress: AddressRequest
}

struct PrintOrderResponse: Decodable {
    let orderId: String
    let partnerOrderId: String?
    let status: String
}

struct OrderResponse: Decodable {
    let id: String
    let calendarId: String
    let partner: String?
    let status: String
    let partnerOrderId: String?
    let trackingUrl: String?
    let createdAt: Date
}
