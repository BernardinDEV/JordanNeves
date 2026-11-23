import Foundation
import Testing
@testable import AdvClient

private let calendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    return c
}()

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9, minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// Uma quarta-feira, meio da tarde.
private let now = date(2026, 7, 22, hour: 15)

private func movement(on movementDate: Date, requiresClient: Bool = false) -> CaseMovement {
    CaseMovement(
        id: UUID(),
        date: movementDate,
        officialText: "Texto oficial do tribunal.",
        translation: "Tradução.",
        requiresClient: requiresClient,
        approvedBy: "Advogado Responsável",
        approvedAt: movementDate,
        publishedAt: movementDate
    )
}

private func legalCase(
    title: String,
    movements: [CaseMovement] = [],
    hearing: Hearing? = nil,
    closedAt: Date? = nil
) -> LegalCase {
    LegalCase(
        id: UUID(),
        number: "0012345-16.2025.5.17.0004",
        title: title,
        area: .labor,
        court: "4ª Vara do Trabalho",
        courtShort: "TRT-17",
        isUnderSeal: false,
        opposingParty: "Parte",
        claimValue: 1000,
        risk: .medium,
        provision: nil,
        responsibleLawyer: "Advogado Responsável",
        openedAt: date(2025, 1, 10),
        closedAt: closedAt,
        movements: movements,
        hearing: hearing
    )
}

private func hearing(on hearingDate: Date) -> Hearing {
    Hearing(
        id: UUID(),
        date: hearingDate,
        venue: "4ª Vara do Trabalho de Vitória",
        address: "Av. Princesa Isabel, 574; sala 3",
        whoMustAttend: "Um preposto",
        checklist: [],
        confirmedAt: nil
    )
}

private func snapshot(cases: [LegalCase], pendencies: [Pendency] = []) -> ClientSnapshot {
    ClientSnapshot(cases: cases, documents: [], pendencies: pendencies, invoices: [], lastSyncedAt: now)
}

// MARK: - Índice

@Suite("Índice da carteira")
struct PortfolioIndexTests {

    /// O índice é cache, não regra: para os dados de demonstração inteiros, o
    /// que ele guarda tem que ser exatamente o que `Rules` responde.
    @Test("Guarda o mesmo que as regras calculam")
    func agreesWithRules() {
        let data = ClientSnapshot(
            cases: MockData.cases,
            documents: MockData.documents,
            pendencies: MockData.pendencies,
            invoices: MockData.invoices,
            lastSyncedAt: .now
        )
        let reference = Date.now
        let index = PortfolioIndex(snapshot: data, now: reference)

        for legalCase in data.cases {
            #expect(index.state(of: legalCase) == Rules.state(of: legalCase, pendencies: data.pendencies, now: reference))
            #expect(index.nextDeadline(for: legalCase) == Rules.nextDeadline(for: legalCase, pendencies: data.pendencies))
            #expect(index.legalCase(id: legalCase.id) == legalCase)
        }
        for document in data.documents {
            #expect(index.contractAlert(for: document) == Rules.contractAlert(for: document, now: reference))
        }
        #expect(index.position == Rules.position(cases: data.cases, pendencies: data.pendencies, now: reference))
        #expect(index.casesRequiringClient == Rules.casesRequiringClient(data.cases, pendencies: data.pendencies, now: reference))
        #expect(index.documentsNeedingAttention == Rules.documentsNeedingAttention(data.documents, now: reference))
        #expect(index.openPendencies == Rules.openPendencies(data.pendencies, now: reference))
    }

    @Test("O painel não repete em 'Seus casos' o que já está em 'Exige você'")
    func otherOpenCasesExcludeUrgentOnes() {
        let urgent = legalCase(title: "Urgente", hearing: hearing(on: date(2026, 7, 24)))
        let quiet = legalCase(title: "Tranquilo", movements: [movement(on: date(2026, 7, 20))])
        let closed = legalCase(title: "Encerrado", closedAt: date(2026, 1, 5))
        let index = PortfolioIndex(snapshot: snapshot(cases: [quiet, urgent, closed]), now: now, calendar: calendar)

        #expect(index.casesRequiringClient.map(\.title) == ["Urgente"])
        #expect(index.otherOpenCases.map(\.title) == ["Tranquilo"])
        #expect(index.closedCases.map(\.title) == ["Encerrado"])
    }

