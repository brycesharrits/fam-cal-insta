import SwiftUI

struct WaitlistSheetView: View {
    let medium: Medium
    @State private var email = ""
    @State private var submitted = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: medium.iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brandPrimary)

                VStack(spacing: 8) {
                    Text("\(medium.displayName) is coming soon")
                        .font(.brandHeadline)
                        .multilineTextAlignment(.center)

                    Text("Be the first to know when it launches.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if !submitted {
                    VStack(spacing: 12) {
                        TextField("Your email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Button("Notify me") {
                            // TODO: submit to backend waitlist endpoint
                            submitted = true
                        }
                        .buttonStyle(BrandPrimaryButtonStyle())
                        .disabled(email.isEmpty)
                    }
                    .padding(.horizontal, 32)
                } else {
                    Label("You're on the list!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                }

                Spacer()
            }
            .padding(.top, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
