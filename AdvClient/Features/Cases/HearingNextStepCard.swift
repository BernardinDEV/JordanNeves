import SwiftUI

/// "Seu próximo passo": confirmar presença na audiência.
struct HearingNextStepCard: View {
    let hearing: Hearing
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("case.nextStep.label")
                .eyebrow(Theme.critical)

            Text("case.nextStep.confirmHearing")
                .font(Theme.font(17, weight: .semibold))
                .foregroundStyle(Theme.primary)

            Text("case.nextStep.hearingDetail \(Format.dateTime(hearing.date)) \(hearing.venue) \(hearing.address)")
                .font(Theme.font(13.5))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button("case.action.confirmPresence", action: confirm)
                .buttonStyle(CompactPrimaryButtonStyle())
                .padding(.top, 6)
        }
        .card(accent: Theme.critical)
        .sideMargin()
    }
}
