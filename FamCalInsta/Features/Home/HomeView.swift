import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState

    @State private var viewModel: HomeViewModel
    @State private var navigationPath = NavigationPath()

    init() {
        _viewModel = State(wrappedValue: HomeViewModel())
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Medium selection grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What would you like to create?")
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
                case .themeCustomize(let theme):
                    ThemeCustomizeView(theme: theme, navigationPath: $navigationPath)
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
    }
}

enum NavigationDestination: Hashable {
    case themeSelection
    case themeCustomize(theme: Theme)
    case buildDraft(projectID: String, theme: Theme)
    case canvas(projectID: String)
}
