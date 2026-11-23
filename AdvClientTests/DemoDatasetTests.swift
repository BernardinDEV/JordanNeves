import Foundation
import Testing
@testable import AdvClient

@Suite("Demonstração de pessoa física")
struct PersonalDemoTests {

    private let dataset = DemoDataset.personal()

    private func count(_ state: CaseState, in index: PortfolioIndex) -> Int {
        index.openCases.count { index.state(of: $0) == state }
    }

    /// O que foi pedido: de dois a três processos em cada estado. As datas são
    /// relativas a hoje, então isto também prova que nada "apodrece" de um
    /// dia para o outro.
    @Test("De dois a três processos ativos em cada estado")
    func coversEveryState() {
        let index = PortfolioIndex(snapshot: dataset.snapshot)
        for state in [CaseState.requiresYou, .deadlineNear, .withCourt, .onTrack] {
            #expect((2...3).contains(count(state, in: index)), "\(state): \(count(state, in: index))")
        }
        #expect(index.closedCases.count >= 1)
    }

    @Test("Números CNJ com dígito verificador válido")
    func caseNumbersAreValid() throws {
        for legalCase in dataset.cases {
            let number = try #require(CNJNumber(legalCase.number), "\(legalCase.number)")
            #expect(number.isValid, "\(legalCase.title): \(legalCase.number)")
        }
    }

    @Test("Identificadores únicos em tudo")
    func identifiersAreUnique() {
        var ids: [UUID] = dataset.cases.map(\.id) + dataset.documents.map(\.id)
            + dataset.pendencies.map(\.id) + dataset.invoices.map(\.id)
        ids += dataset.cases.flatMap(\.movements).map(\.id)
        ids += dataset.cases.compactMap(\.hearing).flatMap { [$0.id] + $0.checklist.map(\.id) }
        ids += dataset.documents.flatMap(\.attentionPoints).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Pendências apontam para casos e documentos que existem")
    func pendenciesResolve() {
        let caseIDs = Set(dataset.cases.map(\.id))
        let documentIDs = Set(dataset.documents.map(\.id))
        for pendency in dataset.pendencies {
            if let caseID = pendency.caseID { #expect(caseIDs.contains(caseID)) }
            if let documentID = pendency.documentID { #expect(documentIDs.contains(documentID)) }
        }
    }

    @Test("Pontos de entrada das rotas existem no conjunto")
    func entryPointsExist() {
        let hearingCase = dataset.cases.first { $0.id == dataset.hearingCaseID }
        #expect(hearingCase?.hearing?.isConfirmed == false)
        #expect(dataset.cases.first { $0.id == dataset.sealedCaseID }?.isUnderSeal == true)
        #expect(dataset.documents.first { $0.id == dataset.renewalContractID }?.autoRenews == true)
    }

    @Test("Contratos cobrem o escalonamento: urgente e decidir")
    func contractsEscalate() {
        let alerts = dataset.documents.compactMap { Rules.contractAlert(for: $0) }
        #expect(alerts.contains(.urgent))
        #expect(alerts.contains(.decide))
    }

    @Test("Andamento sem tradução não chega ao cliente")
    func keepsUnpublishedMovementHidden() {
        let all = dataset.cases.flatMap(\.movements)
        let visible = dataset.cases.flatMap(\.visibleMovements)
        #expect(all.count > visible.count)
    }

    @Test("A conta é de pessoa física")
    func accountIsPersonal() {
        #expect(dataset.company.isPersonal)
        #expect(!DemoDataset.business().company.isPersonal)
    }
}

@Suite("Conjunto escolhido pela marca")
struct DemoDatasetSelectionTests {

    private func demo(_ json: String) throws -> BrandConfiguration.Demo {
        try JSONDecoder().decode(BrandConfiguration.Demo.self, from: Data(json.utf8))
    }

    @Test("Sem configuração, a empresa do protótipo")
    func defaultsToBusiness() {
        let dataset = DemoDataset.make(for: nil)
        #expect(dataset.company == MockData.company)
        #expect(dataset.hearingCaseID == MockData.laborCaseID)
    }

    @Test("A marca troca o conjunto e a identidade, nada mais")
    func brandOverridesIdentity() throws {
        let config = try demo(#"{"dataset":"personal","account":{"name":"Pessoa Teste","document":"123.456.789-09"},"invitedEmails":["Pessoa@Teste.com"]}"#)
        let dataset = DemoDataset.make(for: config)

        #expect(dataset.company.tradeName == "Pessoa Teste")
        #expect(dataset.company.legalName == "Pessoa Teste")
        #expect(dataset.company.cnpj == "12345678909")
        #expect(dataset.company.userEmail == "pessoa@teste.com")
        #expect(dataset.company.isPersonal)
        #expect(dataset.company.id == PersonalMockData.account.id)
        #expect(dataset.cases.count == PersonalMockData.cases.count)
    }

    @Test("Bloco demo só com e-mails continua válido")
    func emailsOnlyStillDecodes() throws {
        let config = try demo(#"{"invitedEmails":["a@b.com"]}"#)
        #expect(config.dataset == nil)
        #expect(DemoDataset.make(for: config).company == MockData.company)
    }
}

@Suite("Textos de pessoa física")
struct PersonalWordingTests {

    @Test("CPF e CNPJ formatados pelo número de dígitos")
    func formatsTaxID() {
        #expect(Format.taxID("12345678909") == "123.456.789-09")
        #expect(Format.taxID("14902336000108") == "14.902.336/0001-08")
        #expect(Format.taxID("123") == "123")
    }

    @Test("WhatsApp: pessoa física se apresenta pelo nome")
    func greetsAsPerson() {
        let personal = WhatsAppLink.Context.general.message(companyName: "Pessoa Teste", isPersonal: true, locale: Format.brazil)
        let business = WhatsAppLink.Context.general.message(companyName: "Empresa Teste", locale: Format.brazil)

        #expect(personal.contains("Aqui é Pessoa Teste"))
        #expect(business.contains("Sou da Empresa Teste"))
    }
}
