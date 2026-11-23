import SwiftUI

/// Retorno de toque para um cartão inteiro que navega. `.plain` deixava o
/// cartão imóvel sob o dedo, e o cliente tocava duas vezes sem saber se pegou.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.65 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
