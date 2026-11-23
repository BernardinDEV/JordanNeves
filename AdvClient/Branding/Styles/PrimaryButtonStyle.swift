import SwiftUI

/// O botão preenchido — um por tela.
///
/// Lê `isEnabled` do ambiente: basta `.disabled(...)` no botão para ele
/// esmaecer. Antes o estado era passado duas vezes (no estilo e no
/// `.disabled`), e os dois podiam discordar.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration)
    }
}

private struct PrimaryButtonBody: View {
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .font(Theme.font(16, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.primary.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(Theme.onBrand)
            .clipShape(.rect(cornerRadius: 13))
            .opacity(isEnabled ? 1 : 0.45)
    }
}
