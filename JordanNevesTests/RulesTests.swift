import Foundation
import Testing
@testable import JordanNeves

/// Fixed calendar and reference date so nothing here depends on when the suite runs.
private let calendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    return c
}()

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

/// A Wednesday, mid-afternoon.
private let now = date(2026, 7, 22, hour: 15)

private func movement(
    date movementDate: Date = date(2026, 7, 20),
    translation: String? = "Tradução.",
    requiresClient: Bool = false,
    approvedBy: String? = "Jordan Neves",
    publishedAt: Date? = date(2026, 7, 20)
) -> CaseMovement {
    CaseMovement(
        id: UUID(),
        date: movementDate,
        officialText: "Texto oficial do tribunal.",
        translation: translation,
        requiresClient: requiresClient,
        approvedBy: approvedBy,
        approvedAt: publishedAt,
        publishedAt: publishedAt
    )
}

private func legalCase(
    id: UUID = UUID(),
    movements: [CaseMovement] = [],
    hearing: Hearing? = nil,
    closedAt: Date? = nil
) -> LegalCase {
    LegalCase(
        id: id,
        number: "0012345-16.2025.5.17.0004",
        title: "Caso de teste",
        area: .labor,
        court: "4ª Vara do Trabalho",
        courtShort: "TRT-17",
        isUnderSeal: false,
        opposingParty: "Parte",
        claimValue: 1000,
        risk: .medium,
        provision: nil,
        responsibleLawyer: "Jordan Neves",
        openedAt: date(2025, 1, 10),
        closedAt: closedAt,
        movements: movements,
        hearing: hearing
    )
}

private func hearing(on hearingDate: Date, confirmed: Bool = false) -> Hearing {
    Hearing(
        id: UUID(),
        date: hearingDate,
        venue: "Fórum",
        address: "Rua X, 1",
        whoMustAttend: "Representante",
        checklist: [],
        confirmedAt: confirmed ? date(2026, 7, 21) : nil
    )
}

private func document(
    expiresAt: Date? = nil,
    noticeDeadline: Date? = nil,
    autoRenews: Bool = false,
    archivedAt: Date? = nil
) -> ClientDocument {
    ClientDocument(
        id: UUID(),
        title: "Contrato de teste",
        kind: .contract,
        caseID: nil,
        counterparty: "Contraparte",
        effectiveFrom: date(2025, 1, 1),
        expiresAt: expiresAt,
        noticeDeadline: noticeDeadline,
        autoRenews: autoRenews,
        monthlyValue: 1000,
        version: 1,
        attentionPoints: [],
        uploadedByClient: false,
        uploadedAt: date(2025, 1, 1),
        archivedAt: archivedAt
    )
}

// MARK: - Publication

/// The rule the whole product rests on: nothing reaches the client without a
/// human translation *and* an approval. If these ever pass while a field is
/// missing, the app has silently become a court-lookup portal.
@Suite("Publicação de andamentos")
struct PublicationTests {

    @Test("Publica quando tem tradução, aprovação e data de publicação")
    func publishesWhenComplete() {
        #expect(Rules.isPublished(movement()))
    }

    @Test("Não publica sem tradução")
    func blocksWithoutTranslation() {
        #expect(!Rules.isPublished(movement(translation: nil)))
    }

    @Test("Não publica com tradução só de espaços em branco")
    func blocksWhitespaceTranslation() {
        #expect(!Rules.isPublished(movement(translation: "   \n  ")))
    }

    @Test("Não publica sem aprovação humana registrada")
    func blocksWithoutApproval() {
        #expect(!Rules.isPublished(movement(approvedBy: nil)))
        #expect(!Rules.isPublished(movement(approvedBy: "")))
    }

    @Test("Não publica sem data de publicação")
    func blocksWithoutPublishDate() {
        #expect(!Rules.isPublished(movement(publishedAt: nil)))
    }

    @Test("Lista visível filtra os não publicados e ordena do mais novo ao mais antigo")
    func visibleMovementsFilterAndSort() {
        let older = movement(date: date(2026, 5, 1))
        let newer = movement(date: date(2026, 7, 1))
        let hidden = movement(date: date(2026, 7, 15), translation: nil, publishedAt: nil)

        let visible = Rules.visibleMovements([older, hidden, newer])

        #expect(visible.count == 2)
        #expect(visible.first?.id == newer.id)
        #expect(!visible.contains { $0.id == hidden.id })
    }

