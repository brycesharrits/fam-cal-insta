import SwiftUI

/// Hub view for a single calendar project. Shows a Design/Finalize segmented
/// picker; Design side is a 3-step swipe pager (Theme → Layout → Canvas);
/// Finalize side surfaces the Dates and Order/Export flows.
///
/// - projectID = nil: new draft (only the Theme step is accessible until the
///   project is created on Continue).
/// - projectID != nil: hydrate from the backend and land on the step
///   corresponding to progress_stage.
struct CalendarProjectView: View {
    let initialProjectID: String?

    @Environment(ServiceContainer.self) private var services
    @State private var hub = CalendarProjectHubViewModel()
    @State private var mode: Mode = .design
    @State private var currentStep: Int = 0
    @State private var hasBootstrapped = false

    enum Mode: String, Hashable, CaseIterable {
        case design = "Design"
        case finalize = "Finalize"
    }

    init(projectID: String?) {
        self.initialProjectID = projectID
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            switch mode {
            case .design:
                designPager
            case .finalize:
                FinalizeView(projectID: hub.projectID, months: hub.project?.months ?? [])
            }
        }
        .navigationTitle(hub.project?.name ?? "New Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.brandBackground.ignoresSafeArea())
        .task {
            guard !hasBootstrapped else { return }
            hasBootstrapped = true
            await hub.bootstrap(projectID: initialProjectID, apiClient: services.apiClient)
            currentStep = hub.maxUnlockedIndex
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { hub.errorMessage != nil },
                set: { if !$0 { hub.errorMessage = nil } }
            ),
            presenting: hub.errorMessage
        ) { _ in
            Button("OK", role: .cancel) { hub.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Design pager

    @ViewBuilder
    private var designPager: some View {
        let maxIndex = hub.maxUnlockedIndex
        TabView(selection: $currentStep) {
            ThemeStepView(hub: hub, onCompleted: {
                advance(to: 1)
            })
            .tag(0)

            if maxIndex >= 1 {
                LayoutStepView(hub: hub, onCompleted: {
                    advance(to: 2)
                })
                .tag(1)
            }

            if maxIndex >= 2 {
                CalendarCanvasView(projectID: hub.projectID ?? "", layoutSeed: hub.layoutSeed)
                    .tag(2)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onChange(of: hub.maxUnlockedIndex) { _, newMax in
            // Clamp if the user was on a page that just got locked away.
            if currentStep > newMax { currentStep = newMax }
        }
    }

    private func advance(to target: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = min(target, hub.maxUnlockedIndex)
        }
    }
}
