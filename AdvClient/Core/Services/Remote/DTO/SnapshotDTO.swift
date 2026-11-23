import Foundation

/// Resposta de `GET /v1/snapshot` e das ações que devolvem o snapshot.
///
/// Tipo de fio, separado do domínio de propósito: o JSON pode ganhar campo, e
/// enumerações podem ganhar valor, sem que o app instalado quebre. Por isso as
/// enumerações chegam como `String` e o mapeamento (`SnapshotDTO+Domain`)
/// decide o que fazer com um valor desconhecido. Dinheiro chega como texto
/// decimal (`"84200.00"`), nunca número de ponto flutuante.
struct SnapshotDTO: Decodable, Sendable {
    let syncedAt: Date
    let cases: LossyList<Case>
    let documents: LossyList<Document>
    let pendencies: LossyList<Pendency>
    let invoices: LossyList<Invoice>
    /// Ausente vale "tudo ligado".
    let capabilities: Capabilities?

    struct Case: Decodable, Sendable {
        let id: UUID
        let number: String
        let title: String
        let area: String
        let court: String
        let courtShort: String
        let underSeal: Bool
        let opposingParty: String
        let claimValue: String
        let risk: String?
        let provision: String?
        let responsibleLawyer: String
        let openedAt: Date
        let closedAt: Date?
        let movements: LossyList<Movement>
        let hearing: Hearing?
    }

    /// O servidor só deveria mandar andamento publicado. O app confere de novo
    /// com `Rules.isPublished`: a regra é do produto, não do servidor.
    struct Movement: Decodable, Sendable {
        let id: UUID
        let date: Date
        let officialText: String
        let headline: String?
        let translation: String?
        let requiresClient: Bool
        let approvedBy: String?
        let approvedAt: Date?
        let publishedAt: Date?
    }

    struct Hearing: Decodable, Sendable {
        let id: UUID
        let date: Date
        let venue: String
        let address: String
        let whoMustAttend: String
        let checklist: [ChecklistItem]
        let confirmedAt: Date?
    }

    struct ChecklistItem: Decodable, Sendable {
        let id: UUID
        let text: String
        let checked: Bool
    }

    struct Document: Decodable, Sendable {
        let id: UUID
        let title: String
        let kind: String
        let caseId: UUID?
        let counterparty: String?
        let effectiveFrom: Date?
        let expiresAt: Date?
        let noticeDeadline: Date?
        let autoRenews: Bool
        let monthlyValue: String?
        let version: Int
        let attentionPoints: [AttentionPoint]
        let uploadedByClient: Bool
        let uploadedAt: Date
        let archivedAt: Date?
    }

    struct AttentionPoint: Decodable, Sendable {
        let id: UUID
        let clause: String
        let title: String
        let detail: String
        let warning: Bool
    }

    struct Pendency: Decodable, Sendable {
        let id: UUID
        let kind: String
        let title: String
        let detail: String
        let dueDate: Date
        let caseId: UUID?
        let documentId: UUID?
        let resolvedAt: Date?
    }

    struct Invoice: Decodable, Sendable {
        let id: UUID
        let reference: String
        let amount: String
        let dueDate: Date
        let paidAt: Date?
    }

    struct Capabilities: Decodable, Sendable {
        let documents: Bool
        let uploads: Bool
    }
}
