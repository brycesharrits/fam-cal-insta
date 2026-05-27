import SwiftUI

struct ThemeCustomizeView: View {
    @Environment(ServiceContainer.self) private var services
    let theme: Theme
    @Binding var navigationPath: NavigationPath

    @State private var promptText = ""
    @State private var isGenerating = false
    @State private var tapCount = 0
    @State private var errorMessage: String?

    private let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var canGenerate: Bool {
        promptText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                promptSection
                cardsGrid
                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .navigationTitle(theme.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { generateBar }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Describe your vision")
                .font(.brandHeadline)

            TextField("e.g. Cozy holiday mornings, kids laughing", text: $promptText, axis: .vertical)
                .font(.body)
                .lineLimit(4...8)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var cardsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(monthNames, id: \.self) { name in
                MonthExampleCard(theme: theme, monthName: name)
                    .aspectRatio(0.8, contentMode: .fit)
            }
        }
    }

    private var generateBar: some View {
        Button {
            tapCount += 1
            Task { await generate() }
        } label: {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "sparkles")
                    Text("Generate")
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .font(.headline)
        }
        .buttonStyle(AIGenerateButtonStyle(gradientColors: theme.gradientColors))
        .disabled(!canGenerate || isGenerating)
        .opacity(canGenerate ? 1 : 0.55)
        .animation(.easeInOut(duration: 0.2), value: canGenerate)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .sensoryFeedback(.impact(weight: .medium), trigger: tapCount)
    }

    private func generate() async {
        isGenerating = true
        errorMessage = nil

        let year = Calendar.current.component(.year, from: Date())
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = CreateProjectRequest(
            name: "\(theme.displayName) \(year)",
            year: year,
            theme: theme.id,
            prompt: trimmedPrompt.isEmpty ? nil : trimmedPrompt
        )

        do {
            let project: ProjectResponse = try await services.apiClient.request(.createProject, body: request)
            navigationPath.append(NavigationDestination.buildDraft(projectID: project.id, theme: theme))
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
    }
}

// MARK: - Month example card

struct MonthExampleCard: View {
    let theme: Theme
    let monthName: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Rectangle()
                .fill(.white.opacity(0.04))

            Text(monthName)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.22))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}

// MARK: - AI generate button style

struct AIGenerateButtonStyle: ButtonStyle {
    let gradientColors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    LinearGradient(
                        colors: [.white.opacity(0.22), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
                .clipShape(Capsule())
            )
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(
                color: (gradientColors.last ?? .accentColor).opacity(configuration.isPressed ? 0.25 : 0.5),
                radius: configuration.isPressed ? 6 : 20,
                y: configuration.isPressed ? 2 : 10
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
