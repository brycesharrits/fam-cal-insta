import SwiftUI

struct CustomThemeConfigView: View {
    let calendarName: String
    let onComplete: (Theme) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CustomThemeConfigViewModel()
    @State private var validationMessage: String? = nil

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Design your theme")
                                .font(.brandTitle)
                            Text("Pick your palette and describe the style. We'll use these when generating each month's image.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        HStack(spacing: 0) {
                            vm.primary
                            vm.secondary
                            vm.tertiary
                        }
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Theme name")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("e.g. Coastal Pastel", text: $vm.name)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Colors")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            colorRow(label: "Primary", color: $vm.primary)
                            colorRow(label: "Secondary", color: $vm.secondary)
                            colorRow(label: "Tertiary", color: $vm.tertiary)
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Style descriptor")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField(
                                "e.g. Soft watercolor with hand-drawn details, coastal mood",
                                text: $vm.styleDescriptor,
                                axis: .vertical
                            )
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3, reservesSpace: true)
                        }
                        .padding(.horizontal, 20)

                        if let msg = validationMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }

                Button {
                    if let theme = viewModel.makeTheme() {
                        validationMessage = nil
                        onComplete(theme)
                        dismiss()
                    } else {
                        validationMessage = "Give your theme a name and a style descriptor."
                    }
                } label: {
                    Text("Use this theme")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .background(Color.brandBackground)
            }
            .background(Color.brandBackground.ignoresSafeArea())
            .navigationTitle("Custom Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func colorRow(label: String, color: Binding<Color>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
        }
    }
}