    @Test("Caso expõe apenas movimentos publicados")
    func caseHidesUnpublished() {
        let subject = legalCase(movements: [movement(), movement(translation: nil, publishedAt: nil)])
        #expect(subject.visibleMovements.count == 1)
    }
}

// MARK: - Push

@Suite("Regra de notificação")
struct PushTests {

    @Test("Só 'exige o cliente' gera aviso no aparelho")
    func onlyRequiresClientPushes() {
        #expect(Rules.shouldPush(movement(requiresClient: true)))
        #expect(!Rules.shouldPush(movement(requiresClient: false)))
    }

    @Test("Movimento não publicado nunca notifica, mesmo exigindo o cliente")
    func unpublishedNeverPushes() {
        #expect(!Rules.shouldPush(movement(translation: nil, requiresClient: true, publishedAt: nil)))
    }

    @Test("Teto de um aviso por caso por dia, mantendo o mais recente")
    func throttlesToOnePerCasePerDay() {
        let caseA = UUID(), caseB = UUID()
        let morning = movement(date: date(2026, 7, 20, hour: 9), requiresClient: true)
        let evening = movement(date: date(2026, 7, 20, hour: 18), requiresClient: true)
        let nextDay = movement(date: date(2026, 7, 21, hour: 9), requiresClient: true)
        let other = movement(date: date(2026, 7, 20, hour: 11), requiresClient: true)

        let owners = [morning.id: caseA, evening.id: caseA, nextDay.id: caseA, other.id: caseB]
        let result = Rules.throttledPushes(
            [morning, evening, nextDay, other],
            caseID: { owners[$0.id]! },
            calendar: calendar
        )

        // Two days for case A plus one for case B; the evening one wins its day.
        #expect(result.count == 3)
        #expect(result.contains { $0.id == evening.id })
        #expect(!result.contains { $0.id == morning.id })
        #expect(result.contains { $0.id == other.id })
    }
}

// MARK: - Deadlines

@Suite("Urgência de prazo")
struct UrgencyTests {

    @Test("Hoje é crítico, mesmo faltando horas")
    func todayIsCritical() {
        #expect(Rules.urgency(of: date(2026, 7, 22, hour: 23), now: now, calendar: calendar) == .critical)
    }

    @Test("Vencido é crítico")
    func overdueIsCritical() {
        #expect(Rules.urgency(of: date(2026, 7, 10), now: now, calendar: calendar) == .critical)
    }

    @Test("Até sete dias é atenção", arguments: [1, 3, 7])
    func withinSevenDaysIsWarning(days: Int) {
        let deadline = calendar.date(byAdding: .day, value: days, to: now)!
        #expect(Rules.urgency(of: deadline, now: now, calendar: calendar) == .warning)
    }

    @Test("Oito dias ou mais é normal")
    func beyondSevenDaysIsNormal() {
        let deadline = calendar.date(byAdding: .day, value: 8, to: now)!
        #expect(Rules.urgency(of: deadline, now: now, calendar: calendar) == .normal)
    }

    /// Raw time-interval arithmetic gets this wrong: 10 hours is under a day, but
    /// from the client's chair the deadline is tomorrow.
    @Test("Conta dias de calendário, não intervalo de 24 horas")
    func countsCalendarDays() {
        let lateTonight = date(2026, 7, 22, hour: 23)
        let tomorrowMorning = date(2026, 7, 23, hour: 9)
        #expect(Rules.days(from: lateTonight, to: tomorrowMorning, calendar: calendar) == 1)
    }
}

// MARK: - Contracts

@Suite("Escalonamento de contratos 60/30/7")
struct ContractAlertTests {

    private func alert(daysOut: Int, autoRenews: Bool = false) -> ContractAlert? {
        let deadline = calendar.date(byAdding: .day, value: daysOut, to: now)!
        let doc = autoRenews
            ? document(expiresAt: calendar.date(byAdding: .day, value: 60, to: deadline)!, noticeDeadline: deadline, autoRenews: true)
            : document(expiresAt: deadline)
        return Rules.contractAlert(for: doc, now: now, calendar: calendar)
    }

