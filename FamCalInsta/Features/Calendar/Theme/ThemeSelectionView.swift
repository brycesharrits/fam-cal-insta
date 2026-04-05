import SwiftUI

struct ThemeSelectionView: View {
    @Environment(ServiceContainer.self) private var services
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = ThemeSelectionViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a theme")
                        .font(.brandTitle)
                    Text("This sets the artistic style for all 12 months. You can tweak individual months later.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Theme.catalog) { theme in
                        ThemeCardView(
                            theme: theme,
                            isSelected: viewModel.selectedTheme?.id == theme.id,
                            onTap: { viewModel.selectedTheme = theme }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 120)
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .navigationTitle("New Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if viewModel.selectedTheme != nil {
                Button {
                    Task { await createAndProceed() }
                } label: {
                    if viewModel.isCreating {
                        ProgressView().tint(.white)
                    } else {
                        Text("Build My Draft")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .disabled(viewModel.isCreating)
            }
        }
    }

    private func createAndProceed() async {
        guard let theme = viewModel.selectedTheme else { return }
        viewModel.isCreating = true
        do {
            let project: ProjectResponse = try await services.apiClient.request(
                .createProject,
                body: CreateProjectRequest(
                    name: "\(Calendar.current.component(.year, from: Date())) Family Calendar",
                    year: Calendar.current.component(.year, from: Date()),
                    theme: theme.id
                )
            )
            navigationPath.append(NavigationDestination.buildDraft(projectID: project.id, theme: theme))
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        viewModel.isCreating = false
    }
}
