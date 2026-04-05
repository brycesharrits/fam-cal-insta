import SwiftUI

struct CalendarCanvasView: View {
    let projectID: String
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: CalendarCanvasViewModel
    @State private var selectedMonth: MonthResponse? = nil
    @State private var showDatesLayer = false
    @State private var showOrderExport = false

    init(projectID: String) {
        self.projectID = projectID
        _viewModel = State(wrappedValue: CalendarCanvasViewModel(projectID: projectID))
    }

    private let monthNames = ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"]

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
                                month: month
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
        .navigationTitle("Your Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showDatesLayer = true } label: {
                        Label("Add Dates", systemImage: "calendar.badge.plus")
                    }
                    Button { showOrderExport = true } label: {
                        Label("Order / Export", systemImage: "printer")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $selectedMonth) { month in
            MonthEditorView(
                projectID: projectID,
                month: month,
                onUpdated: { updated in
                    viewModel.updateMonth(updated)
                }
            )
        }
        .sheet(isPresented: $showDatesLayer) {
            DatesLayerView(projectID: projectID, months: viewModel.project?.months ?? [])
        }
        .sheet(isPresented: $showOrderExport) {
            OrderExportView(projectID: projectID)
        }
        .task { await viewModel.load(apiClient: services.apiClient) }
    }

    private func sortedMonths(_ months: [MonthResponse]) -> [MonthResponse] {
        months.sorted { $0.month < $1.month }
    }
}
