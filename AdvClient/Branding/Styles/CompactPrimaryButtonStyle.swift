import SwiftUI

/// Versão compacta do botão preenchido, para dentro de um cartão.
///
/// O fundo faz parte do rótulo, então a área inteira do botão responde ao
/// toque. Com os modificadores aplicados por fora do `Button`, só o texto era
/// tocável — o resto do retângulo azul era desenho.
struct CompactPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(14, weight: .semibold))
            .foregroundStyle(Theme.onBrand)
            .padding(.horizontal, 18)
            .frame(minHeight: Theme.minTouchTarget)
            .background(
                Theme.primary.opacity(configuration.isPressed ? 0.85 : 1),
                in: .rect(cornerRadius: 10)
            )
    }
}
