import SwiftUI

/// Says what happens next, never just "done" — a bare success screen is what
/// generates the follow-up e-mail to the firm.
struct HearingConfirmedView: View {
    @Environment(\.openURL) private var openURL
    let hearing: Hearing
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ConfirmationMark()
                    .padding(.top, 40)

                Text("hearing.confirmed.title")
                    .font(Theme.font(24, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)
                    .accessibilityAddTraits(.isHeader)

                Text("hearing.confirmed.body")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)

                // Offered at the moment it is useful, not buried in settings.
                Button(action: addToCalendar) {
                    AppListRow(
                        title: Format.string("hearing.addToCalendar"),
                        subtitle: Format.dateTime(hearing.date),
                        systemImage: "calendar",
                        isMonoSubtitle: true
                    )
                }
                .buttonStyle(RowPressStyle())
                .card(padding: 0)
                .padding(.top, 24)
            }
            .sideMargin()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            Button("hearing.backToCase", action: onClose)
                .buttonStyle(SecondaryButtonStyle())
                .sideMargin()
                .padding(.vertical, 12)
                .background(Theme.background)
        }
    }

    private func addToCalendar() {
        let title = "\(Format.string("hearing.calendar.title")) — \(BrandConfiguration.current.legalName)"
        if let url = HearingCalendarFile.url(for: hearing, title: title) {
            openURL(url)
        }
    }
}
