// Disposable Test Lab medium UI. Delete when the spike concludes.

import Photos
import PhotosUI
import SwiftUI

struct TestLabView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: TestLabViewModel?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var resultShareImage: TestLabShareItem?
    @State private var resultToast: String?

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
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                resultMenu(image: image)
                    .padding(8)

                if let resultToast {
                    Text(resultToast)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 44)
                        .padding(.trailing, 8)
                        .transition(.opacity)
                }
            }
            if let ms = durationMs {
                Text("Generated in \(ms) ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(item: $resultShareImage) { item in
            TestLabShareSheet(items: [item.image])
        }
    }

    @ViewBuilder
    private func resultMenu(image: UIImage) -> some View {
        Menu {
            Button {
                Task { await saveResultToLibrary(image: image) }
            } label: {
                Label("Save to Library", systemImage: "square.and.arrow.down")
            }
            Button {
                Task { await saveResultToCameraRoll(image: image) }
            } label: {
                Label("Save to Photos", systemImage: "photo.badge.plus")
            }
            Button {
                resultShareImage = TestLabShareItem(image: image)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.black.opacity(0.45), in: Circle())
        }
    }

    private func saveResultToLibrary(image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let metadata = SavedCreationMetadata(prompt: viewModel?.prompt, themeName: "Test Lab")
        do {
            _ = try await services.savedCreationsService.save(imageData: data, metadata: metadata)
            await showResultToast("Saved")
        } catch {
            await showResultToast("Save failed")
        }
    }

    private func saveResultToCameraRoll(image: UIImage) async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            await showResultToast("Photos access denied")
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            await showResultToast("Saved to Photos")
        } catch {
            await showResultToast("Save failed")
        }
    }

    @MainActor
    private func showResultToast(_ message: String) async {
        withAnimation { resultToast = message }
        try? await Task.sleep(for: .seconds(1.6))
        withAnimation { resultToast = nil }
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

private struct TestLabShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct TestLabShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
