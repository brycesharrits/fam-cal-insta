import SwiftUI

struct TokenBalanceBadgeView: View {
    let balance: Int

    var body: some View {
        Label("\(balance)", systemImage: "circle.hexagonpath")
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(Color.brandPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.brandPrimary.opacity(0.1))
            .clipShape(Capsule())
    }
}
