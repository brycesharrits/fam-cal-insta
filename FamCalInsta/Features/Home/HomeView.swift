import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services

    @State private var viewModel: HomeViewModel
    @State private var navigationPath = NavigationPath()

    init() {
        _viewModel = State(wrappedValue: HomeViewModel())
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Recent projects (for returning users)
                    if !viewModel.recentProjects.isEmpty {
                        RecentProjectsView(projects: viewModel.recentProjects, navigationPath: $navigationPath)
                    }

                    // Medium selection grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.recentProjects.isEmpty ? "What would you like to create?" : "Create something new")
                            .font(.brandHeadline)
                            .padding(.horizontal, 20)

                        MasonryGrid(columns: 2, spacing: 12) {
                            ForEach(viewModel.mediums) { medium in
                                MediumBrickView(medium: medium) {
                                    if medium.isEnabled {
                                        navigationPath.append(NavigationDestination.themeSelection)
                                    } else {
                                        viewModel.lockedMediumTapped = medium
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.brandBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("fam-cal-insta")
                        .font(.brandTitle)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    TokenBalanceBadgeView(balance: appState.tokenBalance)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .themeSelection:
                    ThemeSelectionView(navigationPath: $navigationPath)
                case .buildDraft(let projectID, let theme):
                    BuildDraftView(projectID: projectID, theme: theme, navigationPath: $navigationPath)
                case .canvas(let projectID):
                    CalendarCanvasView(projectID: projectID)
                }
            }
        }
        .sheet(item: $viewModel.lockedMediumTapped) { medium in
            WaitlistSheetView(medium: medium)
        }
        .task { await viewModel.loadRecentProjects(apiClient: services.apiClient) }
    }
}

enum NavigationDestination: Hashable {
    case themeSelection
    case buildDraft(projectID: String, theme: Theme)
    case canvas(projectID: String)
}
