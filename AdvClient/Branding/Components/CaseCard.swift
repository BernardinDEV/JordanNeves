import SwiftUI

struct CaseCard: View {
    let legalCase: LegalCase
    let state: CaseState
    var deadline: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Lado a lado quando cabe; empilhado quando a letra está grande.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 8) {
                    areaLabel
                    Spacer(minLength: 4)
                    pill
                }
                VStack(alignment: .leading, spacing: 6) {
                    areaLabel
                    pill
                }
            }
            .padding(.bottom, 6)

            Text(legalCase.title)
                .font(Theme.font(15.5, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(legalCase.number)
                .font(Theme.mono(11.5))
                .foregroundStyle(Theme.muted)
                .padding(.top, 5)

            if let nextStepText {
                Divider().overlay(Theme.line).padding(.vertical, 9)
                Text(nextStepText)
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.leading, 17)
        .padding(.trailing, 14)
        .padding(.vertical, 13)
        .card(padding: 0, accent: Theme.color(for: state))
    }

    private var areaLabel: some View {
        // verbatim: the pieces are already localised; treating the joined
        // string as a key would expose "%@ · %@" to translators.
        Text(verbatim: "\(Format.string(.init(legalCase.area.labelKey))) · \(legalCase.courtShort)")
            .font(Theme.font(10.5))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Theme.muted)
            .lineLimit(1)
    }

    /// One date per card. The hearing is the anchor the client recognises; the
    /// confirmation deadline that precedes it goes in the next-step line, where
    /// it can be labelled.
    private var pill: StatePill {
        if let pillDate, state == .requiresYou {
            StatePill(Format.weekdayDate(pillDate), tone: .critical)
        } else {
            StatePill(state: state)
        }
    }

    /// Date shown in the pill. Prefers the hearing, so the pill and the
    /// next-step line can never disagree about which date they mean.
    private var pillDate: Date? {
        if let hearing = legalCase.hearing, !hearing.isConfirmed { return hearing.date }
        return deadline
    }

    private var nextStepText: String? {
        if legalCase.isUnderSeal {
            return Format.string("case.underSeal.short")
        }
        if let hearing = legalCase.hearing, !hearing.isConfirmed {
            if let confirmBy = deadline, confirmBy < hearing.date {
                return Format.string("case.next.hearingConfirmBy \(Format.dateTime(hearing.date)) \(Format.date(confirmBy))")
            }
            return Format.string("case.next.hearing \(Format.dateTime(hearing.date))")
        }
        if let headline = legalCase.visibleMovements.first?.displayHeadline {
            return headline
        }
        // Houve movimento, mas sem explicação publicada: a data, nunca o texto.
        return legalCase.lastCourtActivity.map {
            Format.string("case.next.courtActivity \(Format.date($0.date))")
        }
    }
}
