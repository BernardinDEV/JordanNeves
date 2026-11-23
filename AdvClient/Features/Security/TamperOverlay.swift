import SwiftUI

/// Tela de bloqueio para aparelho comprometido. Uma tela, e não `exit(0)`:
/// encerrar o app por código é recusado na revisão da App Store e parece
/// travamento para quem usa.
struct TamperOverlay: View {
    var body: some View {
        Theme.background
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.critical)
                        .accessibilityHidden(true)
                    Text("tamper.title")
                        .font(Theme.font(20, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("tamper.message")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
            }
    }
}