    @Test("Mais de 60 dias não gera alerta")
    func quietBeyondSixty() {
        #expect(alert(daysOut: 61) == nil)
        #expect(alert(daysOut: 200) == nil)
    }

    @Test("Entre 31 e 60 dias apenas observa")
    func watchBand() {
        #expect(alert(daysOut: 60) == .watch)
        #expect(alert(daysOut: 31) == .watch)
    }

    @Test("Entre 8 e 30 dias pede decisão")
    func decideBand() {
        #expect(alert(daysOut: 30) == .decide)
        #expect(alert(daysOut: 8) == .decide)
    }

    @Test("Sete dias ou menos é urgente")
    func urgentBand() {
        #expect(alert(daysOut: 7) == .urgent)
        #expect(alert(daysOut: 0) == .urgent)
    }

    /// Dropping the alert once the date passes is how a lapsed contract goes unseen.
    @Test("Contrato vencido continua urgente")
    func overdueStaysUrgent() {
        #expect(alert(daysOut: -5) == .urgent)
    }

    @Test("Arquivado não alerta")
    func archivedIsSilent() {
        let doc = document(expiresAt: calendar.date(byAdding: .day, value: 3, to: now)!, archivedAt: now)
        #expect(Rules.contractAlert(for: doc, now: now, calendar: calendar) == nil)
    }

    @Test("Sem prazo não alerta")
    func noDeadlineIsSilent() {
        #expect(Rules.contractAlert(for: document(), now: now, calendar: calendar) == nil)
    }

    /// The notice deadline is the date that actually forces a decision, and it
    /// always lands before expiry. Escalating on expiry would warn too late.
    @Test("Renovação automática escalona pelo aviso prévio, não pelo vencimento")
    func noticeDeadlineWinsOverExpiry() {
        let notice = calendar.date(byAdding: .day, value: 5, to: now)!
        let expiry = calendar.date(byAdding: .day, value: 90, to: now)!
        let doc = document(expiresAt: expiry, noticeDeadline: notice, autoRenews: true)

        #expect(doc.effectiveDeadline == notice)
        #expect(Rules.contractAlert(for: doc, now: now, calendar: calendar) == .urgent)
    }

    @Test("'Precisa de você' traz urgentes e decidir, mas não os apenas observados")
    func attentionListExcludesWatch() {
        let urgent = document(expiresAt: calendar.date(byAdding: .day, value: 3, to: now)!)
        let decide = document(expiresAt: calendar.date(byAdding: .day, value: 20, to: now)!)
        let watch = document(expiresAt: calendar.date(byAdding: .day, value: 50, to: now)!)
        let quiet = document(expiresAt: calendar.date(byAdding: .day, value: 300, to: now)!)

        let result = Rules.documentsNeedingAttention([watch, quiet, decide, urgent], now: now, calendar: calendar)

        #expect(result.map(\.id) == [urgent.id, decide.id])
    }
}

// MARK: - Case state

@Suite("Estado do caso")
struct CaseStateTests {

    @Test("Pendência aberta manda o caso para 'exige você'")
    func openPendencyWins() {
        let subject = legalCase()
        let pendency = Pendency(
            id: UUID(), kind: .hearing, title: "t", detail: "d",
            dueDate: calendar.date(byAdding: .day, value: 3, to: now)!,
            caseID: subject.id, documentID: nil, resolvedAt: nil
        )
        #expect(Rules.state(of: subject, pendencies: [pendency], now: now, calendar: calendar) == .requiresYou)
    }

    @Test("Pendência resolvida deixa de exigir o cliente")
    func resolvedPendencyReleases() {
        let subject = legalCase(movements: [movement(date: date(2026, 7, 18))])
        let pendency = Pendency(
            id: UUID(), kind: .hearing, title: "t", detail: "d",
            dueDate: calendar.date(byAdding: .day, value: 3, to: now)!,
            caseID: subject.id, documentID: nil, resolvedAt: now
        )
        #expect(Rules.state(of: subject, pendencies: [pendency], now: now, calendar: calendar) != .requiresYou)
    }

