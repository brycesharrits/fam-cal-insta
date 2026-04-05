import SwiftUI

struct RecentProjectsView: View {
    let projects: [ProjectResponse]
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Calendars")
                .font(.brandHeadline)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(projects) { project in
                        Button {
                            navigationPath.append(NavigationDestination.canvas(projectID: project.id))
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.brandPrimary.opacity(0.15))
                                    .frame(width: 120, height: 90)
                                    .overlay {
                                        Image(systemName: "calendar")
                                            .font(.title)
                                            .foregroundStyle(Color.brandPrimary)
                                    }

                                Text(project.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(String(project.year))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 120)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
