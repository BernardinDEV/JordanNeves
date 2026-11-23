import Foundation
import Testing
@testable import AdvClient

// MARK: - CNJ

@Suite("Número CNJ")
struct CNJNumberTests {

    @Test("Analisa e reformata um número já formatado")
    func parsesFormatted() throws {
        let number = try #require(CNJNumber("0012345-16.2025.5.17.0004"))
        #expect(number.sequential == "0012345")
        #expect(number.checkDigits == "16")
        #expect(number.year == "2025")
        #expect(number.segment == "5")
        #expect(number.court == "17")
        #expect(number.origin == "0004")
        #expect(number.formatted == "0012345-16.2025.5.17.0004")
    }

    @Test("Aceita apenas dígitos")
    func parsesDigitsOnly() throws {
        let number = try #require(CNJNumber("00123451620255170004"))
        #expect(number.formatted == "0012345-16.2025.5.17.0004")
    }

    @Test("Rejeita comprimento errado")
    func rejectsWrongLength() {
        #expect(CNJNumber("123") == nil)
        #expect(CNJNumber("001234516202551700041") == nil)
        #expect(CNJNumber("") == nil)
    }

    /// The check digits are what catch a number mistyped in the firm's panel
    /// before it reaches a client who will compare it against their accountant's e-mail.
    @Test("Valida o dígito verificador dos números reais do app", arguments: [
        "0012345-16.2025.5.17.0004",
        "0004821-06.2024.8.08.0035",
        "0009117-03.2026.8.08.0035",
        "0007233-51.2025.5.17.0009"
    ])
    func validatesRealNumbers(raw: String) throws {
        let number = try #require(CNJNumber(raw))
        #expect(number.isValid, "\(raw) deveria ter dígito verificador válido")
    }

    @Test("Detecta dígito verificador errado")
    func detectsWrongCheckDigits() throws {
        // The number used in the design prototype — its check digits were made up.
        let number = try #require(CNJNumber("0012345-67.2025.5.17.0004"))
        #expect(!number.isValid)
        #expect(number.expectedCheckDigits == "16")
    }

    @Test("Rótulo curto do tribunal")
    func courtLabel() throws {
        #expect(try #require(CNJNumber("0012345-16.2025.5.17.0004")).courtLabel == "TRT-17")
        #expect(try #require(CNJNumber("0004821-06.2024.8.08.0035")).courtLabel == "TJ (08)")
    }

    @Test("Todo número de demonstração tem dígito válido")
    func mockDataIsInternallyConsistent() throws {
        for legalCase in MockData.cases {
            let number = try #require(CNJNumber(legalCase.number), "\(legalCase.number) não parseou")
            #expect(number.isValid, "\(legalCase.number) tem dígito verificador inválido")
        }
    }
}

// MARK: - Formatting

