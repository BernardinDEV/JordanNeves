import SwiftUI

/// Mensagem de erro sob um campo. Ícone e palavra, nunca só a cor.
struct FieldErrorLabel: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(Theme.font(13))
            .foregroundStyle(Theme.critical)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.opacity)
    }
}
