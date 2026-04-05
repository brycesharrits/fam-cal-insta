import Foundation
import StoreKit

class StoreKitPurchaseService: PurchaseService {
    private let apiClient: APIClient
    private var products: [Product] = []

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        Task { await listenForTransactions() }
    }

    func fetchProducts() async throws -> [TokenPackage] {
        // Fetch product configs from backend (matches App Store Connect product IDs)
        let backendProducts: [TokenProduct] = try await apiClient.request(.getTokenProducts)
        let productIDs = backendProducts.map { $0.productId }

        let storeProducts = try await Product.products(for: productIDs)
        self.products = storeProducts

        return storeProducts.compactMap { storeProduct in
            guard let backend = backendProducts.first(where: { $0.productId == storeProduct.id }) else { return nil }
            return TokenPackage(
                id: storeProduct.id,
                tokenAmount: backend.tokenAmount,
                displayPrice: storeProduct.displayPrice,
                displayName: storeProduct.displayName
            )
        }.sorted { $0.tokenAmount < $1.tokenAmount }
    }

    func purchase(package: TokenPackage) async throws -> PurchaseResult {
        guard let product = products.first(where: { $0.id == package.id }) else {
            throw APIError.httpError(statusCode: 400, message: "Product not found")
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            let verifyResponse: VerifyPurchaseResponse = try await apiClient.request(
                .verifyPurchase,
                body: VerifyPurchaseRequest(
                    transactionId: String(transaction.id),
                    productId: package.id
                )
            )
            await transaction.finish()
            return PurchaseResult(
                tokenBalance: verifyResponse.tokenBalance,
                credited: verifyResponse.credited
            )

        case .userCancelled:
            throw APIError.httpError(statusCode: 0, message: "Purchase cancelled")

        case .pending:
            throw APIError.httpError(statusCode: 0, message: "Purchase pending approval")

        @unknown default:
            throw APIError.httpError(statusCode: 0, message: "Unknown purchase result")
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    func getBalance() async throws -> Int {
        let response: TokenBalanceResponse = try await apiClient.request(.getTokenBalance)
        return response.balance
    }

    // MARK: - Private

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw APIError.httpError(statusCode: 400, message: "Transaction verification failed")
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
        }
    }
}
