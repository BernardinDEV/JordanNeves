import Foundation

/// Tudo o que as telas derivam de um `ClientSnapshot`, calculado **uma vez**
/// por snapshot.
///
/// Antes, cada uma destas listas era uma propriedade computada do `AppState`:
/// filtrava, ordenava e reaplicava as regras a cada leitura. O painel lia
/// `casesRequiringClient` três vezes por atualização, a lista de casos chamava
/// `state(of:)` dentro do comparador da ordenação, e cada chamada refazia o
/// filtro de andamentos publicados. Com poucos casos não se nota; com a
/// carteira de uma empresa de verdade, é trabalho repetido a cada toque.
///
/// As regras continuam em `Rules` — aqui só se guarda o resultado. O índice
/// depende do relógio (prazos, recência), então o `AppState` o refaz quando o
/// snapshot muda **e** quando o app volta ao primeiro plano.
struct PortfolioIndex: Equatable, Sendable {

    // MARK: Casos

    private(set) var openCases: [LegalCase] = []
    private(set) var closedCases: [LegalCase] = []
    /// As três listas da tela de casos, já na ordem em que aparecem: o mais
    /// urgente primeiro, e dentro do mesmo estado o de movimento mais recente.
    private(set) var openCasesByUrgency: [LegalCase] = []
    private(set) var closedCasesByUrgency: [LegalCase] = []
    private(set) var allCasesByUrgency: [LegalCase] = []
    /// "Exige você", prazo mais próximo primeiro.
    private(set) var casesRequiringClient: [LegalCase] = []
    /// Casos ativos que **não** estão em "Exige você" — o painel não repete.
    private(set) var otherOpenCases: [LegalCase] = []
    private(set) var position = PortfolioPosition(requiresYou: 0, deadlineNear: 0, onTrack: 0)

    private var states: [UUID: CaseState] = [:]
    private var deadlines: [UUID: Date] = [:]
    private var casesByID: [UUID: LegalCase] = [:]

    // MARK: Documentos

    /// Não arquivados.
    private(set) var documents: [ClientDocument] = []
    private(set) var contracts: [ClientDocument] = []
    private(set) var documentsNeedingAttention: [ClientDocument] = []

    private var contractAlerts: [UUID: ContractAlert] = [:]
    private var documentsByID: [UUID: ClientDocument] = [:]

    // MARK: Pendências e avisos

    private(set) var openPendencies: [Pendency] = []
    /// "Para saber": publicados, sem ação do cliente, os oito mais recentes.
    private(set) var informationalMovements: [MovementReference] = []
    /// Andamentos informativos dos últimos 14 dias — o que conta para o selo
    /// do sino enquanto o cliente não abriu.
    private(set) var recentInformationalMovementIDs: Set<UUID> = []

    // MARK: Honorários

    private(set) var nextInvoice: Invoice?

    static let empty = PortfolioIndex()

    /// Por quantos dias um andamento informativo conta como "não lido".
    static let unreadWindowDays = 14
    static let informationalLimit = 8

    private init() {}

    init(snapshot: ClientSnapshot, now: Date = .now, calendar: Calendar = Rules.calendar) {
        let pendencies = snapshot.pendencies

        // Casos — estado, prazo e última atualização saem uma vez por caso.
        var lastUpdate: [UUID: Date] = [:]
        var informational: [MovementReference] = []

        for legalCase in snapshot.cases {
            casesByID[legalCase.id] = legalCase
            states[legalCase.id] = Rules.state(of: legalCase, pendencies: pendencies, now: now, calendar: calendar)
            deadlines[legalCase.id] = Rules.nextDeadline(for: legalCase, pendencies: pendencies)

            let visible = legalCase.visibleMovements
            lastUpdate[legalCase.id] = visible.first?.date ?? legalCase.lastCourtActivity?.date ?? legalCase.openedAt
            for movement in visible where !movement.requiresClient {
                informational.append(MovementReference(movement: movement, legalCase: legalCase))
                if Rules.days(from: movement.date, to: now, calendar: calendar) <= Self.unreadWindowDays {
                    recentInformationalMovementIDs.insert(movement.id)
                }
            }
        }

        openCases = snapshot.cases.filter(\.isOpen)
        closedCases = snapshot.cases.filter { !$0.isOpen }

        let states = states
        let byUrgency: (LegalCase, LegalCase) -> Bool = { lhs, rhs in
            let l = Self.sortRank(states[lhs.id] ?? .onTrack)
            let r = Self.sortRank(states[rhs.id] ?? .onTrack)
            if l != r { return l < r }
            return (lastUpdate[lhs.id] ?? .distantPast) > (lastUpdate[rhs.id] ?? .distantPast)
        }
        openCasesByUrgency = openCases.sorted(by: byUrgency)
        closedCasesByUrgency = closedCases.sorted(by: byUrgency)
        allCasesByUrgency = snapshot.cases.sorted(by: byUrgency)

        casesRequiringClient = Rules.casesRequiringClient(
            snapshot.cases, pendencies: pendencies, now: now, calendar: calendar
        )
        let urgent = Set(casesRequiringClient.map(\.id))
        otherOpenCases = openCases.filter { !urgent.contains($0.id) }
        position = Rules.position(cases: snapshot.cases, pendencies: pendencies, now: now, calendar: calendar)

        // Documentos
        for document in snapshot.documents {
            documentsByID[document.id] = document
            contractAlerts[document.id] = Rules.contractAlert(for: document, now: now, calendar: calendar)
        }
        documents = snapshot.documents.filter { !$0.isArchived }
        contracts = documents.filter { $0.kind == .contract }
        documentsNeedingAttention = Rules.documentsNeedingAttention(snapshot.documents, now: now, calendar: calendar)

        // Pendências e avisos
        openPendencies = Rules.openPendencies(pendencies, now: now)
        informationalMovements = Array(
            informational
                .sorted { $0.movement.date > $1.movement.date }
                .prefix(Self.informationalLimit)
        )

        nextInvoice = snapshot.invoices.filter { !$0.isPaid }.min { $0.dueDate < $1.dueDate }
    }

    // MARK: Consultas

    func state(of legalCase: LegalCase) -> CaseState {
        states[legalCase.id] ?? .onTrack
    }

    func nextDeadline(for legalCase: LegalCase) -> Date? {
        deadlines[legalCase.id]
    }

    func contractAlert(for document: ClientDocument) -> ContractAlert? {
        contractAlerts[document.id]
    }

    func legalCase(id: UUID?) -> LegalCase? {
        id.flatMap { casesByID[$0] }
    }

    /// Inclui arquivados: um link antigo para um documento arquivado ainda abre.
    func document(id: UUID?) -> ClientDocument? {
        id.flatMap { documentsByID[$0] }
    }

    /// Quantos avisos o cliente ainda não viu: toda pendência aberta, mais os
    /// andamentos informativos recentes que ele não abriu.
    func unreadCount(excluding readMovementIDs: Set<UUID>) -> Int {
        openPendencies.count + recentInformationalMovementIDs.subtracting(readMovementIDs).count
    }

    /// Ordem da lista de casos: o que pede o cliente vem antes do que está com
    /// o tribunal.
    static func sortRank(_ state: CaseState) -> Int {
        switch state {
        case .requiresYou: 0
        case .deadlineNear: 1
        case .onTrack: 2
        case .withCourt: 3
        }
    }
}
