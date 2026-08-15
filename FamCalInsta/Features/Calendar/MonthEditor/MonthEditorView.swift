import SwiftUI
import PhotosUI
import UIKit

struct MonthEditorView: View {
    let projectID: String
    let month: MonthResponse
    let layout: MonthLayout
    let onUpdated: (MonthResponse) -> Void

    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MonthEditorViewModel
    @State private var refPickerItem: PhotosPickerItem? = nil
    @State private var showUserSlotPicker: Bool = false
    @State private var pendingUserSlot: Int? = nil
    @State private var userSlotPickerItem: PhotosPickerItem? = nil
    @State private var userPhotoIDs: [String] = []
    @State private var zoomedSlot: ZoomedSlot? = nil

    private let monthNames = ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"]

    init(projectID: String, month: MonthResponse, layout: MonthLayout, onUpdated: @escaping (MonthResponse) -> Void) {
        self.projectID = projectID
        self.month = month
        self.layout = layout
        self.onUpdated = onUpdated
        _viewModel = State(wrappedValue: MonthEditorViewModel(month: month))
    }

    private var aiFilled: Bool { viewModel.generatedImageURL != nil }
    private var userSlotFilledCount: Int {
        userPhotoIDs.filter { !$0.isEmpty }.count
    }
    private var totalFilled: Int {
        (aiFilled ? 1 : 0) + min(userSlotFilledCount, layout.userSlotCount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    slotGrid
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    HStack(spacing: 6) {
                        ForEach(0..<layout.slotCount, id: \.self) { i in
                            Circle()
                                .fill(i < totalFilled ? Color.accentColor : Color(.systemGray4))
                                .frame(width: 8, height: 8)
                        }
                        Text("\(totalFilled) of \(layout.slotCount) filled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 6)
                    }

                    Divider().padding(.horizontal, 20)

                    aiControls
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
            .onAppear {
                userPhotoIDs = UserPhotoSlotStore.get(projectID: projectID, month: month.month)
                let refPath = UserPhotoCache.referencePath(projectID: projectID, month: month.month)
                if UserPhotoCache.exists(relativePath: refPath) {
                    viewModel.referenceLocalPath = refPath
                }
            }
            .photosPicker(
                isPresented: $showUserSlotPicker,
                selection: $userSlotPickerItem,
                matching: .images
            )
            .onChange(of: userSlotPickerItem) { _, item in
                // pendingUserSlot survives picker dismissal (unlike isPresented),
                // so we can correlate the returned photo with the tapped slot.
                guard let item, let index = pendingUserSlot else {
                    userSlotPickerItem = nil
                    return
                }
                pendingUserSlot = nil
                Task { await handleUserSlotPick(item, at: index) }
            }
            .fullScreenCover(item: $zoomedSlot) { slot in
                ZoomedImageView(source: slot.source) { zoomedSlot = nil }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Slot grid

    /// The container is forced to the printed page aspect (4:3 landscape),
    /// so what you see on screen matches print proportions. Slots split that
    /// space via plain HStack/VStack.
    @ViewBuilder
    private var slotGrid: some View {
        Group {
            switch layout {
            case .single:
                slotView(for: 0)
            case .double:
                HStack(spacing: 6) {
                    slotView(for: 0)
                    slotView(for: 1)
                }
            case .grid:
                VStack(spacing: 6) {
                    HStack(spacing: 6) { slotView(for: 0); slotView(for: 1) }
                    HStack(spacing: 6) { slotView(for: 2); slotView(for: 3) }
                }
            }
        }
        .aspectRatio(MonthLayout.pageAspect, contentMode: .fit)
    }

    /// Slot 0 is the AI slot; the rest are user photo slots.
    @ViewBuilder
    private func slotView(for index: Int) -> some View {
        if index == 0 {
            aiSlotView
        } else {
            userSlotView(userSlotIndex: index - 1)
        }
    }

    private var aiSlotHasContent: Bool {
        viewModel.generatedImageURL != nil || viewModel.referenceLocalPath != nil
    }

    private var aiSlotView: some View {
        ZStack(alignment: .topTrailing) {
            aiSlotContent
                .contentShape(Rectangle())
                .onTapGesture {
                    if let source = aiSlotZoomSource() {
                        zoomedSlot = ZoomedSlot(index: 0, source: source)
                    }
                }

            if aiSlotHasContent {
                removeBadge(action: clearAISlot)
                    .padding(6)
            }
        }
    }

    /// RoundedRectangle is the layout anchor (fully flexible sizing). The image
    /// lives in the overlay so its .scaledToFill() overflow doesn't grow the
    /// slot's layout size — a landscape image in a portrait cell used to
    /// balloon the cell out and push the sibling off-screen.
    private var aiSlotContent: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.accentColor.opacity(0.12))
            .overlay { aiSlotForeground }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var aiSlotForeground: some View {
        if let urlString = viewModel.generatedImageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
        } else if let refPath = viewModel.referenceLocalPath,
                  let refImage = UserPhotoCache.loadImage(relativePath: refPath) {
            ZStack {
                Image(uiImage: refImage)
                    .resizable()
                    .scaledToFit()
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 2, dash: [5, 4])
                    )
            }
        } else {
            VStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                Text("AI slot")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func userSlotView(userSlotIndex: Int) -> some View {
        let isFilled = userSlotIndex < userPhotoIDs.count && !userPhotoIDs[userSlotIndex].isEmpty
        return ZStack(alignment: .topTrailing) {
            userSlotContent(userSlotIndex: userSlotIndex, isFilled: isFilled)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isFilled {
                        zoomedSlot = ZoomedSlot(
                            index: userSlotIndex + 1,
                            source: .local(userPhotoIDs[userSlotIndex])
                        )
                    } else {
                        pendingUserSlot = userSlotIndex
                        showUserSlotPicker = true
                    }
                }

            if isFilled {
                removeBadge { clearUserSlot(userSlotIndex: userSlotIndex) }
                    .padding(6)
            }
        }
    }

    /// See aiSlotContent for why the image lives in an overlay, not as a
    /// ZStack sibling — .scaledToFill() overflow must not grow the slot.
    private func userSlotContent(userSlotIndex: Int, isFilled: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(.systemGray6))
            .overlay {
                if isFilled {
                    UserSlotThumbnail(relativePath: userPhotoIDs[userSlotIndex])
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                        Text("Add photo")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func aiSlotZoomSource() -> ImageSource? {
        if let urlString = viewModel.generatedImageURL, let url = URL(string: urlString) {
            return .remote(url)
        }
        if let refPath = viewModel.referenceLocalPath, UserPhotoCache.exists(relativePath: refPath) {
            return .local(refPath)
        }
        return nil
    }

    private func removeBadge(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.black.opacity(0.55), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove photo")
    }

    private func clearAISlot() {
        viewModel.generatedImageURL = nil
        viewModel.referenceImageURL = nil
        viewModel.referenceLocalPath = nil
        viewModel.promptNudge = ""
        UserPhotoCache.remove(
            relativePath: UserPhotoCache.referencePath(projectID: projectID, month: month.month)
        )
    }

    private func clearUserSlot(userSlotIndex: Int) {
        guard userSlotIndex < userPhotoIDs.count else { return }
        let path = userPhotoIDs[userSlotIndex]
        var updated = userPhotoIDs
        updated[userSlotIndex] = ""
        userPhotoIDs = updated
        UserPhotoSlotStore.set(updated, projectID: projectID, month: month.month)
        if !path.isEmpty {
            UserPhotoCache.remove(relativePath: path)
        }
    }

    // MARK: - AI controls

    private var aiControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                Text("AI slot")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                Spacer()
            }

            Text("The reference photo and prompt below shape the image that fills the AI slot above.")
                .font(.caption)
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $refPickerItem, matching: .images) {
                Label(viewModel.referenceLocalPath == nil && viewModel.referenceImageURL == nil
                        ? "Choose Reference Photo" : "Swap Reference Photo",
                      systemImage: "photo.badge.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .onChange(of: refPickerItem) { _, item in
                Task { await handleReferencePick(item) }
            }

            if viewModel.isUploadingReference {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text("Uploading reference photo…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Prompt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. 'more playful, add snow'", text: $viewModel.promptNudge, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3, reservesSpace: true)
            }

            Button {
                Task { await viewModel.regenerate(projectID: projectID, generationService: services.generationService) }
            } label: {
                if viewModel.isRegenerating {
                    ProgressView().tint(.white).frame(maxWidth: .infinity)
                } else {
                    Label(aiFilled ? "Regenerate" : "Generate",
                          systemImage: aiFilled ? "arrow.trianglehead.2.clockwise" : "sparkles")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .disabled(viewModel.isRegenerating || viewModel.isUploadingReference || viewModel.referenceImageURL == nil)

            if let error = viewModel.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(Color.accentColor.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Reference picker

    private func handleReferencePick(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = image.jpegData(compressionQuality: 0.85) else { return }
            let relativePath = try UserPhotoCache.saveReference(jpeg, projectID: projectID, month: month.month)
            viewModel.referenceLocalPath = relativePath
            // Upload in the background so Generate becomes usable.
            await viewModel.uploadReference(
                jpegData: jpeg,
                projectID: projectID,
                month: month.month,
                uploadService: services.uploadService
            )
        } catch {
            viewModel.errorMessage = "Couldn't save reference photo: \(error.localizedDescription)"
        }
        refPickerItem = nil
    }

    // MARK: - User slot picker

    private func handleUserSlotPick(_ item: PhotosPickerItem, at index: Int) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = image.jpegData(compressionQuality: 0.85) else { return }
            let relativePath = try UserPhotoCache.save(jpeg, projectID: projectID, month: month.month, slot: index)

            var updated = userPhotoIDs
            while updated.count <= index { updated.append("") }
            updated[index] = relativePath
            userPhotoIDs = updated
            UserPhotoSlotStore.set(updated, projectID: projectID, month: month.month)
        } catch {
            viewModel.errorMessage = "Couldn't save photo: \(error.localizedDescription)"
        }
        userSlotPickerItem = nil
    }
}

enum ImageSource: Equatable {
    case remote(URL)
    case local(String) // Documents-relative path
}

struct ZoomedSlot: Identifiable, Equatable {
    let index: Int
    let source: ImageSource
    var id: Int { index }
}

private struct ZoomedImageView: View {
    let source: ImageSource
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            imageContent
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1, min(6, lastScale * value))
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale <= 1.01 {
                                withAnimation(.spring(response: 0.3)) {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            guard scale > 1 else { return }
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3)) {
                        scale = scale > 1 ? 1 : 2
                        lastScale = scale
                        if scale == 1 { offset = .zero; lastOffset = .zero }
                    }
                }

            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5), in: Circle())
                    }
                    .accessibilityLabel("Close")
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if scale <= 1.01 {
                onDismiss()
            } else {
                withAnimation(.spring(response: 0.3)) {
                    scale = 1
                    lastScale = 1
                    offset = .zero
                    lastOffset = .zero
                }
            }
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        switch source {
        case .remote(let url):
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView().tint(.white)
            }
        case .local(let path):
            if let img = UserPhotoCache.loadImage(relativePath: path) {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                Color.clear
            }
        }
    }
}

/// Renders a slot photo from disk (bytes we own — no Photos permission required).
/// Color.clear is the layout anchor so a .scaledToFill() image can't grow this
/// view past its parent's proposed size.
private struct UserSlotThumbnail: View {
    let relativePath: String
    @State private var image: UIImage? = nil

    var body: some View {
        Color.clear
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFit()
                }
            }
            .task(id: relativePath) { load() }
    }

    private func load() {
        image = UserPhotoCache.loadImage(relativePath: relativePath)
    }
}
