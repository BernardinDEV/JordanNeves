import SwiftUI

/// O portão biométrico, quando o app volta ao primeiro plano.
struct LockedOverlay: View {
    let unlock: () -> Void

    var body: some View {
        Theme.background
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.primary)
                        .accessibilityHidden(true)
                    Button("lock.unlock", action: unlock)
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: 220)
                }
                .padding(32)
            }
    }
}
