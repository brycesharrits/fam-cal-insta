import SwiftUI

struct BrandPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brandPrimary.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
