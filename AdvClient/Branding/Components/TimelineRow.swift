import SwiftUI

struct TimelineRow: View {
    let movement: CaseMovement
    var isFirst: Bool
    var isLast: Bool

    private var dotColor: Color {
        movement.requiresClient ? Theme.attention : Theme.line
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Theme.line)
                    .frame(width: 1.5)
                    .padding(.top, isFirst ? 10 : 0)
                    .padding(.bottom, isLast ? 0 : -40)
                    .opacity(isLast ? 0 : 1)

                Circle()
                    .fill(movement.requiresClient ? Theme.attention : Theme.card)
                    .stroke(dotColor, lineWidth: 2.5)
                    .frame(width: 11, height: 11)
                    .padding(.top, 5)
            }
            .frame(width: 11)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(Format.date(movement.date))
                    .font(Theme.mono(11.5))
                    .foregroundStyle(Theme.muted)
                Text(movement.displayHeadline)
                    .font(Theme.font(14.5, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 14)
            .padding(.bottom, isLast ? 0 : 18)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.muted.opacity(0.55))
                .padding(.top, 6)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
    }
}
