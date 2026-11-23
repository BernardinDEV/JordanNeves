import SwiftUI

/// Asked *after* the first successful sign-in, with the reason next to it.
/// Asking before is the classic mistake: the user declines and never finds the
/// setting again.
///
/// Apresentada pela `MainTabView`, não pelo fluxo de login: quando o código é
/// aceito a sessão já existe, e a árvore do login deixou de estar na tela.
struct BiometricOptInStep: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image(systemName: "faceid")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 96, height: 96)
                    .background(Theme.fill, in: .rect(cornerRadius: 26))
                    .accessibilityHidden(true)
                    .padding(.top, 80)

                Text("biometric.optIn.title \(appState.biometryName)")
                    .font(Theme.font(24, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 26)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                // LocalizedStringKey explícito: um ternário de literais vira
                // String, e Text(String) mostra a chave crua em vez de traduzir.
                Text(LocalizedStringKey(appState.isPersonalAccount ? "biometric.optIn.body.personal" : "biometric.optIn.body"))
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .sideMargin()
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button("biometric.optIn.enable \(appState.biometryName)", action: enable)
                    .buttonStyle(PrimaryButtonStyle())

                Button("biometric.optIn.later", action: decline)
                    .buttonStyle(LinkButtonStyle())
            }
            .sideMargin()
            .padding(.vertical, 12)
            .background(Theme.background)
        }
    }

    private func enable() {
        appState.setBiometricEnabled(true)
    }

    private func decline() {
        appState.markBiometricsAsked()
    }
}
