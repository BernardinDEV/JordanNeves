import Foundation

/// Um conjunto completo de dados de demonstração: a conta e tudo o que ela vê.
///
/// Há dois no núcleo — empresa (`MockData`, a Costa Log do protótipo) e pessoa
/// física (`PersonalMockData`). A marca escolhe no `Brand.json`:
///
/// ```json
/// "demo": {
///   "dataset": "personal",
///   "account": { "name": "Nome da Pessoa", "document": "123.456.789-09" },
///   "invitedEmails": ["pessoa@exemplo.com"]
/// }
/// ```
///
/// `account` troca só a identidade (nome e CPF ou CNPJ). É o que permite a
/// demonstração sair em nome de alguém do escritório sem esse nome entrar no
/// núcleo, que não pode citar escritório nenhum.
struct DemoDataset: Sendable {
    var company: Company
    var cases: [LegalCase]
    var documents: [ClientDocument]
    var pendencies: [Pendency]
    var invoices: [Invoice]

    /// Pontos de entrada das rotas de captura e das prévias do Xcode: um caso
    /// com audiência a confirmar, um em segredo de justiça e um contrato com
    /// renovação automática perto do aviso.
    var hearingCaseID: UUID
    var sealedCaseID: UUID
    var renewalContractID: UUID

    /// Empresa: o conjunto do protótipo. É o da marca de referência e dos testes.
    static func business() -> DemoDataset {
        DemoDataset(
            company: MockData.company,
            cases: MockData.cases,
            documents: MockData.documents,
            pendencies: MockData.pendencies,
            invoices: MockData.invoices,
            hearingCaseID: MockData.laborCaseID,
            sealedCaseID: MockData.sealedCaseID,
            renewalContractID: MockData.suzanoContractID
        )
    }

    /// Pessoa física: de dois a três processos em cada estado.
    static func personal() -> DemoDataset {
        DemoDataset(
            company: PersonalMockData.account,
            cases: PersonalMockData.cases,
            documents: PersonalMockData.documents,
            pendencies: PersonalMockData.pendencies,
            invoices: PersonalMockData.invoices,
            hearingCaseID: PersonalMockData.evictionCaseID,
            sealedCaseID: PersonalMockData.sealedCaseID,
            renewalContractID: PersonalMockData.officeLeaseID
        )
    }

    /// O conjunto que a marca em execução pede. Calculado a cada chamada: as
    /// datas são relativas a hoje.
    static var current: DemoDataset {
        make(for: BrandConfiguration.current.demo)
    }

    static func make(for demo: BrandConfiguration.Demo?) -> DemoDataset {
        var dataset: DemoDataset = demo?.dataset == .personal ? .personal() : .business()
        if let account = demo?.account {
            dataset.company.legalName = account.name
            dataset.company.tradeName = account.name
            dataset.company.cnpj = account.document.filter(\.isNumber)
            if let email = account.email ?? demo?.invitedEmails?.first {
                dataset.company.userEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
        }
        return dataset
    }

    var snapshot: ClientSnapshot {
        ClientSnapshot(
            cases: cases,
            documents: documents,
            pendencies: pendencies,
            invoices: invoices,
            lastSyncedAt: Rules.calendar.date(bySettingHour: 8, minute: 30, second: 0, of: .now) ?? .now
        )
    }
}