    @Test("Lista de casos: o que exige o cliente vem primeiro, depois o mais recente")
    func ordersByUrgencyThenRecency() {
        let older = legalCase(title: "Em dia, antigo", movements: [movement(on: date(2026, 7, 1))])
        let newer = legalCase(title: "Em dia, recente", movements: [movement(on: date(2026, 7, 20))])
        let stale = legalCase(title: "Com o tribunal", movements: [movement(on: date(2026, 3, 1))])
        let urgent = legalCase(title: "Exige você", hearing: hearing(on: date(2026, 7, 24)))
        let index = PortfolioIndex(snapshot: snapshot(cases: [stale, older, urgent, newer]), now: now, calendar: calendar)

        #expect(index.openCasesByUrgency.map(\.title) == [
            "Exige você", "Em dia, recente", "Em dia, antigo", "Com o tribunal",
        ])
    }

    @Test("Selo do sino: pendências abertas mais informativos recentes não lidos")
    func countsUnread() {
        let recent = movement(on: date(2026, 7, 20))
        let old = movement(on: date(2026, 6, 1))
        let needsClient = movement(on: date(2026, 7, 21), requiresClient: true)
        let subject = legalCase(title: "Caso", movements: [recent, old, needsClient])
        let pendency = Pendency(
            id: UUID(), kind: .documentRequest, title: "Enviar contrato social", detail: "",
            dueDate: date(2026, 8, 1), caseID: subject.id, documentID: nil, resolvedAt: nil
        )
        let index = PortfolioIndex(snapshot: snapshot(cases: [subject], pendencies: [pendency]), now: now, calendar: calendar)

        // Uma pendência + um informativo dentro da janela de 14 dias. O de
        // junho já saiu da janela; o que exige o cliente não é "para saber".
        #expect(index.unreadCount(excluding: []) == 2)
        #expect(index.unreadCount(excluding: [recent.id]) == 1)
        #expect(index.informationalMovements.map(\.id) == [recent.id, old.id])
    }
}

// MARK: - Calendário

@Suite("Arquivo de calendário da audiência")
struct HearingCalendarFileTests {

    @Test("Vírgula e ponto e vírgula do endereço são escapados")
    func escapesSeparators() {
        let ics = HearingCalendarFile.ics(for: hearing(on: date(2026, 7, 27, hour: 14, minute: 30)), title: "Audiência — Silva, Souza")

        #expect(ics.contains("LOCATION:4ª Vara do Trabalho de Vitória — Av. Princesa Isabel\\, 574\\; sala 3"))
        #expect(ics.contains("SUMMARY:Audiência — Silva\\, Souza"))
    }

    @Test("Horário sai em UTC, não no fuso do aparelho")
    func stampsInUTC() {
        // 14h30 em São Paulo (UTC−3) são 17h30 UTC.
        #expect(HearingCalendarFile.stamp(date(2026, 7, 27, hour: 14, minute: 30)) == "20260727T173000Z")
    }
}

// MARK: - Hora

@Suite("Data e hora")
struct DateTimeFormatTests {

    @Test("Hora em 24 horas também em inglês")
    func usesTwentyFourHourClockInEnglish() {
        let afternoon = date(2026, 7, 27, hour: 14, minute: 30)

        #expect(Format.dateTime(afternoon, locale: Locale(identifier: "en_US")).hasSuffix("14h30"))
        #expect(Format.dateTime(afternoon, locale: Locale(identifier: "pt-BR")) == "27/07/2026 · 14h30")
    }

    @Test("Iniciais para o avatar")
    func buildsInitials() {
        #expect(Format.initials(of: "Costa Log Transportes") == "CL")
        #expect(Format.initials(of: "jordan") == "J")
    }
}
