import SwiftUI

/// The translation, shown first and larger than the court's own words. Inverting
/// this order is what every legal portal does — and why nobody uses them.
struct MeaningBlock: View {
    let translation: String
    var reassuranceKey: String?
    /// "O que isso significa para a sua empresa" ou "… para você".
    var labelKey: LocalizedStringKey = "movement.meaning.label"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(labelKey)
                .eyebrow()
                .padding(.bottom, 8)

            Text(translation)
                .font(Theme.font(15))
                .foregroundStyle(Theme.body)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let reassuranceKey {
                Label {
                    Text(LocalizedStringKey(reassuranceKey))
                } icon: {
                    Image(systemName: "checkmark.shield")
                }
                .font(Theme.font(12.5, weight: .semibold))
                .foregroundStyle(Theme.onTrack)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.onTrack.opacity(0.13), in: .rect(cornerRadius: 8))
                .padding(.top, 12)
            }
        }
        .card(accent: Theme.primary)
    }
}
