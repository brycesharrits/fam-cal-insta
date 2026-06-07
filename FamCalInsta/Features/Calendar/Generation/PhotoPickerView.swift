import SwiftUI

struct PhotoPickerView: View {
    @Environment(ServiceContainer.self) private var services
    let projectID: String
    let theme: Theme
    @Binding var navigationPath: NavigationPath

    @State private var viewModel: PhotoPickerViewModel
    @State private var sheetMonth: MonthSheetID? = nil

    private let monthNames = ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"]

    init(projectID: String, theme: Theme, navigationPath: Binding<NavigationPath>) {
        self.projectID = projectID
        self.theme = theme
        _navigationPath = navigationPath
        _viewModel = State(wrappedValue: PhotoPickerViewModel(projectID: projectID))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading your photos…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.loadError {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Couldn't load photos")
                        .font(.headline)
                    Text(error).font(.callout).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                monthList
            }
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .navigationTitle("Pick photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear all") { viewModel.clearAll() }
                    .disabled(viewModel.selections.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) { continueBar }
        .task { await viewModel.load(photoService: services.photoLibraryService) }
        .sheet(item: $sheetMonth) { sheet in
            AllPhotosPickerSheet(
                pickingForMonthName: monthNames[sheet.month - 1],
                allPhotos: viewModel.allPhotos,
                selectedID: viewModel.selections[sheet.month],
                photoService: services.photoLibraryService,
                onSelect: { localID in
                    viewModel.select(localID: localID, for: sheet.month)
                    sheetMonth = nil
                }
            )
        }
    }

    private var monthList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tap a month to pick a reference photo.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                LazyVStack(spacing: 8) {
                    ForEach(1...12, id: \.self) { month in
                        MonthRow(
                            monthName: monthNames[month - 1],
                            selectedID: viewModel.selections[month],
                            photoService: services.photoLibraryService
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { sheetMonth = MonthSheetID(month: month) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private var continueBar: some View {
        Button {
            navigationPath.append(NavigationDestination.buildDraft(
                projectID: projectID,
                theme: theme,
                photoLocalIDs: viewModel.selections
            ))
        } label: {
            Label("Continue", systemImage: "arrow.right")
                .fontWeight(.semibold)
        }
        .buttonStyle(BrandPrimaryButtonStyle())
        .disabled(!viewModel.allMonthsSelected)
        .opacity(viewModel.allMonthsSelected ? 1 : 0.5)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

private struct MonthSheetID: Identifiable {
    let month: Int
    var id: Int { month }
}

private struct MonthRow: View {
    let monthName: String
    let selectedID: String?
    let photoService: any PhotoLibraryService

    @State private var thumbnail: UIImage? = nil

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemGray6))
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else if selectedID == nil {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 64, height: 64)

            Text(monthName).font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task(id: selectedID) {
            guard let id = selectedID else { thumbnail = nil; return }
            thumbnail = try? await photoService.fetchThumbnail(
                localIdentifier: id,
                size: CGSize(width: 200, height: 200)
            )
        }
    }
}

private struct AllPhotosPickerSheet: View {
    let pickingForMonthName: String
    let allPhotos: [PhotoAsset]
    let selectedID: String?
    let photoService: any PhotoLibraryService
    let onSelect: (String) -> Void

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                if allPhotos.isEmpty {
                    Text("No photos available")
                        .foregroundStyle(.secondary)
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: cols, spacing: 2) {
                        ForEach(allPhotos) { photo in
                            ThumbCell(
                                localID: photo.id,
                                isSelected: photo.id == selectedID,
                                photoService: photoService
                            )
                            .onTapGesture { onSelect(photo.id) }
                        }
                    }
                }
            }
            .navigationTitle("Pick photo for \(pickingForMonthName)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}

private struct ThumbCell: View {
    let localID: String
    let isSelected: Bool
    let photoService: any PhotoLibraryService

    @State private var image: UIImage? = nil

    var body: some View {
        Color(.systemGray6)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .overlay {
                if isSelected {
                    Rectangle().strokeBorder(Color.accentColor, lineWidth: 3)
                }
            }
            .clipped()
        .task {
            image = try? await photoService.fetchThumbnail(
                localIdentifier: localID,
                size: CGSize(width: 240, height: 240)
            )
        }
    }
}
