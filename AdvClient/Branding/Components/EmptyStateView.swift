import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: LocalizedStringKey
    var message: LocalizedStringKey?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.muted.opacity(0.6))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.font(16, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(Theme.font(13.5))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, Theme.Space.side)
        .accessibilityElement(children: .combine)
    }
}
