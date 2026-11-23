import SwiftUI

/// A linha do tempo de um caso: só andamentos publicados, o mais novo em cima.
struct CaseTimeline: View {
    let legalCase: LegalCase

    var body: some View {
        // Filtrar e ordenar uma vez por atualização, não uma vez por linha.
        let movements = legalCase.visibleMovements

        if legalCase.isUnderSeal {
            EmptyStateView(
                systemImage: "lock.shield",
                title: "case.underSeal.timelineTitle",
                message: "case.underSeal.timelineMessage"
            )
            .card()
        } else if movements.isEmpty, let activity = legalCase.lastCourtActivity {
            CourtActivityNotice(activity: activity)
                .card()
        } else if movements.isEmpty {
            EmptyStateView(
                systemImage: "clock.badge.questionmark",
                title: "case.timeline.empty.title",
                message: "case.timeline.empty.message"
            )
            .card()
        } else {
            VStack(spacing: 0) {
                ForEach(movements) { movement in
                    NavigationLink(value: AppRoute.movement(caseID: legalCase.id, movementID: movement.id)) {
                        TimelineRow(
                            movement: movement,
                            isFirst: movement.id == movements.first?.id,
                            isLast: movement.id == movements.last?.id
                        )
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
            .card()
        }
    }
}


/// Sem andamento explicado, mas o tribunal se mexeu: diz quando e de onde veio
/// o dado, e por que o texto não aparece.
private struct CourtActivityNotice: View {
    let activity: CourtActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("case.courtActivity.title \(Format.date(activity.date))")
                    .font(Theme.font(15, weight: .semibold))
                    .foregroundStyle(Theme.primary)
            } icon: {
                Image(systemName: "building.columns")
                    .foregroundStyle(Theme.muted)
            }
            Text("case.courtActivity.message")
                .font(Theme.font(13.5))
                .foregroundStyle(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
            if let source = activity.source {
                Text("case.courtActivity.source \(source)")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
