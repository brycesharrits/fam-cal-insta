import SwiftUI

struct ThemeSelectionView: View {
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a theme")
                        .font(.brandTitle)
                    Text("This sets the artistic style for all 12 months. You can tweak individual months later.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Theme.catalog) { theme in
                        ThemeCardView(theme: theme, isSelected: false) {
                            navigationPath.append(NavigationDestination.themeCustomize(theme: theme))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 32)
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .navigationTitle("New Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}