@Suite("Formatação")
struct FormatTests {

    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return c
    }()

    private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: dayOfMonth, hour: hour))!
    }

    @Test("CNPJ formatado")
    func formatsCNPJ() {
        #expect(Format.cnpj("14902336000108") == "14.902.336/0001-08")
    }

    @Test("CNPJ com tamanho errado volta como veio")
    func passesThroughBadCNPJ() {
        #expect(Format.cnpj("123") == "123")
    }

    @Test("Contagem regressiva em palavras")
    func countdownWording() {
        let now = day(2026, 7, 22, hour: 15)
        let pt = Locale(identifier: "pt-BR")
        #expect(Format.countdown(to: day(2026, 7, 22, hour: 23), now: now, calendar: calendar, locale: pt) == "hoje")
        #expect(Format.countdown(to: day(2026, 7, 23), now: now, calendar: calendar, locale: pt) == "amanhã")
        #expect(Format.countdown(to: day(2026, 7, 21), now: now, calendar: calendar, locale: pt) == "vencido ontem")
        #expect(Format.countdown(to: day(2026, 9, 14), now: now, calendar: calendar, locale: pt).contains("54"))
    }

    /// The app has an in-app language switch, so these strings must follow the
    /// user's choice rather than the device language.
    @Test("Contagem regressiva segue o idioma pedido")
    func countdownFollowsLocale() {
        let now = day(2026, 7, 22, hour: 15)
        let tomorrow = day(2026, 7, 23)
        #expect(Format.countdown(to: tomorrow, now: now, calendar: calendar, locale: Locale(identifier: "pt-BR")) == "amanhã")
        #expect(Format.countdown(to: tomorrow, now: now, calendar: calendar, locale: Locale(identifier: "en")) == "tomorrow")
    }

    /// Principle: a deadline always shows the absolute date *and* the countdown.
    /// The date alone forces mental arithmetic; the countdown alone loses the reference.
    @Test("Prazo traz data e contagem juntas")
    func deadlineShowsBoth() {
        let now = day(2026, 7, 22, hour: 15)
        let text = Format.deadline(day(2026, 9, 14), now: now, calendar: calendar, locale: Locale(identifier: "pt-BR"))
        #expect(text.contains("14/09/2026"))
        #expect(text.contains("54"))
    }

    @Test("Valor em reais")
    func formatsMoney() {
        let text = Format.money(84_200)
        #expect(text.contains("84"))
        #expect(text.contains("R$"))
    }

    @Test("Data e valor seguem o idioma pedido, não o do aparelho")
    func formatsForTheChosenLanguage() {
        // Locale explícito de propósito: `Format.uiLocale` é estado global e os
        // testes rodam em paralelo — mexer nele daria intermitência.
        let english = Locale(identifier: "en_US")
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        let deadline = gregorian.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 9))!

        #expect(Format.date(deadline, locale: english) != Format.date(deadline, locale: Format.brazil))
        // A moeda continua sendo a do escritório; só a escrita do número muda.
        #expect(Format.money(84_200, locale: english).contains("R$"))
        #expect(Format.money(84_200, locale: english) != Format.money(84_200, locale: Format.brazil))
    }
}

// MARK: - WhatsApp

@Suite("Link do WhatsApp")
struct WhatsAppLinkTests {

    @Test("Normaliza número brasileiro sem código do país")
    func addsCountryCode() {
        #expect(WhatsAppLink.normalize(phone: "27 3442-8250") == "552734428250")
        #expect(WhatsAppLink.normalize(phone: "(27) 99999-8250") == "5527999998250")
    }

    @Test("Mantém número que já traz o código do país")
    func keepsInternational() {
        #expect(WhatsAppLink.normalize(phone: "+55 27 3442-8250") == "552734428250")
    }

    @Test("Rejeita número implausível")
    func rejectsGarbage() {
        #expect(WhatsAppLink.normalize(phone: "") == nil)
        #expect(WhatsAppLink.normalize(phone: "abc") == nil)
        #expect(WhatsAppLink.normalize(phone: "1234") == nil)
    }

    @Test("Monta URL wa.me com a mensagem codificada")
    func buildsURL() throws {
        let url = try #require(WhatsAppLink.url(phone: "27 3442-8250", message: "Olá, é sobre o caso"))
        #expect(url.scheme == "https")
        #expect(url.host == "wa.me")
        #expect(url.path == "/552734428250")

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let text = try #require(components.queryItems?.first { $0.name == "text" }?.value)
        #expect(text == "Olá, é sobre o caso")
    }

    @Test("Telefone inválido não gera URL")
    func noURLForBadPhone() {
        #expect(WhatsAppLink.url(phone: "nope", message: "oi") == nil)
    }

    /// Carrying the case number in the message is what preserves the firm's
    /// "one subject, one case" rule now that the in-app conversation is gone.
    @Test("Mensagem de andamento leva empresa, processo e data")
    func movementMessageCarriesContext() {
        // Fuso e idioma explícitos: a data é escrita no fuso do escritório, e
        // `Format.uiLocale` é estado global que o app hospedeiro ajusta para o
        // idioma do aparelho — num simulador em inglês este teste falhava.
        var saoPaulo = Calendar(identifier: .gregorian)
        saoPaulo.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        let date = saoPaulo.date(from: DateComponents(year: 2026, month: 7, day: 12, hour: 9))!
        let message = WhatsAppLink.Context
            .movement(caseNumber: "0012345-16.2025.5.17.0004", caseTitle: "Reclamação trabalhista", movementDate: date)
            .message(companyName: "Costa Log Transportes", locale: Format.brazil)

        #expect(message.contains("Costa Log Transportes"))
        #expect(message.contains("0012345-16.2025.5.17.0004"))
        #expect(message.contains("Reclamação trabalhista"))
        #expect(message.contains("12/07/2026"))
    }

