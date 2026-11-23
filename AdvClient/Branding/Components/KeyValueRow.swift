import SwiftUI

struct KeyValueRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let label: LocalizedStringKey
    let value: String
    var isMono = false
    var tint: Color?

    var body: some View {
        // Com a letra em tamanho de acessibilidade, rótulo e valor não cabem
        // lado a lado: o valor desce para a linha de baixo.
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 3))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 16))

        layout {
            Text(label)
                .font(Theme.font(13))
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(isMono ? Theme.mono(13, weight: .semibold) : Theme.font(13.5, weight: .semibold))
                .foregroundStyle(tint ?? Theme.primary)
                .multilineTextAlignment(stacked ? .leading : .trailing)
                .frame(maxWidth: .infinity, alignment: stacked ? .leading : .trailing)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
        // Um par só para o VoiceOver: "Vara, 4ª Vara do Trabalho".
        .accessibilityElement(children: .combine)
    }
}
