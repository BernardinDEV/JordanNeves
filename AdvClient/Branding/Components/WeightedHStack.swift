import SwiftUI

/// Uma linha em que cada filho ocupa a largura proporcional ao seu peso
/// (`layoutWeight`). Substitui o `GeometryReader` que media a largura do
/// cartão só para dividir uma barra em três.
struct WeightedHStack: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let weights = subviews.map { max($0[LayoutWeightKey.self], 0) }
        let total = weights.reduce(0, +)
        guard total > 0 else { return }

        let available = bounds.width - spacing * CGFloat(max(0, subviews.count - 1))
        var x = bounds.minX
        for (subview, weight) in zip(subviews, weights) {
            let width = max(0, available * weight / total)
            subview.place(
                at: CGPoint(x: x, y: bounds.minY),
                proposal: ProposedViewSize(width: width, height: bounds.height)
            )
            x += width + spacing
        }
    }
}

private struct LayoutWeightKey: LayoutValueKey {
    static let defaultValue: CGFloat = 1
}

extension View {
    /// A fatia que esta view ocupa dentro de um `WeightedHStack`.
    func layoutWeight(_ weight: Int) -> some View {
        layoutValue(key: LayoutWeightKey.self, value: CGFloat(weight))
    }
}
