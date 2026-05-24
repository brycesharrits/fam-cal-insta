import SwiftUI

struct BuildDraftView: View {
    @Environment(ServiceContainer.self) private var services
    @Binding var navigationPath: NavigationPath
    @State private var viewModel: BuildDraftViewModel

    init(projectID: String, theme: Theme, navigationPath: Binding<NavigationPath>) {
        _viewModel = State(wrappedValue: BuildDraftViewModel(projectID: projectID, theme: theme))
        _navigationPath = navigationPath
    }

    var body: some View {
        Group {
            if viewModel.isBuilding || viewModel.isComplete {
                MagicalLoadingView(viewModel: viewModel) {
                    navigationPath.append(NavigationDestination.canvas(projectID: viewModel.projectID))
                }
            } else {
                startView
            }
        }
        .navigationTitle(viewModel.theme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isBuilding)
    }

    private var startView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                LinearGradient(colors: viewModel.theme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text("Ready to build your calendar?")
                    .font(.brandTitle)
                    .multilineTextAlignment(.center)

                Text("We'll pick the best photo from each month of \(viewModel.year) and generate 12 unique \(viewModel.theme.displayName) images.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            if let error = viewModel.buildError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
            }

            Button {
                Task {
                    await viewModel.build(
                        photoService: services.photoLibraryService,
                        uploadService: services.uploadService,
                        generationService: services.generationService,
                        apiClient: services.apiClient
                    )
                }
            } label: {
                Label("Build My Draft", systemImage: "wand.and.sparkles")
                    .fontWeight(.semibold)
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color.brandBackground.ignoresSafeArea())
    }
}
