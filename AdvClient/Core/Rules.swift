import Foundation

// MARK: - Urgency

/// How close a deadline is. Drives colour, badge text and ordering everywhere
/// in the app. Never expressed by colour alone — every use pairs it with words.
enum Urgency: String, Sendable, CaseIterable, Comparable {
    /// Deadline is today or already past.
    case critical
    /// Seven days or fewer.
    case warning
    /// More than seven days away.
    case normal

    private var rank: Int {
        switch self {
        case .critical: 2
        case .warning: 1
        case .normal: 0
        }
    }

    static func < (lhs: Urgency, rhs: Urgency) -> Bool { lhs.rank < rhs.rank }
}

/// Where a case stands, from the client's point of view. Derived — never stored,
/// so it can't drift out of sync with the underlying pendencies.
enum CaseState: String, Sendable, Equatable {
    /// Something is waiting on the client.
    case requiresYou
    /// A deadline is near but the firm is handling it.
    case deadlineNear
    /// Waiting on the court; nobody at the firm or the company can speed it up.
    case withCourt
    /// Nothing pending.
    case onTrack

    var labelKey: String {
        switch self {
        case .requiresYou: "state.requiresYou"
        case .deadlineNear: "state.deadlineNear"
        case .withCourt: "state.withCourt"
        case .onTrack: "state.onTrack"
        }
    }
}

/// Escalation step for a contract approaching its deadline. The interface's
/// urgency tracks the real urgency: it never shouts before it has to.
enum ContractAlert: String, Sendable, Equatable {
    /// 60 days out — quiet amber badge in the list, nothing more.
    case watch
    /// 30 days out — promoted to "Precisa de você".
    case decide
    /// 7 days out — earns a push notification.
    case urgent

    var urgency: Urgency {
        switch self {
        case .watch: .normal
        case .decide: .warning
        case .urgent: .critical
        }
    }
}

/// Snapshot of the whole portfolio, used by the dashboard's position bar.
struct PortfolioPosition: Equatable, Sendable {
    var requiresYou: Int
    var deadlineNear: Int
    var onTrack: Int

    var total: Int { requiresYou + deadlineNear + onTrack }
    var isEmpty: Bool { total == 0 }

    /// Share of the bar for each segment, in the order the bar draws them.
    /// Returns zeros when there is nothing to show, so the caller can hide the bar.
    var fractions: (requiresYou: Double, deadlineNear: Double, onTrack: Double) {
        guard total > 0 else { return (0, 0, 0) }
        let t = Double(total)
        return (Double(requiresYou) / t, Double(deadlineNear) / t, Double(onTrack) / t)
    }
}

// MARK: - Rules

/// Every product rule the interface depends on, as pure functions over a given
/// `now`. Keeping them here — rather than inside views — is what makes them
/// testable and keeps the dashboard, the notification list and the documents
/// screen from each inventing their own version of "urgent".
enum Rules {

