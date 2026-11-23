import Foundation
import Testing
@testable import AdvClient

/// `APIClient` que devolve sempre a mesma resposta (ou o mesmo erro) e anota
/// os endpoints pedidos.
private actor FixedAPIClient: APIClient {
    private let result: Result<Data, APIError>
    private(set) var paths: [String] = []
    private(set) var headers: [[String: String]] = []

    init(_ result: Result<Data, APIError>) { self.result = result }

    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint<Response>) async throws -> Fetched<Response> {
        paths.append(endpoint.path)
        headers.append(endpoint.headers)
        let value = try JSONDecoder.api.decode(Response.self, from: try result.get())
        return Fetched(value: value, source: .network, servedAt: .now)
    }

    func setScope(_ scope: String?) async {}
    func purgeCache() async {}
}

/// Dados fictícios no formato da fonte de teste — nenhum processo real.
private let listJSON = Data("""
{
  "atualizado_em": null,
  "total": 3,
  "processos": [
    {
      "numero_cnj": "0001234-56.2026.8.08.0001",
      "tribunal": "TJXX",
      "orgao": "1º Juizado Especial Cível de Exemplo",
      "classe": "Procedimento do Juizado Especial Cível",
      "polo": "ativo (autor)",
      "ultimo_andamento": { "data": "2026-11-01", "texto": "Conclusos para despacho", "fonte": "DataJud" },
      "proximo_prazo": null
    },
    {
      "numero_cnj": "0009999-11.2020.5.17.0002",
      "tribunal": "TRTXX",
      "orgao": "2ª Vara do Trabalho de Exemplo",
      "classe": null,
      "polo": "passivo (réu)",
      "ultimo_andamento": { "data": "2020-03-01", "texto": "Arquivado", "fonte": null },
      "proximo_prazo": null
    },
    { "numero_cnj": "sem número", "tribunal": "TJXX" }
  ]
}
""".utf8)

@Suite("Fonte somente leitura")
struct ReadOnlySourceTests {

    private func snapshot() throws -> ClientSnapshot {
        try JSONDecoder.api.decode(ProcessListDTO.self, from: listJSON).domain()
    }

    @Test("Mapeia os processos e descarta o que não tem número CNJ")
    func mapsProcesses() throws {
        let snapshot = try snapshot()
        #expect(snapshot.cases.count == 2)

        let first = try #require(snapshot.cases.first)
        #expect(first.number == "0001234-56.2026.8.08.0001")
        #expect(first.title == "1º Juizado Especial Cível de Exemplo")
        #expect(first.courtShort == "TJXX")
        #expect(first.caseClass == "Procedimento do Juizado Especial Cível")
        #expect(first.clientRole == "ativo (autor)")
        #expect(first.area == .civil)
        #expect(first.isOpen)
        #expect(first.lastCourtActivity?.source == "DataJud")
        #expect(first.lastCourtActivity?.date == ISO8601Parsing.date(from: "2026-11-01"))
    }

    @Test("Não afirma o que a fonte não disse")
    func leavesUnknownsEmpty() throws {
        let legalCase = try #require(try snapshot().cases.first)
        #expect(legalCase.opposingParty == nil)
        #expect(legalCase.claimValue == nil)
        #expect(legalCase.provision == nil)
        #expect(legalCase.responsibleLawyer.isEmpty)
        #expect(legalCase.hearing == nil)
    }

    @Test("O texto cru do tribunal nunca entra no caso (regra 2)")
    func dropsRawCourtText() throws {
        for legalCase in try snapshot().cases {
            #expect(legalCase.movements.isEmpty)
            #expect(legalCase.visibleMovements.isEmpty)
        }
    }

    @Test("Sem atualizado_em, nenhuma data inventada; documentos e envio desligados")
    func snapshotMetadata() throws {
        let snapshot = try snapshot()
        #expect(snapshot.lastSyncedAt == .distantPast)
        #expect(snapshot.capabilities == ProviderCapabilities(documents: false, uploads: false))
        #expect(snapshot.documents.isEmpty && snapshot.pendencies.isEmpty && snapshot.invoices.isEmpty)
    }

    @Test("O mesmo número CNJ dá sempre o mesmo id")
    func stableIDs() throws {
        let a = try snapshot().cases.map(\.id)
        let b = try snapshot().cases.map(\.id)
        #expect(a == b)
        #expect(Set(a).count == a.count)
    }

