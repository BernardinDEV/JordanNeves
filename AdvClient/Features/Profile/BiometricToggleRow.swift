import SwiftUI

/// Liga e desliga o bloqueio por Face ID / Touch ID.
struct BiometricToggleRow: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        HStack(spacing: 13) {
            RowIcon(systemImage: "faceid")

            Toggle(isOn: $appState.biometricLockEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("profile.biometric \(appState.biometryName)")
                        .font(Theme.font(15, weight: .medium))
                        .foregroundStyle(Theme.primary)
                    Text("profile.biometric.footer \(appState.biometryName)")
                        .font(Theme.font(12.5))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.primary)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
    }
}
