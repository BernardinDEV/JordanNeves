import SwiftUI

struct TriageArtCard: View {
    let pill: String.LocalizationValue
    let tone: StatePill.Tone
    let title: LocalizedStringKey
    let isDimmed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            StatePill(Format.string(pill), tone: tone)
            Text(title)
                .font(Theme.font(14, weight: .semibold))
                .foregroundStyle(Theme.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: .rect(cornerRadius: 11))
        .opacity(isDimmed ? 0.42 : 1)
    }
}
