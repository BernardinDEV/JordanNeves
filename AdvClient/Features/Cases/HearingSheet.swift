import SwiftUI

/// Confirming attendance at a hearing. A sheet rather than a full screen so the
/// client never loses the case behind it, and the checklist replaces the
/// instruction e-mail that today gets lost in an inbox.
struct HearingSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let caseID: UUID
    let caseNumber: String
    let hearing: Hearing

    @State private var checklist: [ChecklistItem]
    @State private var isConfirming = false
    @State private var didConfirm = false

    init(caseID: UUID, caseNumber: String, hearing: Hearing) {
        self.caseID = caseID
        self.caseNumber = caseNumber
        self.hearing = hearing
        _checklist = State(initialValue: hearing.checklist)
    }

    var body: some View {
        NavigationStack {
            Group {
                if didConfirm {
                    ConfirmedView(hearing: hearing) { dismiss() }
                } else {
                    form
                }
            }
            .background(Theme.background)
            .navigationTitle(Text(didConfirm ? "" : "hearing.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !didConfirm {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("common.close") { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    KeyValueRow(label: "hearing.when", value: Format.dateTime(hearing.date), isMono: true)
                    KeyValueRow(label: "hearing.where", value: "\(hearing.venue)\n\(hearing.address)")
                    KeyValueRow(label: "hearing.who", value: hearing.whoMustAttend)
                }
                .padding(.bottom, 18)

                Text("hearing.bring")
                    .font(Theme.font(10.5, weight: .semibold))
                    .kerning(1.3)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 10)

                VStack(spacing: 9) {
                    ForEach($checklist) { $item in
                        Button {
                            item.isChecked.toggle()
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 19))
                                    .foregroundStyle(item.isChecked ? Theme.primary : Theme.muted)
                                Text(item.text)
                                    .font(Theme.font(14))
                                    .foregroundStyle(Theme.body)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: 30)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.fill, in: RoundedRectangle(cornerRadius: 13))

                VStack(spacing: 8) {
                    Button {
                        confirm()
                    } label: {
                        if isConfirming {
                            ProgressView().tint(Theme.onBrand)
                        } else {
                            Text("hearing.action.confirm")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: !isConfirming))
                    .disabled(isConfirming)

                    WhatsAppButton(
                        context: .hearingConflict(caseNumber: caseNumber, hearingDate: hearing.date),
                        caseID: caseID,
                        titleKey: "hearing.action.cannotAttend"
                    )
                }
                .padding(.top, 20)
            }
            .sideMargin()
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private func confirm() {
        isConfirming = true
        Task {
            await appState.confirmHearing(caseID: caseID)
            isConfirming = false
            withAnimation { didConfirm = true }
        }
    }
}

// MARK: - Confirmation

/// Says what happens next, never just "done" — a bare success screen is what
/// generates the follow-up e-mail to the firm.
private struct ConfirmedView: View {
    @Environment(\.openURL) private var openURL
    let hearing: Hearing
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Theme.onTrack)
                .frame(width: 74, height: 74)
                .background(Theme.onTrack.opacity(0.15), in: Circle())

            Text("hearing.confirmed.title")
                .font(Theme.font(24, weight: .bold))
                .foregroundStyle(Theme.primary)
                .padding(.top, 22)

            Text("hearing.confirmed.body")
                .font(Theme.font(15))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)

            // Offered at the moment it is useful, not buried in settings.
            Button {
                addToCalendar()
            } label: {
                AppListRow(
                    title: String(localized: "hearing.addToCalendar"),
                    subtitle: Format.dateTime(hearing.date),
                    systemImage: "calendar",
                    isMonoSubtitle: true
                )
            }
            .buttonStyle(.plain)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
            .padding(.top, 24)

            Spacer()

            Button("hearing.backToCase") { onClose() }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.bottom, 20)
        }
        .sideMargin()
    }

    /// Hands the event to the system calendar as a data: URL, so the app needs no
    /// calendar permission for a one-off event the user explicitly asked for.
    private func addToCalendar() {
        let start = hearing.date
        let end = start.addingTimeInterval(2 * 3600)
        let stamp: (Date) -> String = { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            formatter.timeZone = Rules.calendar.timeZone
            return formatter.string(from: date)
        }
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        DTSTART:\(stamp(start))
        DTEND:\(stamp(end))
        SUMMARY:\(String(localized: "hearing.calendar.title")) — \(BrandConfiguration.current.legalName)
        LOCATION:\(hearing.venue) — \(hearing.address)
        END:VEVENT
        END:VCALENDAR
        """
        guard let encoded = ics.data(using: .utf8)?.base64EncodedString(),
              let url = URL(string: "data:text/calendar;base64,\(encoded)") else { return }
        openURL(url)
    }
}

#Preview {
    HearingSheet(
        caseID: MockData.laborCaseID,
        caseNumber: "0012345-16.2025.5.17.0004",
        hearing: MockData.cases[0].hearing!
    )
    .environment(AppState.signedInPreview())
}
