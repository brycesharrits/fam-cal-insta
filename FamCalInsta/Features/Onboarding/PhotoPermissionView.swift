import SwiftUI
import Photos

struct PhotoPermissionView: View {
    @Environment(ServiceContainer.self) private var services
    let onGranted: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(Color.brandPrimary)

            VStack(spacing: 12) {
                Text("Your photos, your calendar")
                    .font(.brandTitle)
                    .multilineTextAlignment(.center)

                Text("We use your photo library to create personalized AI-generated calendar images. We never store your original photos.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                Task { await requestPermission() }
            } label: {
                if isRequesting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Allow Photo Access")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .disabled(isRequesting)
            .padding(.horizontal, 32)

            Button("Skip for now") {
                onGranted()
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
        .background(Color.brandBackground.ignoresSafeArea())
    }

    private func requestPermission() async {
        isRequesting = true
        let status = await services.photoLibraryService.requestAuthorization()
        isRequesting = false
        // Proceed regardless of grant level — user can grant later
        _ = status
        onGranted()
    }
}
