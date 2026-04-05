import Foundation
import Observation

@Observable
class OrderExportViewModel {
    enum Option { case print, pdf }

    var selectedOption: Option = .print
    var shippingAddress = ShippingAddress()
    var isSubmitting = false
    var errorMessage: String? = nil
    var orderResult: PrintOrderResult? = nil

    func submit(projectID: String, printService: any PrintService, apiClient: APIClient) async {
        isSubmitting = true
        errorMessage = nil
        do {
            if selectedOption == .print {
                orderResult = try await printService.submitPrintOrder(
                    projectID: projectID,
                    shippingAddress: shippingAddress
                )
            } else {
                // PDF export via backend
                struct PDFResponse: Decodable { let downloadUrl: String }
                let _: PDFResponse = try await apiClient.request(.exportPDF(projectID: projectID))
                // TODO: open download URL
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
