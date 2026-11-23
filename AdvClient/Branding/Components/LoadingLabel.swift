import SwiftUI

/// Rótulo de botão que vira indicador de progresso enquanto a ação corre.
/// O texto continua sendo o nome do botão para o VoiceOver.
struct LoadingLabel: View {
    let title: LocalizedStringKey
    let isLoading: Bool

    init(_ title: LocalizedStringKey, isLoading: Bool) {
        self.title = title
        self.isLoading = isLoading
    }

    var body: some View {
        Text(title)
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {
                    ProgressView().tint(Theme.onBrand)
                }
            }
    }
}