    /// Calendar used for all day arithmetic. Deadlines are whole days in the
    /// client's own timezone: "tomorrow 9am" seen at "today 11pm" is 1 day away,
    /// not 0, which raw time-interval maths would get wrong.
    static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
        return c
    }()

    /// Whole days from `now` to `date`. Negative once the date has passed.
    static func days(from now: Date, to date: Date, calendar: Calendar = Rules.calendar) -> Int {
        let a = calendar.startOfDay(for: now)
        let b = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// Urgency of a deadline. Today and anything overdue are both critical —
    /// from the client's chair there is no useful difference.
    static func urgency(of deadline: Date, now: Date = .now, calendar: Calendar = Rules.calendar) -> Urgency {
        let remaining = days(from: now, to: deadline, calendar: calendar)
        if remaining <= 0 { return .critical }
        if remaining <= 7 { return .warning }
        return .normal
    }

    // MARK: Publication — the rule the whole product rests on

    /// A movement reaches the client only once someone at the firm has written a
    /// plain-Portuguese translation, decided whether it requires the client, and
    /// approved it. No screen may bypass this: it is the difference between this
    /// app and a court-lookup portal.
    static func isPublished(_ movement: CaseMovement) -> Bool {
        guard let translation = movement.translation,
              !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              movement.approvedBy?.isEmpty == false,
              movement.publishedAt != nil
        else { return false }
        return true
    }

    /// Movements the client may see, newest first.
    static func visibleMovements(_ movements: [CaseMovement]) -> [CaseMovement] {
        movements.filter(isPublished).sorted { $0.date > $1.date }
    }

    // MARK: Notifications

    /// Only movements that require the client earn a push. Everything else piles
    /// up quietly for the weekly digest — notifying every movement is the fastest
    /// way to get the app muted.
    static func shouldPush(_ movement: CaseMovement) -> Bool {
        isPublished(movement) && movement.requiresClient
    }

    /// Caps pushes at one per case per day, keeping the newest. The ceiling
    /// belongs to the backend, not to a user preference: if someone has to switch
    /// notifications off to stop being pestered, the product already failed.
    static func throttledPushes(
        _ movements: [CaseMovement],
        caseID: (CaseMovement) -> UUID,
        calendar: Calendar = Rules.calendar
    ) -> [CaseMovement] {
        let candidates = movements.filter(shouldPush).sorted { $0.date > $1.date }
        var seen = Set<String>()
        var result: [CaseMovement] = []
        for movement in candidates {
            let day = calendar.startOfDay(for: movement.date)
            let key = "\(caseID(movement).uuidString)|\(day.timeIntervalSince1970)"
            if seen.insert(key).inserted { result.append(movement) }
        }
        return result
    }

    // MARK: Contracts

    /// Escalation at 60 / 30 / 7 days before the deadline that actually matters —
    /// the notice deadline when the contract renews automatically, otherwise
    /// expiry. Returns `nil` when the document is archived, has no deadline, or
    /// is still more than 60 days out.
    ///
    /// Past-due contracts stay `.urgent`: the decision became more pressing, not
    /// less, and silently dropping the alert is how a lapsed contract goes unseen.
    static func contractAlert(
        for document: ClientDocument,
        now: Date = .now,
        calendar: Calendar = Rules.calendar
    ) -> ContractAlert? {
        guard !document.isArchived, let deadline = document.effectiveDeadline else { return nil }
        let remaining = days(from: now, to: deadline, calendar: calendar)
        switch remaining {
        case ..<8: return .urgent
        case ..<31: return .decide
        case ..<61: return .watch
        default: return nil
        }
    }

    /// Documents the client has to act on, most urgent first. Feeds the
    /// "Precisa de você" block at the top of the documents screen.
    static func documentsNeedingAttention(
        _ documents: [ClientDocument],
        now: Date = .now,
        calendar: Calendar = Rules.calendar
    ) -> [ClientDocument] {
        documents
            .compactMap { doc -> (ClientDocument, ContractAlert)? in
                guard let alert = contractAlert(for: doc, now: now, calendar: calendar),
                      alert != .watch else { return nil }
                return (doc, alert)
            }
            .sorted { lhs, rhs in
                let l = lhs.0.effectiveDeadline ?? .distantFuture
                let r = rhs.0.effectiveDeadline ?? .distantFuture
                return l < r
            }
            .map(\.0)
    }

    // MARK: Case state

    /// A partir daqui um andamento deixa de ser "o que está acontecendo agora".
    /// É o mesmo corte dos dois lados: o que não é recente está com o tribunal.
    static let staleAfterDays = 30

    /// Where a case stands. Order matters: an open pendency outranks everything,
    /// because it is the only state that asks the client to do something.
    static func state(
        of legalCase: LegalCase,
        pendencies: [Pendency],
        now: Date = .now,
        calendar: Calendar = Rules.calendar
    ) -> CaseState {
        let open = pendencies.filter { $0.caseID == legalCase.id && !$0.isResolved }
        if !open.isEmpty { return .requiresYou }

        if let hearing = legalCase.hearing, !hearing.isConfirmed,
           urgency(of: hearing.date, now: now, calendar: calendar) >= .warning {
            return .requiresYou
        }

        // Recência, não urgência. `urgency(of:)` mede quanto falta para uma data
        // futura; a data de um andamento é sempre passada, então ela devolvia
        // `.critical` para qualquer caso e esta condição virava só
        // `next.requiresClient` — deixando o ramo `.withCourt` inalcançável e
        // marcando como "prazo próximo" processo parado há meses.
        if let next = legalCase.visibleMovements.first,
           next.requiresClient,
           days(from: next.date, to: now, calendar: calendar) <= staleAfterDays {
            return .deadlineNear
        }

        // No movement for a while and nothing pending: the ball is with the court.
        // Sem andamento publicado, vale a data da última movimentação no
        // tribunal, quando a fonte a informa.
        let lastActivity = legalCase.visibleMovements.first?.date ?? legalCase.lastCourtActivity?.date
        if let lastActivity,
           days(from: lastActivity, to: now, calendar: calendar) > staleAfterDays {
            return .withCourt
        }

        return .onTrack
    }

    /// Cases that need the client, most urgent first. Drives the dashboard's
    /// "Exige você" section, which is hidden entirely when this comes back empty.
    static func casesRequiringClient(
        _ cases: [LegalCase],
        pendencies: [Pendency],
        now: Date = .now,
        calendar: Calendar = Rules.calendar
    ) -> [LegalCase] {
        cases
            .filter { $0.isOpen && state(of: $0, pendencies: pendencies, now: now, calendar: calendar) == .requiresYou }
            .sorted { lhs, rhs in
                let l = nextDeadline(for: lhs, pendencies: pendencies) ?? .distantFuture
                let r = nextDeadline(for: rhs, pendencies: pendencies) ?? .distantFuture
                return l < r
            }
    }

    /// Soonest date this case demands attention: an open pendency or an
    /// unconfirmed hearing, whichever lands first.
    static func nextDeadline(for legalCase: LegalCase, pendencies: [Pendency]) -> Date? {
        var dates = pendencies
            .filter { $0.caseID == legalCase.id && !$0.isResolved }
            .map(\.dueDate)
        if let hearing = legalCase.hearing, !hearing.isConfirmed {
            dates.append(hearing.date)
        }
        return dates.min()
    }

    // MARK: Dashboard

    /// Counts for the position bar. Open cases only — closed ones would inflate
    /// the "on track" segment and make the bar useless.
    static func position(
        cases: [LegalCase],
        pendencies: [Pendency],
        now: Date = .now,
        calendar: Calendar = Rules.calendar
    ) -> PortfolioPosition {
        var position = PortfolioPosition(requiresYou: 0, deadlineNear: 0, onTrack: 0)
        for legalCase in cases where legalCase.isOpen {
            switch state(of: legalCase, pendencies: pendencies, now: now, calendar: calendar) {
            case .requiresYou: position.requiresYou += 1
            case .deadlineNear: position.deadlineNear += 1
            case .withCourt, .onTrack: position.onTrack += 1
            }
        }
        return position
    }

    /// Everything waiting on the client, across cases and documents, soonest first.
    static func openPendencies(_ pendencies: [Pendency], now: Date = .now) -> [Pendency] {
        pendencies.filter { !$0.isResolved }.sorted { $0.dueDate < $1.dueDate }
    }
}
