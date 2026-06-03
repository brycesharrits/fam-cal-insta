// Disposable Test Lab medium UI. Delete when the spike concludes.

import PhotosUI
import SwiftUI

struct TestLabView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: TestLabViewModel?
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Test Lab")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.brandBackground.ignoresSafeArea())
        .onAppear {
            if viewModel == nil {
                viewModel = TestLabViewModel(service: services.testGenerationService)
            }
        }
    }

    @ViewBuilder
    private func content(vm: TestLabViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                disclaimer

                Picker("Mode", selection: $vm.mode) {
                    ForEach(TestLabViewModel.Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if vm.mode == .edit {
                    photoPickerSection(vm: vm)
                }

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
                    Task { await vm.generate() }
                } label: {
                    HStack {
                        if vm.isGenerating {
                            ProgressView().tint(.white)
                        }
                        Text(vm.isGenerating ? "Generating…" : "Generate")
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

                if let image = vm.resultImage {
                    resultSection(image: image, durationMs: vm.lastDurationMs)
                }
            }
            .padding(20)
        }
    }

    private var disclaimer: some View {
        Text("Disposable test surface. Hits OpenAI gpt-image-1 inline; results aren't saved to a project.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func photoPickerSection(vm: TestLabViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reference photo")
                .font(.headline)

            if let data = vm.selectedImageData, let image = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        vm.clearSelectedImage()
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
    private func resultSection(image: UIImage, durationMs: Int?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Result")
                .font(.headline)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if let ms = durationMs {
                Text("Generated in \(ms) ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadPickedImage(_ item: PhotosPickerItem?, vm: TestLabViewModel) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Re-encode to JPEG at modest quality to keep the JSON payload reasonable.
                if let image = UIImage(data: data),
                   let jpeg = image.jpegData(compressionQuality: 0.85) {
                    vm.setSelectedImage(data: jpeg, mime: "image/jpeg")
                } else {
                    vm.setSelectedImage(data: data, mime: "image/png")
                }
            }
        } catch {
            vm.errorMessage = "Failed to load photo: \(error.localizedDescription)"
        }
    }
}