    @Test("Mensagem de contrato nomeia o contrato")
    func contractMessageNamesIt() {
        let message = WhatsAppLink.Context
            .contract(title: "Transporte rodoviário — Suzano")
            .message(companyName: "Costa Log")
        #expect(message.contains("Transporte rodoviário — Suzano"))
        #expect(message.contains("Costa Log"))
    }

    @Test("Mensagem genérica se apresenta pela empresa")
    func generalMessageIntroducesCompany() {
        #expect(WhatsAppLink.Context.general.message(companyName: "Costa Log").contains("Costa Log"))
    }
}

// MARK: - Auth

@Suite("Autenticação sem senha")
struct AuthTests {

    @Test("E-mail de demonstração da marca entra, normalizado")
    func acceptsBrandDemoEmails() {
        let accepted = MockAuthService.acceptedEmails(brandEmails: ["  Pessoa.Teste@Exemplo.com "])
        #expect(accepted.contains("pessoa.teste@exemplo.com"))
        #expect(accepted.isSuperset(of: MockAuthService.invitedEmails))
        #expect(MockAuthService.acceptedEmails(brandEmails: []) == MockAuthService.invitedEmails)
    }


    private let service = MockAuthService()

    @Test("E-mail convidado recebe um código com validade")
    func issuesChallenge() async throws {
        let challenge = try await service.requestCode(email: "financeiro@costalog.com.br")
        #expect(challenge.email == "financeiro@costalog.com.br")
        #expect(!challenge.isExpired())
        #expect(challenge.secondsUntilResend() > 0)
    }

    @Test("Expiração do código e cooldown de reenvio são relógios diferentes")
    func resendIsNotGatedOnExpiry() async throws {
        let challenge = try await service.requestCode(email: "financeiro@costalog.com.br")
        // O reenvio libera muito antes de o código morrer — o contrário deixava
        // o cliente sem código válido e sem botão para pedir outro.
        #expect(challenge.resendAllowedAt < challenge.expiresAt)
        #expect(MockAuthService.resendCooldown < MockAuthService.codeLifetime)

        let justAfterCooldown = challenge.resendAllowedAt.addingTimeInterval(1)
        #expect(challenge.secondsUntilResend(now: justAfterCooldown) == 0)
        #expect(!challenge.isExpired(now: justAfterCooldown))
    }

    @Test("Código sobrevive ao tempo de abrir o e-mail e digitar")
    func codeOutlivesTheEmailRoundTrip() async throws {
        let challenge = try await service.requestCode(email: "financeiro@costalog.com.br")
        #expect(!challenge.isExpired(now: challenge.issuedAt.addingTimeInterval(300)))
    }

    @Test("Normaliza caixa e espaços do e-mail")
    func normalizesEmail() async throws {
        let challenge = try await service.requestCode(email: "  Financeiro@CostaLog.com.br ")
        #expect(challenge.email == "financeiro@costalog.com.br")
    }

    @Test("E-mail fora da lista de convidados é recusado")
    func rejectsUninvited() async {
        await #expect(throws: AuthError.unknownEmail) {
            _ = try await service.requestCode(email: "alguem@outraempresa.com")
        }
    }

    @Test("E-mail malformado é recusado", arguments: ["semarroba", "@semlocal.com", "sem@dominio", "a@b."])
    func rejectsMalformed(email: String) async {
        await #expect(throws: AuthError.malformedEmail) {
            _ = try await service.requestCode(email: email)
        }
    }

    @Test("Código correto devolve a empresa do usuário")
    func verifiesCode() async throws {
        let challenge = try await service.requestCode(email: "financeiro@costalog.com.br")
        let company = try await service.verify(code: MockAuthService.demoCode, challenge: challenge)
        #expect(company.userEmail == "financeiro@costalog.com.br")
        #expect(company.cnpj == MockData.company.cnpj)
    }

    @Test("Código errado é recusado")
    func rejectsWrongCode() async throws {
        let challenge = try await service.requestCode(email: "financeiro@costalog.com.br")
        await #expect(throws: AuthError.invalidCode) {
            _ = try await service.verify(code: "000000", challenge: challenge)
        }
    }

    @Test("Código expirado é recusado antes de olhar os dígitos")
    func rejectsExpired() async {
        let expired = CodeChallenge(
            email: "financeiro@costalog.com.br",
            issuedAt: .now.addingTimeInterval(-120),
            expiresAt: .now.addingTimeInterval(-60)
        )
        await #expect(throws: AuthError.codeExpired) {
            _ = try await service.verify(code: MockAuthService.demoCode, challenge: expired)
        }
    }
}

