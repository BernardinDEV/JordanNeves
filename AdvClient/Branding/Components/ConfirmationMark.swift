import SwiftUI

/// O visto verde das telas de confirmação — presença confirmada, arquivo enviado.
struct ConfirmationMark: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 32, weight: .semibold))
            .foregroundStyle(Theme.onTrack)
            .frame(width: 74, height: 74)
            .background(Theme.onTrack.opacity(0.15), in: .circle)
            .accessibilityHidden(true)
    }
}
