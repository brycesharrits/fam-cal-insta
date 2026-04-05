import SwiftUI

/// Simple masonry-style grid backed by LazyVGrid.
/// True variable-height masonry layout can be added later via the Layout protocol.
struct MasonryGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            content()
        }
    }
}
