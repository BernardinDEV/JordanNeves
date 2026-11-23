import SwiftUI

/// O que as listas mostram enquanto o primeiro carregamento não respondeu.
struct FirstLoadPlaceholder: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
    }
}
