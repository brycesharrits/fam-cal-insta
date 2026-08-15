import SwiftUI

/// Step 1 of the calendar pager. Combines calendar name + theme selection.
/// On Continue, creates the backend project and calls `onCompleted`.
struct ThemeStepView: View {
    @Bindable var hub: CalendarProjectHubViewModel
    let onCompleted: () -> Void

    @Environment(ServiceContainer.self) private var services
    @State private var showCustomThemeSheet = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name your calendar")
                            .font(.brandTitle)
                        Text("Pick a theme too — it sets the artistic style.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Calendar name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Calendar name", text: $hub.draftName)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Theme")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(Theme.catalog) { theme in
                                ThemeCardView(theme: theme, isSelected: hub.draftTheme?.id == theme.id) {
                                    hub.draftTheme = theme
                                }
                            }
                            ThemeCardView(
                                theme: Theme.customPlaceholder,
                                isSelected: hub.draftTheme?.isCustom == true
                            ) {
                                showCustomThemeSheet = true
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if let error = hub.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
            }

            Button {
                Task { await confirm() }
            } label: {
                if hub.isBusy {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .disabled(!canContinue || hub.isBusy)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .sheet(isPresented: $showCustomThemeSheet) {
            CustomThemeConfigView(
                calendarName: hub.draftName,
                onComplete: { customTheme in
                    hub.draftTheme = customTheme
                }
            )
        }
        .disabled(hub.project != nil && hub.progressStage > 1)
    }

    private var canContinue: Bool {
        !hub.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func confirm() async {
        // If the project already exists (user is revisiting step 1), skip re-create.
        // TODO: PATCH name/theme changes back to backend on revisit.
        if hub.projectID != nil {
            onCompleted()
            return
        }
        let ok = await hub.confirmTheme(apiClient: services.apiClient)
        if ok { onCompleted() }
    }
}
