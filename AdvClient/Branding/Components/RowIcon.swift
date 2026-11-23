import SwiftUI

/// O ícone num quadrado arredondado que abre toda linha de lista do app.
struct RowIcon: View {
    let systemImage: String
    var tone: StatePill.Tone = .neutral

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(tone == .neutral ? Theme.primary : tone.foreground)
            .frame(width: 38, height: 38)
            .background(
                tone == .neutral ? Theme.fill : tone.foreground.opacity(0.13),
                in: .rect(cornerRadius: 10)
            )
            .accessibilityHidden(true)
    }
}
