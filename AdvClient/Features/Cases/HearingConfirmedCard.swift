import SwiftUI

/// Audiência com presença já confirmada.
struct HearingConfirmedCard: View {
    let hearing: Hearing

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.onTrack)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("case.hearing.confirmedTitle")
                    .font(Theme.font(15, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                Text(Format.dateTime(hearing.date))
                    .font(Theme.mono(12.5))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .card()
        .sideMargin()
        .accessibilityElement(children: .combine)
    }
}
