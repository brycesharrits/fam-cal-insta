import PhotosUI
import SwiftUI

struct PlaygroundView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PlaygroundViewModel?
    @State private var photosPickerItem: PhotosPickerItem?

    /// Called after a successful generation, so a parent library view can refresh.
    var onCreated: ((CreationResponse) -> Void)?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("New Creation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .onAppear {
            if viewModel == nil {
                viewModel = PlaygroundViewModel(
                    service: services.creationsService,
                    uploadService: services.uploadService
                )
            }
        }
    }

    @ViewBuilder
    private func content(vm: PlaygroundViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Describe what you'd like to see. Every generation is saved to your Creations library.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                referenceImageSection(vm: vm)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Prompt")
                        .font(.headline)
                    TextEditor(text: $vm.prompt)
                        .frame(minHeight: 110)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25))
                        )
                }

                Button {
                    Task {
                        await vm.generate()
                        if let creation = vm.lastCreation {
                            onCreated?(creation)
                        }
                    }
                } label: {
                    HStack {
                        if vm.isGenerating || vm.isUploadingReference { ProgressView().tint(.white) }
                        Text(generateButtonLabel(vm: vm))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(vm.canGenerate ? Color.accentColor : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canGenerate)

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                if let creation = vm.lastCreation {
                    resultSection(creation: creation)
                }
            }
            .padding(20)
        }
    }

    private func generateButtonLabel(vm: PlaygroundViewModel) -> String {
        if vm.isUploadingReference { return "Uploading photo…" }
        if vm.isGenerating { return "Generating…" }
        return "Generate"
    }

    @ViewBuilder
    private func referenceImageSection(vm: PlaygroundViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reference photo (optional)")
                .font(.headline)

            if let image = vm.selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        vm.clearReferenceImage()
                        photosPickerItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.6))
                            .padding(8)
                    }
                }
            } else {
                PhotosPicker(selection: $photosPickerItem, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Pick a photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.25))
                    )
                }
                .onChange(of: photosPickerItem) { _, newItem in
                    Task { await loadPickedImage(newItem, vm: vm) }
                }
            }
        }
    }

    @ViewBuilder
    private func resultSection(creation: CreationResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Result")
                .font(.headline)
            AsyncImage(url: URL(string: creation.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                default:
                    ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func loadPickedImage(_ item: PhotosPickerItem?, vm: PlaygroundViewModel) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                vm.setReferenceImage(image)
            }
        } catch {
            vm.errorMessage = "Failed to load photo: \(error.localizedDescription)"
        }
    }
}
