import SwiftUI

struct ProjectsView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel = ProjectsViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.projects.isEmpty {
                    emptyState
                } else {
                    projectGrid
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.brandBackground.ignoresSafeArea())
            .navigationDestination(for: String.self) { projectID in
                CalendarCanvasView(projectID: projectID)
            }
        }
        .task { await viewModel.load(apiClient: services.apiClient) }
    }

    private var projectGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(viewModel.projects) { project in
                    Button {
                        navigationPath.append(project.id)
                    } label: {
                        ProjectCardView(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .refreshable { await viewModel.load(apiClient: services.apiClient) }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary.opacity(0.4))
            Text("No projects yet")
                .font(.brandTitle)
            Text("Head to Create to start your first family calendar.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProjectCardView: View {
    let project: ProjectResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.brandPrimary.opacity(0.12))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .foregroundStyle(Color.brandPrimary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(String(project.year))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
