import SwiftUI

/// A marca gráfica do escritório, vinda do catálogo de assets da marca
/// (`BrandMark`). Renderizada como template: só o alpha do arquivo importa, e a
/// cor vem de quem a coloca na tela.
///
/// Aqui havia a bússola do Jordan Neves desenhada como `Shape` — o que fazia o
/// segundo escritório abrir o app com o logotipo do primeiro. Neste app ela não
/// é enfeite: marca a "posição jurídica" no painel, onde a empresa está.
struct BrandMark: View {
    var tint: Color = Theme.primary

    var body: some View {
        Image("BrandMark")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(1, contentMode: .fit)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}
