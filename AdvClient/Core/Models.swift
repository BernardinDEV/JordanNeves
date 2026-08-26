import Foundation

// MARK: - Client company (empresa)

/// The app's tenant. Every case, document and pendency belongs to one company —
/// the isolation boundary that the backend will enforce with row-level security.
struct Company: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var legalName: String
    var tradeName: String
    var cnpj: String
    /// E-mail of the person currently signed in on this device.
    var userEmail: String

    var initials: String {
        tradeName.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
}

// MARK: - Practice area

enum PracticeArea: String, Codable, CaseIterable, Sendable {
    case labor
    case tax
    case civil
    case corporate
    case contracts

    var labelKey: String {
        switch self {
        case .labor: "case.area.labor"
        case .tax: "case.area.tax"
        case .civil: "case.area.civil"
        case .corporate: "case.area.corporate"
        case .contracts: "case.area.contracts"
        }
    }

    var systemImage: String {
        switch self {
        case .labor: "person.2.badge.gearshape"
        case .tax: "percent"
        case .civil: "building.columns"
        case .corporate: "chart.pie"
        case .contracts: "doc.text"
        }
    }
}

// MARK: - Case movement (andamento)

/// A single movement pulled from the court. The two fields that make the whole
/// product work are `translation` and `requiresClient`: nothing reaches the
/// client without a human having written the first and decided the second.
/// See `Rules.isPublished(_:)` — the app never renders an unpublished movement.
struct CaseMovement: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var date: Date
    /// Raw text exactly as the court published it.
    var officialText: String
    /// One-line summary in plain Portuguese — what the timeline shows and what
    /// headlines the detail screen. Falls back to `translation` when absent.
    var headline: String?
    /// The fuller explanation of what the movement means for this company.
    /// `nil` until someone at the firm writes it.
    var translation: String?
    /// Whether the client has to do something about this movement.
    var requiresClient: Bool
    /// Who at the firm approved the translation. `nil` until approved.
    var approvedBy: String?
    var approvedAt: Date?
    /// Set when the movement became visible to the client.
    var publishedAt: Date?
    /// Short reassurance shown under the translation, e.g. "Nada a fazer da sua parte".
    var reassuranceKey: String?

    /// What to show as the title of this movement anywhere in the UI.
    var displayHeadline: String {
        if let headline, !headline.isEmpty { return headline }
        return translation ?? ""
    }

    init(
        id: UUID,
        date: Date,
        officialText: String,
        headline: String? = nil,
        translation: String? = nil,
        requiresClient: Bool = false,
        approvedBy: String? = nil,
        approvedAt: Date? = nil,
        publishedAt: Date? = nil,
        reassuranceKey: String? = nil
    ) {
        self.id = id
        self.date = date
        self.officialText = officialText
        self.headline = headline
        self.translation = translation
        self.requiresClient = requiresClient
        self.approvedBy = approvedBy
        self.approvedAt = approvedAt
        self.publishedAt = publishedAt
        self.reassuranceKey = reassuranceKey
    }
}

// MARK: - Risk

enum RiskLevel: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high

    var labelKey: String {
        switch self {
        case .low: "case.risk.low"
        case .medium: "case.risk.medium"
        case .high: "case.risk.high"
        }
    }
}

// MARK: - Hearing (audiência)

struct ChecklistItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var text: String
    var isChecked: Bool
}

struct Hearing: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var date: Date
    var venue: String
    var address: String
    /// Who from the company must attend, in plain words.
    var whoMustAttend: String
    var checklist: [ChecklistItem]
    var confirmedAt: Date?

    var isConfirmed: Bool { confirmedAt != nil }
}

// MARK: - Legal case (processo)

struct LegalCase: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    /// CNJ-standard number, digits only or formatted — see `CNJNumber`.
    var number: String
    var title: String
    var area: PracticeArea
    var court: String
    /// Short court label shown on cards, e.g. "TRT-17".
    var courtShort: String
    /// Cases under seal never receive automated movements — no public source
    /// exposes them. The UI has to say so instead of looking idle.
    var isUnderSeal: Bool
    var opposingParty: String
    var claimValue: Decimal
    var risk: RiskLevel
    var provision: Decimal?
    var responsibleLawyer: String
    var openedAt: Date
    var closedAt: Date?
    var movements: [CaseMovement]
    var hearing: Hearing?

    var isOpen: Bool { closedAt == nil }

    /// Only movements the client is allowed to see, newest first.
    var visibleMovements: [CaseMovement] {
        movements.filter(Rules.isPublished).sorted { $0.date > $1.date }
    }

    var lastVisibleUpdate: Date {
        visibleMovements.first?.date ?? openedAt
    }
}

// MARK: - Documents and contracts

enum DocumentKind: String, Codable, CaseIterable, Sendable {
    case contract
    case procedural
    case corporate

    var labelKey: String {
        switch self {
        case .contract: "docs.kind.contract"
        case .procedural: "docs.kind.procedural"
        case .corporate: "docs.kind.corporate"
        }
    }
}

/// A clause the firm flagged while reviewing the contract. This is the value the
/// client is paying for — a lawyer already read the PDF and marked what matters.
struct AttentionPoint: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var clause: String
    var title: String
    var detail: String
    var isWarning: Bool
}

struct ClientDocument: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var kind: DocumentKind
    var caseID: UUID?
    var counterparty: String?
    var effectiveFrom: Date?
    /// The date the contract lapses.
    var expiresAt: Date?
    /// Deadline to give notice when the contract renews automatically. This is
    /// the date that actually forces a decision, and it always comes first.
    var noticeDeadline: Date?
    var autoRenews: Bool
    var monthlyValue: Decimal?
    var version: Int
    var attentionPoints: [AttentionPoint]
    var uploadedByClient: Bool
    var uploadedAt: Date
    /// Documents are never deleted by the client, only archived — the history
    /// has to survive to be usable as evidence in a contractual dispute.
    var archivedAt: Date?

    var isArchived: Bool { archivedAt != nil }

    /// The date that drives every alert: notice deadline when there is one,
    /// otherwise plain expiry.
    var effectiveDeadline: Date? { noticeDeadline ?? expiresAt }
}

// MARK: - Pendency ("Exige você")

enum PendencyKind: String, Codable, CaseIterable, Sendable {
    case hearing
    case contractDecision
    case documentRequest

    var systemImage: String {
        switch self {
        case .hearing: "calendar"
        case .contractDecision: "doc.text"
        case .documentRequest: "arrow.up.doc"
        }
    }
}

/// The single source of "Exige você" across the whole app. The dashboard,
/// the notification list and the documents screen all read from here, so the
/// rule lives in one place instead of being reimplemented three times.
struct Pendency: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var kind: PendencyKind
    var title: String
    var detail: String
    var dueDate: Date
    var caseID: UUID?
    var documentID: UUID?
    var resolvedAt: Date?

    var isResolved: Bool { resolvedAt != nil }
}

// MARK: - Invoice (honorários)

struct Invoice: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var reference: String
    var amount: Decimal
    var dueDate: Date
    var paidAt: Date?

    var isPaid: Bool { paidAt != nil }
}
