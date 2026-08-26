import SwiftUI

// MARK: - Brand mark

/// The compass rose from the firm's logo, drawn as a shape so it scales cleanly
/// and takes the current foreground colour. In this app it is not decoration: it
/// marks the dashboard's "posição jurídica" — where the company stands.
struct CompassRose: View {
    var showsRing = true

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let scale = side / 100
            ZStack {
                Star8()
                    .fill(.tint)
                if showsRing {
                    CompassRing()
                        .stroke(.tint, style: StrokeStyle(lineWidth: 6.5 * scale, lineCap: .round))
                }
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Eight-point star: long points at the cardinals, shorter ones between.
private struct Star8: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 100
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for index in 0..<16 {
            let angle = Double(index) * .pi / 8 - .pi / 2
            let radius: Double = index.isMultiple(of: 2)
                ? (index.isMultiple(of: 4) ? 44 : 34)
                : 7.5
            let point = CGPoint(
                x: center.x + radius * scale * cos(angle),
                y: center.y + radius * scale * sin(angle)
            )
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

/// Four arcs with cardinal ticks — the instrument bezel.
private struct CompassRing: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 100
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = 42.0 * scale
        var path = Path()
        for quadrant in 0..<4 {
            let start = Double(quadrant) * 90 - 78
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(start),
                endAngle: .degrees(start + 56),
                clockwise: false
            )
        }
        for tick in 0..<4 {
            let angle = Double(tick) * .pi / 2 - .pi / 2
            let inner = 46.0 * scale, outer = 50.0 * scale
            path.move(to: CGPoint(x: center.x + inner * cos(angle), y: center.y + inner * sin(angle)))
            path.addLine(to: CGPoint(x: center.x + outer * cos(angle), y: center.y + outer * sin(angle)))
        }
        return path
    }
}

// MARK: - State pill

/// A status badge. Always carries words — the app never encodes state in colour
/// alone, so it still reads for someone who can't tell amber from red.
struct StatePill: View {
    let text: String
    let tone: Tone

    enum Tone {
        case onTrack, attention, critical, neutral, brass

        var foreground: Color {
            switch self {
            case .onTrack: Theme.onTrack
            case .attention: Theme.attention
            case .critical: Theme.critical
            case .neutral: Theme.muted
            case .brass: Theme.brass
            }
        }

        var background: Color {
            switch self {
            case .neutral: Theme.fill
            default: foreground.opacity(0.14)
            }
        }
    }

    init(_ text: String, tone: Tone) {
        self.text = text
        self.tone = tone
    }

    init(state: CaseState) {
        self.text = String(localized: .init(state.labelKey))
        self.tone = switch state {
        case .requiresYou: .critical
        case .deadlineNear: .attention
        case .withCourt: .neutral
        case .onTrack: .onTrack
        }
    }

    var body: some View {
        Text(text)
            .font(Theme.font(11.5, weight: .semibold))
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(tone.background, in: RoundedRectangle(cornerRadius: Theme.Radius.pill))
            .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Section header

struct SectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.font(13, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.4)
                .foregroundStyle(Theme.muted)
            Spacer(minLength: 8)
            trailing
        }
        .sideMargin()
        .padding(.top, 22)
        .padding(.bottom, 9)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: LocalizedStringKey) {
        self.init(title: title) { EmptyView() }
    }
}

// MARK: - Deadline

/// A deadline always shows both the date and the countdown. The date alone forces
/// mental arithmetic; the countdown alone loses the reference.
struct DeadlineLabel: View {
    let date: Date
    var showsDate = true

    var body: some View {
        Text(showsDate ? Format.deadline(date) : Format.countdown(to: date))
            .font(Theme.mono(12))
            .foregroundStyle(Theme.muted)
    }
}

// MARK: - Case card

