import SwiftUI

/// Retorno de toque para uma linha dentro de um `RowCard`: a linha escurece
/// enquanto é pressionada, como numa lista do sistema.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.fill : .clear)
    }
}
