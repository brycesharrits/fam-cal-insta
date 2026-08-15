import SwiftUI

struct CalendarCanvasView: View {
    let projectID: String
    let layoutSeed: Int?
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: CalendarCanvasViewModel
    @State private var selectedMonth: MonthResponse? = nil
    @State private var userSlotCountsByMonth: [Int: Int] = [:]

    init(projectID: String, layoutSeed: Int? = nil) {
        self.projectID = projectID
        self.layoutSeed = layoutSeed
        _viewModel = State(wrappedValue: CalendarCanvasViewModel(projectID: projectID))
    }

    private let monthNames = ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"]

    private var layouts: [MonthLayout] {
        MonthLayout.distribute(seed: layoutSeed ?? projectID.hashValue)
    }

    var body: some View {
        ScrollView {
            if let project = viewModel.project {
                VStack(spacing: 20) {
                    // Calendar name + year header
                    VStack(spacing: 4) {
                        Text(project.name)
                            .font(.brandTitle)
                        Text(String(project.year))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // 12-month masonry grid (3 columns)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(sortedMonths(project.months ?? []), id: \.id) { month in
                            MonthTileView(
                                monthName: monthNames[month.month - 1],
                                month: month,
                                layout: layouts[month.month - 1],
                                userSlotFilledCount: userSlotCountsByMonth[month.month] ?? 0
                            ) {
                                selectedMonth = month
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 120)
            } else {
                ProgressView("Loading calendar…")
                    .padding(.top, 60)
            }
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .sheet(item: $selectedMonth) { month in
            MonthEditorView(
                projectID: projectID,
                month: month,
                layout: layouts[month.month - 1],
                onUpdated: { updated in
                    viewModel.updateMonth(updated)
                }
            )
        }
        .onChange(of: selectedMonth?.id) { old, new in
            // Sheet closed — re-read UserPhotoSlotStore so tile dots reflect
            // add/remove edits made in the editor (UserDefaults isn't reactive).
            if old != nil && new == nil {
                refreshUserSlotCounts()
            }
        }
        .task {
            await viewModel.load(apiClient: services.apiClient)
            refreshUserSlotCounts()
        }
    }

    private func sortedMonths(_ months: [MonthResponse]) -> [MonthResponse] {
        months.sorted { $0.month < $1.month }
    }

    private func refreshUserSlotCounts() {
        var counts: [Int: Int] = [:]
        for m in 1...12 {
            counts[m] = UserPhotoSlotStore.get(projectID: projectID, month: m)
                .filter { !$0.isEmpty }.count
        }
        userSlotCountsByMonth = counts
    }
}