// MARK: - Repository

@Suite("Repositório")
struct RepositoryTests {

    @Test("Confirmar audiência marca o caso e resolve a pendência")
    func confirmingHearingResolvesPendency() async throws {
        let repository = MockClientRepository()
        let before = try await repository.snapshot(for: MockData.company.id)

        let hearingCase = try #require(before.cases.first { $0.hearing != nil })
        #expect(hearingCase.hearing?.isConfirmed == false)
        #expect(before.pendencies.contains { $0.caseID == hearingCase.id && !$0.isResolved })

        let after = try await repository.confirmHearing(caseID: hearingCase.id)
        let updated = try #require(after.cases.first { $0.id == hearingCase.id })

        #expect(updated.hearing?.isConfirmed == true)
        #expect(!after.pendencies.contains { $0.caseID == hearingCase.id && $0.kind == .hearing && !$0.isResolved })
    }

    @Test("Envio de arquivo entra no topo, marcado como enviado pelo cliente")
    func uploadInsertsDocument() async throws {
        let repository = MockClientRepository()
        let before = try await repository.snapshot(for: MockData.company.id)

        let file = UploadFile(name: "cartao-ponto.pdf", data: Data("%PDF".utf8), contentType: "application/pdf")
        let after = try await repository.upload(file, caseID: MockData.laborCaseID)

        #expect(after.documents.count == before.documents.count + 1)
        let first = try #require(after.documents.first)
        #expect(first.title == "cartao-ponto.pdf")
        #expect(first.uploadedByClient)
        #expect(first.caseID == MockData.laborCaseID)
    }

    @Test("Saída para o WhatsApp registra só o rastro")
    func recordsHandoff() async {
        let repository = MockClientRepository()
        await repository.recordWhatsAppHandoff(caseID: MockData.laborCaseID)
        await repository.recordWhatsAppHandoff(caseID: nil)
        #expect(await repository.handoffCount == 2)
    }

    /// The demo tenant has to exercise every state, or the review account shows
    /// the app at its blandest — and the sealed case is the one nobody remembers.
    @Test("Dados de demonstração cobrem os estados que as telas precisam mostrar")
    func demoDataCoversStates() async throws {
        let repository = MockClientRepository()
        let snapshot = try await repository.snapshot(for: MockData.company.id)

        #expect(snapshot.cases.contains { $0.isUnderSeal })
        #expect(snapshot.cases.contains { $0.hearing != nil })
        #expect(snapshot.documents.contains { $0.autoRenews })
        #expect(!snapshot.pendencies.isEmpty)

        // At least one movement arrived from the court without a translation and
        // must stay invisible.
        let unpublished = snapshot.cases.flatMap(\.movements).filter { !Rules.isPublished($0) }
        #expect(!unpublished.isEmpty)
        for movement in unpublished {
            #expect(!snapshot.cases.flatMap(\.visibleMovements).contains { $0.id == movement.id })
        }
    }
}

// MARK: - Contato

@Suite("Tela de contato")
struct ContactFormattingTests {

    @Test("Telefone vira algo que o discador aceita")
    func buildsDialableNumber() {
        #expect(ContactView.dialable("+55 27 3442-8250") == "+552734428250")
        #expect(ContactView.dialable("(27) 3442-8250") == "2734428250")
    }

    @Test("Site aparece sem o esquema")
    func stripsScheme() {
        #expect(ContactView.hostname("https://jordanneves.adv.br") == "jordanneves.adv.br")
        // Sem URL válida, mostra o que veio em vez de sumir com o dado.
        #expect(ContactView.hostname("jordanneves.adv.br") == "jordanneves.adv.br")
    }

    @Test("Perfil social vira arroba")
    func buildsHandle() {
        #expect(ContactView.handle("https://instagram.com/jordannevesadv") == "@jordannevesadv")
        #expect(ContactView.handle("https://linkedin.com/company/jordan-neves-advogados") == "@jordan-neves-advogados")
    }
}
