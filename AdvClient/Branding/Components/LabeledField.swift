import SwiftUI

/// Text field with a persistent caption above it. The caption never disappears
/// on focus, so the client can still tell what a filled field means.
struct LabeledField<Content: View>: View {
    let label: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.font(11, weight: .medium))
                .kerning(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Theme.muted)
            content
                .font(Theme.font(16))
                .foregroundStyle(Theme.primary)
                .frame(minHeight: 26)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: .rect(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13).stroke(Theme.line, lineWidth: 1)
        }
    }
}
