import Foundation

struct TokenPackage: Identifiable {
    let id: String        // App Store product ID
    let tokenAmount: Int
    let displayPrice: String
    let displayName: String
}

struct PurchaseResult {
    let tokenBalance: Int
    let credited: Int
}

protocol PurchaseService: AnyObject {
    func fetchProducts() async throws -> [TokenPackage]
    func purchase(package: TokenPackage) async throws -> PurchaseResult
    func restorePurchases() async throws
    func getBalance() async throws -> Int
}
