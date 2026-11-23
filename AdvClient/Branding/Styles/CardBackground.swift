import SwiftUI

/// Superfície de cartão: fundo, canto, sombra e — opcionalmente — a faixa de
/// cor na borda esquerda que marca o estado (vermelho exige você, verde ok…).
///
/// A faixa era redesenhada à mão em seis telas, cada uma com um `overlay` e um
/// segundo `clipShape` por cima do cartão.
struct CardBackground: ViewModifier {
    var padding: CGFloat = Theme.Space.card
    var accent: Color?

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .overlay(alignment: .leading) {
                if let accent {
                    Rectangle().fill(accent).frame(width: 3)
                }
            }
            .clipShape(.rect(cornerRadius: Theme.Radius.card))
            .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
    }
}

extension View {
    func card(padding: CGFloat = Theme.Space.card, accent: Color? = nil) -> some View {
        modifier(CardBackground(padding: padding, accent: accent))
    }

    func sideMargin() -> some View {
        padding(.horizontal, Theme.Space.side)
    }

    /// Rótulo de seção em caixa alta com espaçamento — "O QUE SIGNIFICA",
    /// "SEU PRÓXIMO PASSO", "LEVE COM VOCÊ".
    func eyebrow(_ color: Color = Theme.muted) -> some View {
        font(Theme.font(10.5, weight: .semibold))
            .kerning(1.3)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
