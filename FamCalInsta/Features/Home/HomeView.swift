import SwiftUI

struct HomeView: View {
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
                    if !viewModel.recentProjects.isEmpty {
                        recentProjectsSection
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("What would you like to create?")
                            .font(.brandHeadline)
                            .padding(.horizontal, 20)

                        MasonryGrid(columns: 2, spacing: 12) {
                            ForEach(viewModel.mediums) { medium in
                                MediumBrickView(medium: medium) {
                                    if medium.isEnabled {
                                        switch medium.id {
                                        case "testlab":
                                            navigationPath.append(NavigationDestination.testLab)
                                        default:
                                            navigationPath.append(NavigationDestination.calendarProject(id: nil))
                                        }
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
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .calendarProject(let id):
                    CalendarProjectView(projectID: id)
                case .testLab:
                    TestLabView()
                }
            }
            .task { await viewModel.loadRecentProjects(apiClient: services.apiClient) }
            .refreshable { await viewModel.loadRecentProjects(apiClient: services.apiClient) }
        }
        .sheet(item: $viewModel.lockedMediumTapped) { medium in
            WaitlistSheetView(medium: medium)
        }
    }

    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your projects")
                .font(.brandHeadline)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                ForEach(viewModel.recentProjects) { project in
                    Button {
                        navigationPath.append(NavigationDestination.calendarProject(id: project.id))
                    } label: {
                        RecentProjectCard(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct RecentProjectCard: View {
    let project: ProjectResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.brandPrimary.opacity(0.12))
                .aspectRatio(1.2, contentMode: .fit)
                .overlay {
                    Image(systemName: "calendar")
                        .font(.title)
                        .foregroundStyle(Color.brandPrimary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(String(project.year))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum NavigationDestination: Hashable {
    case calendarProject(id: String?)
    case testLab
}