struct CaseCard: View {
    let legalCase: LegalCase
    let state: CaseState
    var deadline: Date?

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Theme.color(for: state))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    // verbatim: the pieces are already localised; treating the
                    // joined string as a key would expose "%@ · %@" to translators.
                    Text(verbatim: "\(String(localized: .init(legalCase.area.labelKey))) · \(legalCase.courtShort)")
                        .font(Theme.font(10.5))
                        .kerning(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    // One date per card. The hearing is the anchor the client
                    // recognises; the confirmation deadline that precedes it goes
                    // in the next-step line, where it can be labelled.
                    if let pillDate, state == .requiresYou {
                        StatePill(Format.weekdayDate(pillDate), tone: .critical)
                    } else {
                        StatePill(state: state)
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

                if let next = nextStepText {
                    Divider().overlay(Theme.line).padding(.vertical, 9)
                    Text(next)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.body)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
    }

    /// Date shown in the pill. Prefers the hearing, so the pill and the
    /// next-step line can never disagree about which date they mean.
    private var pillDate: Date? {
        if let hearing = legalCase.hearing, !hearing.isConfirmed { return hearing.date }
        return deadline
    }

    private var nextStepText: String? {
        if legalCase.isUnderSeal {
            return String(localized: "case.underSeal.short")
        }
        if let hearing = legalCase.hearing, !hearing.isConfirmed {
            if let confirmBy = deadline, confirmBy < hearing.date {
                return String(localized: "case.next.hearingConfirmBy \(Format.dateTime(hearing.date)) \(Format.date(confirmBy))")
            }
            return String(localized: "case.next.hearing \(Format.dateTime(hearing.date))")
        }
        if let last = legalCase.visibleMovements.first {
            return last.displayHeadline
        }
        return nil
    }
}

// MARK: - Meaning block

/// The translation, shown first and larger than the court's own words. Inverting
/// this order is what every legal portal does — and why nobody uses them.
struct MeaningBlock: View {
    let translation: String
    var reassuranceKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("movement.meaning.label")
                .font(Theme.font(10.5, weight: .semibold))
                .kerning(1.3)
                .textCase(.uppercase)
                .foregroundStyle(Theme.muted)
                .padding(.bottom, 8)

            Text(translation)
                .font(Theme.font(15))
                .foregroundStyle(Theme.body)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let reassuranceKey {
                Label {
                    Text(LocalizedStringKey(reassuranceKey))
                        .font(Theme.font(12.5, weight: .semibold))
                } icon: {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Theme.onTrack)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.onTrack.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
                .padding(.top, 12)
            }
        }
        .padding(Theme.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.primary).frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
    }
}

// MARK: - Key/value row

struct KeyValueRow: View {
    let label: LocalizedStringKey
    let value: String
    var isMono = false
    var tint: Color?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .font(Theme.font(13))
                .foregroundStyle(Theme.muted)
            Spacer(minLength: 8)
            Text(value)
                .font(isMono ? Theme.mono(13, weight: .semibold) : Theme.font(13.5, weight: .semibold))
                .foregroundStyle(tint ?? Theme.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }
}

// MARK: - List row

struct AppListRow: View {
    let title: String
    var subtitle: String?
    var systemImage: String
    var iconTone: StatePill.Tone = .neutral
    var isMonoSubtitle = false
    var trailingPill: (text: String, tone: StatePill.Tone)?
    var showsChevron = true

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(iconTone == .neutral ? Theme.primary : iconTone.foreground)
                .frame(width: 38, height: 38)
                .background(
                    iconTone == .neutral ? Theme.fill : iconTone.foreground.opacity(0.13),
                    in: RoundedRectangle(cornerRadius: 10)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.font(15, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(isMonoSubtitle ? Theme.mono(12) : Theme.font(12.5))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let trailingPill {
                StatePill(trailingPill.text, tone: trailingPill.tone)
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.line)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .frame(minHeight: Theme.minTouchTarget + 12)
        .contentShape(.rect)
    }
}

/// Groups rows into one white card with hairlines between them.
struct RowCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
    }
}

struct RowDivider: View {
    var body: some View {
        Rectangle().fill(Theme.line).frame(height: 1).padding(.leading, 66)
    }
}

// MARK: - Form field

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
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.line, lineWidth: 1))
    }
}

// MARK: - Timeline

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
                    .overlay(Circle().stroke(dotColor, lineWidth: 2.5))
                    .frame(width: 11, height: 11)
                    .padding(.top, 5)
            }
            .frame(width: 11)

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

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let systemImage: String
    let title: LocalizedStringKey
    var message: LocalizedStringKey?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.muted.opacity(0.6))
            Text(title)
                .font(Theme.font(16, weight: .semibold))
                .foregroundStyle(Theme.primary)
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
    }
}

// MARK: - WhatsApp exit

/// The only way out of the app to the firm. Rendered as a secondary action
/// everywhere it appears, and it always carries context in the message it opens.
struct WhatsAppButton: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    let context: WhatsAppLink.Context
    var caseID: UUID?
    var titleKey: LocalizedStringKey = "wa.button"

    var body: some View {
        Button {
            if let url = appState.whatsAppURL(context, caseID: caseID) { openURL(url) }
        } label: {
            Label {
                Text(titleKey)
            } icon: {
                Image(systemName: "bubble.left.and.text.bubble.right")
            }
        }
        .buttonStyle(WhatsAppButtonStyle())
    }
}
