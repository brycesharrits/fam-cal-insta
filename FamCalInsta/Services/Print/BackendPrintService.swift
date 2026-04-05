import Foundation

class BackendPrintService: PrintService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func submitPrintOrder(projectID: String, shippingAddress: ShippingAddress) async throws -> PrintOrderResult {
        let response: PrintOrderResponse = try await apiClient.request(
            .submitPrintOrder(projectID: projectID),
            body: PrintOrderRequest(shippingAddress: AddressRequest(
                name: shippingAddress.name,
                line1: shippingAddress.line1,
                line2: shippingAddress.line2.isEmpty ? nil : shippingAddress.line2,
                city: shippingAddress.city,
                state: shippingAddress.state,
                postalCode: shippingAddress.postalCode,
                country: shippingAddress.country
            ))
        )
        return PrintOrderResult(
            orderID: response.orderId,
            partnerOrderID: response.partnerOrderId,
            status: response.status
        )
    }

    func getOrderStatus(orderID: String) async throws -> OrderResponse {
        return try await apiClient.request(.getOrder(id: orderID))
    }
}
