import Foundation
import Testing
@testable import AdvClient

/// `APIClient` em memória: responde por caminho com JSON pronto e anota o que
/// foi pedido. Basta para testar o contrato sem rede e sem `URLProtocol`.
private actor FakeAPIClient: APIClient {
    private var responses: [String: Result<Data, APIError>]
    private(set) var requests: [(method: HTTPMethod, path: String, query: [String: String], authenticated: Bool)] = []
    private(set) var scope: String?
    private(set) var purged = false

    init(_ responses: [String: Result<Data, APIError>]) {
        self.responses = responses
    }

    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint<Response>) async throws -> Fetched<Response> {
        requests.append((endpoint.method, endpoint.path, endpoint.query, endpoint.requiresAuthentication))
        guard let result = responses[endpoint.path] else { throw APIError.notFound(nil) }
        let data = try result.get()
        let value = Response.self == EmptyResponse.self
            ? EmptyResponse() as! Response
            : try JSONDecoder.api.decode(Response.self, from: data)
        return Fetched(value: value, source: .network, servedAt: .now)
    }

    func setScope(_ scope: String?) async { self.scope = scope }
    func purgeCache() async { purged = true }
}

private let caseID = "11111111-1111-1111-1111-111111111111"

/// Um snapshot como a API canônica o descreve, com os desvios que o app tem
/// que tolerar: área nova, risco novo, um documento quebrado.
private let snapshotJSON = Data("""
{
  "syncedAt": "2026-11-09T11:30:00Z",
  "capabilities": { "documents": true, "uploads": false },
  "cases": [
    {
      "id": "\(caseID)",
      "number": "0012345-16.2025.5.17.0004",
      "title": "Reclamação trabalhista",
      "area": "labor",
      "court": "4ª Vara do Trabalho",
      "courtShort": "TRT-17",
      "underSeal": false,
      "opposingParty": "J. R. da Silva",
      "claimValue": "84200.50",
      "risk": "medium",
      "provision": "32000.00",
      "responsibleLawyer": "Advogado",
      "openedAt": "2025-01-10T12:00:00Z",
      "closedAt": null,
      "movements": [
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "date": "2026-10-30T12:00:00Z",
          "officialText": "Defiro o pedido de adiamento.",
          "headline": "O juiz aceitou o adiamento",
          "translation": "A audiência foi remarcada.",
          "requiresClient": false,
          "approvedBy": "Advogado",
          "approvedAt": "2026-10-30T13:00:00Z",
          "publishedAt": "2026-10-30T13:00:00Z"
        }
      ],
      "hearing": {
        "id": "33333333-3333-3333-3333-333333333333",
        "date": "2026-11-14T17:30:00Z",
        "venue": "Fórum",
        "address": "Av. Champagnat, 200",
        "whoMustAttend": "Um preposto",
        "checklist": [{ "id": "44444444-4444-4444-4444-444444444444", "text": "Procuração", "checked": true }],
        "confirmedAt": null
      }
    },
    {
      "id": "55555555-5555-5555-5555-555555555555",
      "number": "0000001-00.2026.8.08.0001",
      "title": "Área que o app ainda não conhece",
      "area": "environmental",
      "court": "Vara Ambiental",
      "courtShort": "TJES",
      "underSeal": true,
      "opposingParty": "Município",
      "claimValue": "1000",
      "risk": "catastrophic",
      "provision": "999",
      "responsibleLawyer": "Advogado",
      "openedAt": "2026-01-10T12:00:00Z",
      "movements": []
    }
  ],
  "documents": [
    { "id": "66666666-6666-6666-6666-666666666666", "title": "Sem data", "kind": "contract" },
    {
      "id": "77777777-7777-7777-7777-777777777777",
      "title": "Contrato Suzano",
      "kind": "contract",
      "caseId": null,
      "autoRenews": true,
      "monthlyValue": "214900.00",
      "version": 2,
      "attentionPoints": [],
      "uploadedByClient": false,
      "uploadedAt": "2026-01-13T12:00:00Z",
      "noticeDeadline": "2026-11-15T12:00:00Z"
    }
  ],
  "pendencies": [
    {
      "id": "88888888-8888-8888-8888-888888888888",
      "kind": "sign_power_of_attorney",
      "title": "Assinar procuração",
      "detail": "",
      "dueDate": "2026-11-20T12:00:00Z",
      "caseId": "\(caseID)"
    }
  ],
  "invoices": [
    { "id": "99999999-9999-9999-9999-999999999999", "reference": "11/2026", "amount": "9800.00", "dueDate": "2026-11-23T12:00:00Z" }
  ]
}
""".utf8)

@Suite("Contrato com a API do produto")
struct SnapshotContractTests {

    private func decoded() throws -> ClientSnapshot {
        try JSONDecoder.api.decode(SnapshotDTO.self, from: snapshotJSON).domain()
    }

    @Test("Snapshot completo vira o domínio, com dinheiro exato")
    func mapsSnapshot() throws {
        let snapshot = try decoded()
        let legalCase = try #require(snapshot.cases.first { $0.id.uuidString == caseID })

        #expect(legalCase.claimValue == Decimal(string: "84200.50"))
        #expect(legalCase.provision == 32000)
        #expect(legalCase.visibleMovements.count == 1)
        #expect(legalCase.hearing?.checklist.first?.isChecked == true)
        #expect(snapshot.invoices.first?.amount == 9800)
        #expect(snapshot.capabilities == ProviderCapabilities(documents: true, uploads: false))
    }

