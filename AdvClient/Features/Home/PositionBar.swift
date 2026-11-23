import SwiftUI

/// A barra da posição jurídica. Proporcional às contagens reais, não
/// decorativa; o crítico fica à esquerda para o olho cair primeiro no problema.
struct PositionBar: View {
    let position: PortfolioPosition

    var body: some View {
        WeightedHStack(spacing: 3) {
            if position.requiresYou > 0 {
                Capsule().fill(Theme.critical).layoutWeight(position.requiresYou)
            }
            if position.deadlineNear > 0 {
                Capsule().fill(Theme.attention).layoutWeight(position.deadlineNear)
            }
            if position.onTrack > 0 {
                Capsule().fill(Theme.onTrack).layoutWeight(position.onTrack)
            }
        }
        .frame(height: 7)
        .accessibilityElement()
        .accessibilityLabel(Text("home.position.a11y \(position.requiresYou) \(position.deadlineNear) \(position.onTrack)"))
    }
}
