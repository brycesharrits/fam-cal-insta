import Foundation

struct ShippingAddress {
    var name: String = ""
    var line1: String = ""
    var line2: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var country: String = "US"
}

struct PrintOrderResult {
    let orderID: String
    let partnerOrderID: String?
    let status: String
}

protocol PrintService: AnyObject {
    func submitPrintOrder(projectID: String, shippingAddress: ShippingAddress) async throws -> PrintOrderResult
    func getOrderStatus(orderID: String) async throws -> OrderResponse
}
