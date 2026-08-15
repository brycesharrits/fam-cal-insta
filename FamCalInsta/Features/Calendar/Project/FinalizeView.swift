import SwiftUI

/// Second tab of the project hub. Two cards → existing Dates and Order/Export
/// flows presented as sheets (they already ship a self-contained NavigationStack).
struct FinalizeView: View {
    let projectID: String?
    let months: [MonthResponse]

    @State private var showDates = false
    @State private var showOrder = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if let id = projectID {
                    finalizeCard(
                        title: "Family Dates",
                        subtitle: "Add birthdays, anniversaries, and important days.",
                        systemImage: "calendar.badge.plus",
                        action: { showDates = true }
                    )

                    finalizeCard(
                        title: "Order / Export",
                        subtitle: "Print via partner or export a high-res PDF.",
                        systemImage: "printer",
                        action: { showOrder = true }
                    )
                    .disabled(months.isEmpty)
                    .opacity(months.isEmpty ? 0.5 : 1)
                } else {
                    Text("Finish the Design steps to unlock finalizing.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                }
            }
            .padding(20)
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .sheet(isPresented: $showDates) {
            if let id = projectID {
                DatesLayerView(projectID: id, months: months)
            }
        }
        .sheet(isPresented: $showOrder) {
            if let id = projectID {
                OrderExportView(projectID: id)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Finalize your calendar")
                .font(.brandTitle)
            Text("Add family dates and choose how you want to receive your calendar.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func finalizeCard(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.brandPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.gray.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}
