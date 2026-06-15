import Foundation

// MARK: - Client

struct Client: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var cpf: String
    var email: String
    var phone: String

    var initials: String {
        name.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
}

// MARK: - Legal case (processo)

enum CaseStatus: String, Codable, CaseIterable {
    case active
    case awaitingDecision
    case appeal
    case settled
    case closed

    /// String Catalog key
    var labelKey: String {
        switch self {
        case .active: "case.status.active"
        case .awaitingDecision: "case.status.awaitingDecision"
        case .appeal: "case.status.appeal"
        case .settled: "case.status.settled"
        case .closed: "case.status.closed"
        }
    }

    var isOpen: Bool {
        switch self {
        case .settled, .closed: false
        default: true
        }
    }
}

enum PracticeArea: String, Codable, CaseIterable {
    case labor
    case civil
    case socialSecurity
    case corporate
    case family

    var labelKey: String {
        switch self {
        case .labor: "case.area.labor"
        case .civil: "case.area.civil"
        case .socialSecurity: "case.area.socialSecurity"
        case .corporate: "case.area.corporate"
        case .family: "case.area.family"
        }
    }

    var systemImage: String {
        switch self {
        case .labor: "briefcase.fill"
        case .civil: "building.columns.fill"
        case .socialSecurity: "shield.fill"
        case .corporate: "chart.bar.fill"
        case .family: "person.2.fill"
        }
    }
}

struct CaseMovement: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var titleKey: String
    var detailKey: String
}

struct LegalCase: Identifiable, Codable, Hashable {
    let id: UUID
    /// CNJ-standard case number
    var number: String
    var titleKey: String
    var area: PracticeArea
    var status: CaseStatus
    var court: String
    var responsibleLawyer: String
    var openedAt: Date
    var movements: [CaseMovement]

    var lastUpdate: Date {
        movements.map(\.date).max() ?? openedAt
    }
}