    @Test("Audiência próxima e não confirmada exige o cliente")
    func unconfirmedHearingRequiresClient() {
        let soon = calendar.date(byAdding: .day, value: 4, to: now)!
        let subject = legalCase(hearing: hearing(on: soon))
        #expect(Rules.state(of: subject, pendencies: [], now: now, calendar: calendar) == .requiresYou)
    }

    @Test("Audiência já confirmada não exige mais nada")
    func confirmedHearingDoesNot() {
        let soon = calendar.date(byAdding: .day, value: 4, to: now)!
        let subject = legalCase(movements: [movement(date: date(2026, 7, 20))], hearing: hearing(on: soon, confirmed: true))
        #expect(Rules.state(of: subject, pendencies: [], now: now, calendar: calendar) != .requiresYou)
    }

    @Test("Sem movimento há mais de 30 dias, a bola está com o tribunal")
    func staleCaseIsWithCourt() {
        let subject = legalCase(movements: [movement(date: date(2026, 5, 1))])
        #expect(Rules.state(of: subject, pendencies: [], now: now, calendar: calendar) == .withCourt)
    }

    @Test("Movimento recente e nada pendente fica em dia")
    func recentCaseIsOnTrack() {
        let subject = legalCase(movements: [movement(date: date(2026, 7, 18))])
        #expect(Rules.state(of: subject, pendencies: [], now: now, calendar: calendar) == .onTrack)
    }

    @Test("Casos que exigem o cliente vêm do prazo mais próximo para o mais distante")
    func requiringCasesSortedByDeadline() {
        let far = legalCase(hearing: hearing(on: calendar.date(byAdding: .day, value: 6, to: now)!))
        let near = legalCase(hearing: hearing(on: calendar.date(byAdding: .day, value: 2, to: now)!))

        let result = Rules.casesRequiringClient([far, near], pendencies: [], now: now, calendar: calendar)

        #expect(result.map(\.id) == [near.id, far.id])
    }

    @Test("Caso encerrado nunca entra em 'exige você'")
    func closedCasesExcluded() {
        let closed = legalCase(hearing: hearing(on: calendar.date(byAdding: .day, value: 2, to: now)!), closedAt: now)
        #expect(Rules.casesRequiringClient([closed], pendencies: [], now: now, calendar: calendar).isEmpty)
    }
}

// MARK: - Dashboard

@Suite("Barra de posição")
struct PositionTests {

    @Test("Conta cada caso aberto em exatamente um segmento")
    func countsEachOpenCaseOnce() {
        let requiring = legalCase(hearing: hearing(on: calendar.date(byAdding: .day, value: 2, to: now)!))
        let stale = legalCase(movements: [movement(date: date(2026, 5, 1))])
        let fresh = legalCase(movements: [movement(date: date(2026, 7, 18))])

        let position = Rules.position(cases: [requiring, stale, fresh], pendencies: [], now: now, calendar: calendar)

        #expect(position.requiresYou == 1)
        #expect(position.onTrack == 2) // "with court" and "on track" share the calm segment
        #expect(position.total == 3)
    }

    @Test("Casos encerrados não inflam a barra")
    func closedCasesIgnored() {
        let open = legalCase(movements: [movement(date: date(2026, 7, 18))])
        let closed = legalCase(movements: [movement(date: date(2026, 7, 18))], closedAt: now)

        #expect(Rules.position(cases: [open, closed], pendencies: [], now: now, calendar: calendar).total == 1)
    }

    @Test("Frações somam 1 quando há casos")
    func fractionsSumToOne() {
        let position = PortfolioPosition(requiresYou: 1, deadlineNear: 1, onTrack: 2)
        let fractions = position.fractions
        #expect(abs(fractions.requiresYou + fractions.deadlineNear + fractions.onTrack - 1) < 0.0001)
    }

    @Test("Carteira vazia devolve zeros em vez de dividir por zero")
    func emptyPortfolioIsSafe() {
        let position = PortfolioPosition(requiresYou: 0, deadlineNear: 0, onTrack: 0)
        #expect(position.isEmpty)
        #expect(position.fractions == (0, 0, 0))
    }
}
