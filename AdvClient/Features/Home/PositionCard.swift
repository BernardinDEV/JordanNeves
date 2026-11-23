import SwiftUI

/// "Posição jurídica": quantos casos e contratos, e como eles se dividem.
struct PositionCard: View {
    let position: PortfolioPosition
    let openCaseCount: Int
    /// `nil` quando o escritório não oferece documentos: não há contrato a contar.
    let contractCount: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                BrandMark()
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("home.position.title")
                        .font(Theme.font(15, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                    Group {
                        if let contractCount {
                            Text("home.position.summary \(openCaseCount) \(contractCount)")
                        } else {
                            Text("home.position.summaryCases \(openCaseCount)")
                        }
                    }
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.muted)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if !position.isEmpty {
                PositionBar(position: position)

                FlowRow(spacing: 14, rowSpacing: 6) {
                    if position.requiresYou > 0 {
                        PositionLegendItem(
                            color: Theme.critical,
                            text: Format.string("home.legend.requiresYou \(position.requiresYou)")
                        )
                    }
                    if position.deadlineNear > 0 {
                        PositionLegendItem(
                            color: Theme.attention,
                            text: Format.string("home.legend.deadlineNear \(position.deadlineNear)")
                        )
                    }
                    if position.onTrack > 0 {
                        PositionLegendItem(
                            color: Theme.onTrack,
                            text: Format.string("home.legend.onTrack \(position.onTrack)")
                        )
                    }
                }
                // A barra já diz os três números ao VoiceOver.
                .accessibilityHidden(true)
            }
        }
        .card()
        .sideMargin()
    }
}
