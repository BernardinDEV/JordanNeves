import SwiftUI

/// Uma cláusula que o escritório marcou ao revisar o contrato.
struct ClauseCard: View {
    let point: AttentionPoint

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(point.clause)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.muted)
            Text(point.title)
                .font(Theme.font(14.5, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text(point.detail)
                .font(Theme.font(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card(padding: 14, accent: point.isWarning ? Theme.attention : Theme.onTrack)
        .accessibilityElement(children: .combine)
    }
}
