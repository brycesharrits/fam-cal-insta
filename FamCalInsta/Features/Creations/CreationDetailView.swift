import SwiftUI

struct CreationDetailView: View {
    let creation: CreationResponse
    /// Called after the user confirms deletion. Parent dismisses via nav pop.
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: creation.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .foregroundStyle(.secondary)
                    default:
                        ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let refURLString = creation.referenceImageUrl,
                   let refURL = URL(string: refURLString) {
                    referenceSection(url: refURL)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Prompt")
                        .font(.headline)
                    Text(creation.prompt)
                        .font(.body)
                }

                HStack {
                    Text(creation.provider)
                    Spacer()
                    Text(creation.createdAt, style: .date)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .navigationTitle("Creation")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.brandBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete this creation?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func referenceSection(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reference photo")
                .font(.headline)
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                default:
                    ProgressView().frame(maxWidth: .infinity, minHeight: 120)
                }
            }
            .frame(maxHeight: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