    @Test("Área pela classe e, sem ela, pelo segmento da Justiça")
    func areas() throws {
        let cases = try snapshot().cases
        #expect(cases[1].area == .labor)
        #expect(ProcessListDTO.Process.area(caseClass: "Execução Fiscal", cnjDigits: "00000000000000000000") == .tax)
        #expect(ProcessListDTO.Process.area(caseClass: "Ação de Alimentos", cnjDigits: "00000000000000000000") == .family)
        #expect(ProcessListDTO.Process.area(caseClass: nil, cnjDigits: "00000000000000080000") == .other)
    }

    @Test("A data da última movimentação decide se o caso está com o tribunal")
    func stateFromCourtActivity() throws {
        let cases = try snapshot().cases
        let now = try #require(ISO8601Parsing.date(from: "2026-11-13"))
        #expect(Rules.state(of: cases[0], pendencies: [], now: now) == .onTrack)
        #expect(Rules.state(of: cases[1], pendencies: [], now: now) == .withCourt)
        #expect(cases[0].lastVisibleUpdate == cases[0].lastCourtActivity?.date)
    }

    @Test("Pede a lista com o cabeçalho do ngrok")
    func requestsList() async throws {
        let client = FixedAPIClient(.success(listJSON))
        let repository = ReadOnlyCasesRepository(client: client)
        _ = try await repository.snapshot(for: UUID())
        #expect(await client.paths == ["/app/v1/processos"])
        #expect(await client.headers.first?["ngrok-skip-browser-warning"] == "1")
    }

    @Test("Chave recusada é erro de configuração, não sessão vencida")
    func unauthorizedKeepsSession() async {
        let repository = ReadOnlyCasesRepository(client: FixedAPIClient(.failure(.unauthorized(nil))))
        do {
            _ = try await repository.snapshot(for: UUID())
            Issue.record("deveria ter falhado")
        } catch let error as APIError {
            #expect(error == .forbidden(nil))
            #expect(!error.endsSession)
        } catch {
            Issue.record("erro inesperado: \(error)")
        }
    }

    @Test("Ações de escrita falham, em vez de fingir que chegaram")
    func writesFail() async {
        let repository = ReadOnlyCasesRepository(client: FixedAPIClient(.success(listJSON)))
        await #expect(throws: APIError.self) { try await repository.confirmHearing(caseID: UUID()) }
        await #expect(throws: APIError.self) { try await repository.resolvePendency(id: UUID()) }
    }

    @Test("Chave e endereço: ambiente antes do Info.plist")
    func configurationPrecedence() throws {
        let info: [String: Any] = [
            "ADVReadOnlyAPIBaseURL": "https://plist.exemplo.test",
            "ADVReadOnlyAPIKey": "chave-do-plist",
        ]
        let fromPlist = try ReadOnlySource.current(environment: [:], info: info)
        #expect(fromPlist.baseURL.host == "plist.exemplo.test")
        #expect(fromPlist.apiKey == "chave-do-plist")

        let fromEnv = try ReadOnlySource.current(environment: ["ADV_READONLY_API_KEY": "chave-do-ambiente"], info: info)
        #expect(fromEnv.apiKey == "chave-do-ambiente")
    }

    @Test("Configuração ausente, não expandida ou sem https é recusada")
    func rejectsBadConfiguration() {
        #expect(throws: ReadOnlySource.ConfigurationError.missingAPIKey) {
            try ReadOnlySource.current(environment: [:], info: [
                "ADVReadOnlyAPIBaseURL": "https://plist.exemplo.test",
                "ADVReadOnlyAPIKey": "$(READONLY_API_KEY)",
            ])
        }
        #expect(throws: ReadOnlySource.ConfigurationError.missingBaseURL) {
            try ReadOnlySource.current(environment: [:], info: [
                "ADVReadOnlyAPIBaseURL": "http://plist.exemplo.test",
                "ADVReadOnlyAPIKey": "chave",
            ])
        }
        #expect(throws: ReadOnlySource.ConfigurationError.missingBaseURL) {
            try ReadOnlySource.current(environment: [:], info: [:])
        }
    }

    @Test("A chave vai no cabeçalho Authorization")
    func bearerHeader() async {
        #expect(await StaticBearerAuthorization(key: "abc").authorizationHeader() == "Bearer abc")
    }
}
