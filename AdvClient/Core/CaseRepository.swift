import Foundation

/// Everything the signed-in company can see, fetched in one round trip.
///
/// One snapshot rather than four endpoints because every screen mixes the
/// collections — the dashboard needs cases *and* documents *and* pendencies to
/// decide what goes in "Exige você".
struct ClientSnapshot: Sendable, Equatable {
    var cases: [LegalCase]
    var documents: [ClientDocument]
    var pendencies: [Pendency]
    var invoices: [Invoice]
    /// When the court data behind this snapshot was last refreshed. Shown to the
    /// client verbatim — the app must never imply it is fresher than it is.
    var lastSyncedAt: Date

    static let empty = ClientSnapshot(cases: [], documents: [], pendencies: [], invoices: [], lastSyncedAt: .distantPast)
}

/// The UI only ever talks to this protocol. Swapping in an API-backed
/// implementation — DataJud for the backlog, a paid aggregator with webhooks for
/// active cases — should not require touching a single view.
protocol ClientDataRepository: Sendable {
    func snapshot(for companyID: UUID) async throws -> ClientSnapshot
    func confirmHearing(caseID: UUID) async throws -> ClientSnapshot
    func resolvePendency(id: UUID) async throws -> ClientSnapshot
    func upload(fileName: String, caseID: UUID?) async throws -> ClientSnapshot
    /// Records that the client left for WhatsApp from a given case. Only the
    /// trail — who, which case, when — never the content of the conversation.
    func recordWhatsAppHandoff(caseID: UUID?) async
}

/// In-memory implementation seeded from `MockData`.
///
/// An actor because the demo mutates: confirming a hearing has to survive a
/// navigation and show up on the dashboard, the way the real thing will.
actor MockClientRepository: ClientDataRepository {

    private var cases: [LegalCase]
    private var documents: [ClientDocument]
    private var pendencies: [Pendency]
    private var invoices: [Invoice]
    private var handoffs: [(caseID: UUID?, at: Date)] = []

    init() {
        cases = MockData.cases
        documents = MockData.documents
        pendencies = MockData.pendencies
        invoices = MockData.invoices
    }

    /// Test seam: build a repository over a specific dataset.
    init(cases: [LegalCase], documents: [ClientDocument], pendencies: [Pendency], invoices: [Invoice] = []) {
        self.cases = cases
        self.documents = documents
        self.pendencies = pendencies
        self.invoices = invoices
    }

    private var current: ClientSnapshot {
        ClientSnapshot(
            cases: cases,
            documents: documents,
            pendencies: pendencies,
            invoices: invoices,
            // Courts publish in batches, so the app reports a morning sync rather
            // than implying a live feed it does not have.
            lastSyncedAt: Rules.calendar.date(bySettingHour: 8, minute: 30, second: 0, of: .now) ?? .now
        )
    }

    func snapshot(for companyID: UUID) async throws -> ClientSnapshot {
        try? await Task.sleep(for: .milliseconds(400))
        return current
    }

    func confirmHearing(caseID: UUID) async throws -> ClientSnapshot {
        try? await Task.sleep(for: .milliseconds(350))
        guard let index = cases.firstIndex(where: { $0.id == caseID }) else { return current }
        cases[index].hearing?.confirmedAt = .now
        // Confirming clears the pendency that put the case in "Exige você".
        for (i, pendency) in pendencies.enumerated()
        where pendency.caseID == caseID && pendency.kind == .hearing && !pendency.isResolved {
            pendencies[i].resolvedAt = .now
        }
        return current
    }

    func resolvePendency(id: UUID) async throws -> ClientSnapshot {
        try? await Task.sleep(for: .milliseconds(250))
        if let index = pendencies.firstIndex(where: { $0.id == id }) {
            pendencies[index].resolvedAt = .now
        }
        return current
    }

    func upload(fileName: String, caseID: UUID?) async throws -> ClientSnapshot {
        try? await Task.sleep(for: .milliseconds(600))
        documents.insert(
            ClientDocument(
                id: UUID(),
                title: fileName,
                kind: caseID == nil ? .corporate : .procedural,
                caseID: caseID,
                counterparty: nil,
                effectiveFrom: nil,
                expiresAt: nil,
                noticeDeadline: nil,
                autoRenews: false,
                monthlyValue: nil,
                version: 1,
                attentionPoints: [],
                uploadedByClient: true,
                uploadedAt: .now,
                archivedAt: nil
            ),
            at: 0
        )
        return current
    }

    func recordWhatsAppHandoff(caseID: UUID?) async {
        handoffs.append((caseID, .now))
    }

    var handoffCount: Int { handoffs.count }
}
