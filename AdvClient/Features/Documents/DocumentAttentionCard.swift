import SwiftUI

/// Um contrato que pede decisão: título, o prazo que força a decisão e a ação.
struct DocumentAttentionCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let document: ClientDocument
    let alert: ContractAlert?

    var body: some View {
        let badge = DocumentBadge.action(for: document, alert: alert)
        // Com a letra em tamanho de acessibilidade o selo desce para baixo do
        // texto, em vez de espremer o título.
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))

        layout {
            VStack(alignment: .leading, spacing: 3) {
                Text(document.title)
                    .font(Theme.font(14.5, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let deadline = document.effectiveDeadline {
                    Text(DocumentRow.deadlineText(for: document)(deadline))
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            StatePill(badge.text, tone: badge.tone)
        }
        .padding(.leading, 17)
        .padding(.trailing, 14)
        .padding(.vertical, 13)
        .card(padding: 0, accent: badge.tone.foreground)
    }
}
