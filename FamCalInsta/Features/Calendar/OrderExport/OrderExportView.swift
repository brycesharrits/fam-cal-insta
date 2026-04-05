import SwiftUI

struct OrderExportView: View {
    let projectID: String

    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = OrderExportViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Option selector
                Picker("", selection: $viewModel.selectedOption) {
                    Text("Print Order").tag(OrderExportViewModel.Option.print)
                    Text("PDF Export").tag(OrderExportViewModel.Option.pdf)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.selectedOption == .print {
                            printSection
                        } else {
                            pdfSection
                        }
                    }
                    .padding(20)
                }

                Spacer()

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                }

                Button {
                    Task { await viewModel.submit(projectID: projectID, printService: services.printService, apiClient: services.apiClient) }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(viewModel.selectedOption == .print ? "Place Free Order" : "Export PDF (5 tokens)")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .disabled(viewModel.isSubmitting)
            }
            .navigationTitle("Order & Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var printSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Free printed calendar — delivered to your door", systemImage: "gift")
                .font(.callout)
                .foregroundStyle(.secondary)

            ShippingAddressView(address: $viewModel.shippingAddress)
        }
    }

    private var pdfSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("High-resolution PDF ready to print anywhere", systemImage: "doc.richtext")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Text("Cost:")
                Spacer()
                Label("5 tokens", systemImage: "circle.hexagonpath")
                    .foregroundStyle(Color.brandPrimary)
            }
            .font(.callout)

            Text("Current balance: \(appState.tokenBalance) tokens")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
