import SwiftUI

struct ShippingAddressView: View {
    @Binding var address: ShippingAddress

    var body: some View {
        VStack(spacing: 12) {
            TextField("Full name", text: $address.name)
                .textFieldStyle(.roundedBorder)
            TextField("Address line 1", text: $address.line1)
                .textFieldStyle(.roundedBorder)
            TextField("Address line 2 (optional)", text: $address.line2)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 8) {
                TextField("City", text: $address.city)
                    .textFieldStyle(.roundedBorder)
                TextField("State", text: $address.state)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 80)
                TextField("ZIP", text: $address.postalCode)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 80)
                    .keyboardType(.numbersAndPunctuation)
            }
        }
    }
}
