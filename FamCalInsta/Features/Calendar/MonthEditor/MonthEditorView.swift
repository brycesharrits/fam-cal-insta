import SwiftUI
import PhotosUI

struct MonthEditorView: View {
    let projectID: String
    let month: MonthResponse
    let onUpdated: (MonthResponse) -> Void

    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MonthEditorViewModel
    @State private var selectedItem: PhotosPickerItem? = nil

    private let monthNames = ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"]

    init(projectID: String, month: MonthResponse, onUpdated: @escaping (MonthResponse) -> Void) {
        self.projectID = projectID
        self.month = month
        self.onUpdated = onUpdated
        _viewModel = State(wrappedValue: MonthEditorViewModel(month: month))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Generated image
                    if let imageURL = viewModel.generatedImageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color(.systemGray5).frame(height: 200)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                    }

                    // Controls
                    VStack(spacing: 16) {
                        // Swap reference photo
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Swap Reference Photo", systemImage: "photo.badge.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .onChange(of: selectedItem) { _, item in
                            Task { await viewModel.handlePhotoSelection(item, projectID: projectID, month: month.month, uploadService: services.uploadService) }
                        }

                        // Prompt nudge
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Customize the prompt")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            TextField("e.g. 'more playful, add snow'", text: $viewModel.promptNudge, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3, reservesSpace: true)
                        }

                        // Regenerate
                        Button {
                            Task { await viewModel.regenerate(projectID: projectID, generationService: services.generationService) }
                        } label: {
                            if viewModel.isRegenerating {
                                ProgressView().tint(.white)
                            } else {
                                Label("Regenerate", systemImage: "arrow.trianglehead.2.clockwise")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(BrandPrimaryButtonStyle())
                        .disabled(viewModel.isRegenerating)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(monthNames[month.month - 1])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}