    @Test("Área e risco desconhecidos não derrubam nem inventam")
    func toleratesUnknownValues() throws {
        let snapshot = try decoded()
        let unknown = try #require(snapshot.cases.first { $0.title.hasPrefix("Área") })

        #expect(unknown.area == .other)
        #expect(unknown.isUnderSeal)
        // Sem nível de risco conhecido, a provisão some e a linha de risco
        // não aparece na tela.
        #expect(unknown.provision == nil)
    }

    @Test("Um documento quebrado não leva os outros junto")
    func dropsOnlyTheBrokenDocument() throws {
        let dto = try JSONDecoder.api.decode(SnapshotDTO.self, from: snapshotJSON)
        #expect(dto.documents.droppedCount == 1)
        #expect(dto.domain().documents.map(\.title) == ["Contrato Suzano"])
    }

    @Test("Pendência de tipo novo continua exigindo o cliente")
    func keepsUnknownPendency() throws {
        let pendency = try #require(try decoded().pendencies.first)
        #expect(pendency.kind == .documentRequest)
        #expect(AppRoute(pendency: pendency) == .legalCase(UUID(uuidString: caseID)!))
    }

    @Test("Sem capacidades no corpo, tudo ligado")
    func defaultsCapabilities() throws {
        let minimal = Data(#"{"syncedAt":"2026-11-09T11:30:00Z","cases":[],"documents":[],"pendencies":[],"invoices":[]}"#.utf8)
        let snapshot = try JSONDecoder.api.decode(SnapshotDTO.self, from: minimal).domain()
        #expect(snapshot.capabilities == .all)
    }
}

@Suite("Serviços remotos")
struct RemoteServiceTests {

    @Test("Repositório pede o snapshot sem mandar o id da empresa")
    func fetchesSnapshot() async throws {
        let client = FakeAPIClient(["/v1/snapshot": .success(snapshotJSON)])
        let snapshot = try await RemoteClientRepository(client: client).snapshot(for: UUID())

        #expect(snapshot.cases.count == 2)
        let request = try #require(await client.requests.first)
        #expect(request.method == .get)
        #expect(request.query.isEmpty)
        #expect(request.authenticated)
    }

    @Test("Confirmar audiência é POST no caso certo")
    func confirmsHearing() async throws {
        let path = "/v1/cases/\(caseID)/hearing/confirmation"
        let client = FakeAPIClient([path: .success(snapshotJSON)])
        _ = try await RemoteClientRepository(client: client).confirmHearing(caseID: UUID(uuidString: caseID)!)

        let request = try #require(await client.requests.first)
        #expect(request.method == .post)
        #expect(request.path == path)
    }

    @Test("Envio leva nome e caso na query e o arquivo no corpo")
    func uploadsFile() async throws {
        let client = FakeAPIClient(["/v1/documents": .success(snapshotJSON)])
        let file = UploadFile(name: "procuração.pdf", data: Data("%PDF".utf8), contentType: "application/pdf")
        _ = try await RemoteClientRepository(client: client).upload(file, caseID: UUID(uuidString: caseID))

        let request = try #require(await client.requests.first)
        #expect(request.query == ["fileName": "procuração.pdf", "caseId": caseID])
        let endpoint = BackendAPI.upload(file, caseID: nil)
        #expect(endpoint.body?.data == file.data)
        #expect(endpoint.body?.contentType == "application/pdf")
    }

    @Test("Login guarda o token e devolve a empresa")
    func signsIn() async throws {
        let session = Data("""
        {"token":"abc","expiresAt":"2099-01-01T00:00:00Z",
         "company":{"id":"\(caseID)","legalName":"Costa Log Ltda","tradeName":"Costa Log","cnpj":"14902336000108","userEmail":"financeiro@costalog.com.br"}}
        """.utf8)
        let client = FakeAPIClient(["/v1/auth/session": .success(session)])
        let tokens = SessionTokenStore()
        let challenge = CodeChallenge(email: "financeiro@costalog.com.br", issuedAt: .now, expiresAt: .now.addingTimeInterval(600))

        let company = try await RemoteAuthService(client: client, tokens: tokens).verify(code: "492-718", challenge: challenge)

        #expect(company.tradeName == "Costa Log")
        #expect(await tokens.authorizationHeader() == "Bearer abc")
        #expect(await client.requests.first?.authenticated == false)
        await tokens.invalidate()
    }

    @Test("Código errado vira o erro de login com a frase certa")
    func mapsAuthErrors() async {
        let client = FakeAPIClient([
            "/v1/auth/session": .failure(.unauthorized(APIProblem(code: "invalid_code")))
        ])
        let challenge = CodeChallenge(email: "a@b.com", issuedAt: .now, expiresAt: .now.addingTimeInterval(600))

        await #expect(throws: AuthError.invalidCode) {
            _ = try await RemoteAuthService(client: client, tokens: SessionTokenStore()).verify(code: "000000", challenge: challenge)
        }
    }

    @Test("Token vencido não é enviado")
    func expiredTokenIsNotSent() async {
        let tokens = SessionTokenStore()
        await tokens.store(.init(value: "old", expiresAt: .now.addingTimeInterval(-1)))
        #expect(await tokens.authorizationHeader() == nil)
        await tokens.invalidate()
    }

    @Test("Sair limpa o cache e solta o escopo da conta")
    func signOutPurges() async {
        let client = FakeAPIClient([:])
        let lifecycle = RemoteSessionLifecycle(client: client, tokens: SessionTokenStore(), gate: SecurityGate(probe: { false }))

        await lifecycle.didSignIn(companyID: "empresa-1")
        #expect(await client.scope == "empresa-1")
        await lifecycle.didSignOut()
        #expect(await client.purged)
        #expect(await client.scope == nil)
    }
}
