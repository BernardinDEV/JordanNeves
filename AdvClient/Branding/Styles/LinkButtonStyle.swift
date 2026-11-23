import SwiftUI

/// Ação de texto, sem fundo: "Pular", "Agora não", "Reenviar código", "Ver todos".
///
/// O texto é pequeno, a área de toque não: o rótulo ganha 44 pt de altura. O
/// modo `compact` é para cabeçalhos de seção, onde 44 pt de altura real
/// empurrariam o layout — a área de toque cresce sem ocupar espaço.
struct LinkButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(compact ? 13.5 : 15, weight: compact ? .regular : .semibold))
            .foregroundStyle(Theme.primary)
            .frame(minHeight: compact ? nil : Theme.minTouchTarget)
            .padding(compact ? 13 : 0)
            .contentShape(.rect)
            .padding(compact ? -13 : 0)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
