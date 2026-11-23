import Foundation
import Testing
@testable import AdvClient

// MARK: - Apoio

/// Modelo de resposta usado pelos testes. Não é de nenhuma marca nem de nenhuma
/// tela — a camada de rede não conhece o produto.
private struct Painel: Codable, Sendable, Equatable {
    let titulo: String
    let total: Int
}

private func tempDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("advclient-cache-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func json(_ value: some Encodable) -> Data {
    (try? JSONEncoder().encode(value)) ?? Data()
}

/// Servidor de mentira. Responde o que a fila mandar e conta quantas
/// requisições realmente saíram — é assim que os testes provam que o cache
/// evitou a rede, e não apenas que devolveu o valor certo.
final class StubURLProtocol: URLProtocol {

    struct Stub: Sendable {
        var status: Int = 200
        var body: Data = Data()
        var headers: [String: String] = ["Content-Type": "application/json"]
        var error: URLError?
        var delay: TimeInterval = 0
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var queue: [Stub] = []
    nonisolated(unsafe) private static var served = 0

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        queue.removeAll()
        served = 0
    }

    static func enqueue(_ stub: Stub) {
        lock.lock(); defer { lock.unlock() }
        queue.append(stub)
    }

    /// Quantas requisições chegaram ao transporte.
    static var requestCount: Int {
        lock.lock(); defer { lock.unlock() }
        return served
    }

    /// Consome a fila; o último item fica e passa a responder sempre.
    private static func next() -> Stub? {
        lock.lock(); defer { lock.unlock() }
        // Contar só o que foi de fato respondido: com a fila vazia, somar aqui
        // esconderia um teste que esqueceu de enfileirar.
        guard !queue.isEmpty else { return nil }
        served += 1
        if queue.count > 1 { return queue.removeFirst() }
        return queue.first
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let stub = Self.next(), let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        if stub.delay > 0 { Thread.sleep(forTimeInterval: stub.delay) }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: stub.status,
            httpVersion: "HTTP/1.1",
            headerFields: stub.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if !stub.body.isEmpty {
            client?.urlProtocol(self, didLoad: stub.body)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private func stubbedSession() -> URLSession {
    let configuration = NetworkSecurity.makeConfiguration(timeout: 5)
    configuration.protocolClasses = [StubURLProtocol.self]
    // Com o mesmo delegate da produção: sem ele, um redirecionamento seria
    // seguido nos testes e recusado no app, que é a pior das combinações.
    return URLSession(configuration: configuration, delegate: RedirectPolicy(), delegateQueue: nil)
}

private let testBaseURL = URL(string: "https://api.exemplo.test")!

// MARK: - Corpo de erro

@Suite("Corpo de erro do serviço")
struct APIProblemTests {

    @Test("Lê o formato RFC 9457")
    func decodesProblemDetails() throws {
        let body = Data("""
        {"type":"contract_locked","title":"Contrato bloqueado","detail":"aguardando assinatura","request_id":"abc-123"}
        """.utf8)
        let problem = try JSONDecoder().decode(APIProblem.self, from: body)
        #expect(problem.code == "contract_locked")
        // `detail` ganha de `title`: no RFC 9457 o primeiro é a explicação
        // desta ocorrência, o segundo é o rótulo do tipo de problema.
        #expect(problem.detail == "aguardando assinatura")
        #expect(problem.requestID == "abc-123")
    }

    @Test("Lê o formato informal, com erros por campo")
    func decodesInformalShape() throws {
        let body = Data("""
        {"error":"validation_failed","message":"dados inválidos","errors":{"cnpj":["formato inválido"]}}
        """.utf8)
        let problem = try JSONDecoder().decode(APIProblem.self, from: body)
        #expect(problem.code == "validation_failed")
        #expect(problem.detail == "dados inválidos")
        #expect(problem.fields["cnpj"] == "formato inválido")
    }

    /// Um corpo de erro que não bate com o esperado não pode virar um segundo
    /// erro por cima do primeiro: o status é a informação que importa.
    @Test("Corpo inesperado não derruba a decodificação")
    func toleratesGarbage() throws {
        let problem = try JSONDecoder().decode(APIProblem.self, from: Data(#"{"error":{"nested":true}}"#.utf8))
        #expect(problem.code == nil)
        #expect(problem.detail == nil)
        #expect(problem.fields.isEmpty)
    }

    @Test("Adota o identificador do cabeçalho quando o corpo não traz")
    func adoptsHeaderRequestID() {
        let problem = APIProblem(code: "x").withRequestID("req-9")
        #expect(problem.requestID == "req-9")
        #expect(APIProblem(code: "x", requestID: "do-corpo").withRequestID("req-9").requestID == "do-corpo")
    }
}

// MARK: - Padrão de erro

@Suite("Padrão de erro")
struct APIErrorTests {

    @Test("Traduz os status que o app conhece")
    func mapsStatus() throws {
        let esperado: [Int: String] = [
            400: "dados recusados", 401: "não autenticado", 403: "sem permissão",
            404: "não encontrado", 409: "conflito", 422: "dados recusados",
            429: "excesso de chamadas", 500: "erro do servidor", 503: "erro do servidor"
        ]
        for (status, prefixo) in esperado.sorted(by: { $0.key < $1.key }) {
            let error = try #require(APIError.from(status: status, problem: nil))
            #expect(error.diagnostic.hasPrefix(prefixo), "status \(status) devolveu \(error.diagnostic)")
        }
    }

    @Test("2xx não é erro")
    func successIsNotAnError() {
        #expect(APIError.from(status: 200, problem: nil) == nil)
        #expect(APIError.from(status: 204, problem: nil) == nil)
    }

    /// A política de redirecionamento recusa o salto e o 3xx chega até aqui.
    /// Tratar isso como sucesso entregaria a página do redirecionador como se
    /// fosse a resposta do serviço.
    @Test("Redirecionamento que sobrou vira erro de transporte")
    func redirectIsTransportError() throws {
        let error = try #require(APIError.from(status: 302, problem: nil))
        if case .insecureTransport = error {} else {
            Issue.record("esperava insecureTransport, veio \(error.diagnostic)")
        }
    }

    @Test("Só 401 derruba a sessão")
    func onlyUnauthorizedEndsSession() {
        #expect(APIError.unauthorized(nil).endsSession)
        #expect(!APIError.forbidden(nil).endsSession)
        #expect(!APIError.server(status: 500, problem: nil).endsSession)
    }

    /// Entregar cache a quem o servidor acabou de recusar é o vazamento que o
    /// cache não pode causar.
    @Test("Cache vencido não responde por 401 nem 403")
    func staleFallbackExcludesAuthErrors() {
        #expect(APIError.offline.allowsStaleFallback)
        #expect(APIError.timedOut.allowsStaleFallback)
        #expect(APIError.server(status: 502, problem: nil).allowsStaleFallback)
        #expect(!APIError.unauthorized(nil).allowsStaleFallback)
        #expect(!APIError.forbidden(nil).allowsStaleFallback)
        #expect(!APIError.insecureEnvironment.allowsStaleFallback)
    }

    @Test("Repetir só o que vale a pena repetir")
    func retryability() {
        #expect(APIError.timedOut.isRetryable)
        #expect(APIError.server(status: 503, problem: nil).isRetryable)
        #expect(!APIError.notFound(nil).isRetryable)
        #expect(!APIError.invalidData(nil).isRetryable)
        #expect(!APIError.cancelled.isRetryable)
    }

    @Test("Traduz erro de sistema")
    func mapsSystemErrors() {
        #expect(APIError.mapping(URLError(.notConnectedToInternet)) == .offline)
        #expect(APIError.mapping(URLError(.timedOut)) == .timedOut)
        #expect(APIError.mapping(URLError(.cancelled)) == .cancelled)
        #expect(APIError.mapping(CancellationError()) == .cancelled)
        if case .insecureTransport = APIError.mapping(URLError(.serverCertificateUntrusted)) {} else {
            Issue.record("certificado não confiável tem que virar transporte inseguro")
        }
    }

    /// O que vai para o log de um app iOS sai do controle do escritório no
    /// instante em que é escrito.
    @Test("O diagnóstico não carrega o texto do servidor")
    func diagnosticCarriesNoServerText() {
        let problem = APIProblem(
            code: "contract_locked",
            detail: "contrato da COSTALOG LTDA, CNPJ 14.902.336/0001-08",
            requestID: "req-1"
        )
        let diagnostic = APIError.conflict(problem).diagnostic
        #expect(diagnostic.contains("contract_locked"))
        #expect(diagnostic.contains("req-1"))
        #expect(!diagnostic.contains("COSTALOG"))
        #expect(!diagnostic.contains("14.902.336"))
    }

    @Test("Toda variante tem frase para o cliente")
    func everyCaseHasAUserMessage() {
        let todos: [APIError] = [
            .offline, .timedOut, .cancelled, .insecureEnvironment,
            .insecureTransport(reason: "x"), .invalidRequest(reason: "x"),
            .unauthorized(nil), .forbidden(nil), .notFound(nil), .conflict(nil),
            .invalidData(nil), .rateLimited(retryAfter: nil, problem: nil),
            .server(status: 500, problem: nil), .unexpectedStatus(status: 418, problem: nil),
            .malformedResponse(reason: "x")
        ]
        for erro in todos {
            #expect(!erro.userMessage.isEmpty)
            // A frase do cliente nunca cita status nem chave de tradução.
            #expect(!erro.userMessage.contains("network.error"))
        }
    }
}

// MARK: - Endpoint

@Suite("Montagem da requisição")
struct EndpointTests {

    @Test("A chave da chamada não depende da ordem dos parâmetros")
    func canonicalKeyIsOrderIndependent() {
        let a = Endpoint<Painel>.get("/v1/casos", query: ["ano": "2026", "status": "aberto"])
        let b = Endpoint<Painel>.get("/v1/casos", query: ["status": "aberto", "ano": "2026"])
        #expect(a.canonicalKey == b.canonicalKey)
        #expect(a.canonicalKey == "GET /v1/casos?ano=2026&status=aberto")
    }

    @Test("Aceita caminho com e sem barra inicial")
    func normalizesPath() {
        #expect(Endpoint<Painel>.get("v1/painel").canonicalKey == "GET /v1/painel")
        #expect(Endpoint<Painel>.get("/v1/painel").canonicalKey == "GET /v1/painel")
    }

    @Test("Monta a URL preservando o caminho da base")
    func buildsURL() throws {
        let endpoint = Endpoint<Painel>.get("/painel", query: ["empresa": "42"])
        let request = try endpoint.makeRequest(baseURL: URL(string: "https://api.exemplo.test/v1")!)
        #expect(request.url?.absoluteString == "https://api.exemplo.test/v1/painel?empresa=42")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Cache-Control") == "no-store")
        #expect(request.httpShouldHandleCookies == false)
        #expect(request.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData)
    }

    /// O ATS protege o app instalado. Esta linha protege contra um `Brand.json`
    /// de escritório novo apontando para `http://` num build de teste.
    @Test("Recusa base sem HTTPS")
    func refusesPlainHTTP() {
        #expect(throws: APIError.self) {
            _ = try Endpoint<Painel>.get("/painel").makeRequest(baseURL: URL(string: "http://api.exemplo.test")!)
        }
    }

    @Test("Corpo JSON vai com o tipo de conteúdo certo")
    func encodesBody() throws {
        let body = try HTTPBody.json(Painel(titulo: "x", total: 1))
        let endpoint = Endpoint<EmptyResponse>.post("/v1/envios", body: body)
        let request = try endpoint.makeRequest(baseURL: testBaseURL)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("application/json") == true)
        #expect(request.httpBody == body.data)
    }

    @Test("Só GET, PUT e DELETE podem ser repetidos automaticamente")
    func idempotency() {
        #expect(HTTPMethod.get.isIdempotent)
        #expect(HTTPMethod.put.isIdempotent)
        #expect(HTTPMethod.delete.isIdempotent)
        #expect(!HTTPMethod.post.isIdempotent)
        #expect(!HTTPMethod.patch.isIdempotent)
    }

    @Test("Datas ISO 8601 com e sem fração de segundo")
    func parsesDates() {
        #expect(ISO8601Parsing.date(from: "2026-09-14T12:00:00Z") != nil)
        #expect(ISO8601Parsing.date(from: "2026-09-14T12:00:00.250Z") != nil)
        #expect(ISO8601Parsing.date(from: "2026-09-14") != nil)
        #expect(ISO8601Parsing.date(from: "14/09/2026") == nil)
    }
}

// MARK: - Nova tentativa

@Suite("Nova tentativa")
struct RetryTests {

    @Test("Repete 5xx e 429, não repete recusa do servidor")
    func retriesOnlyInfrastructure() {
        #expect(HTTPTransport.retryDelay(status: 500, retryAfter: nil, attempt: 1) != nil)
        #expect(HTTPTransport.retryDelay(status: 503, retryAfter: nil, attempt: 1) != nil)
        #expect(HTTPTransport.retryDelay(status: 429, retryAfter: nil, attempt: 1) != nil)
        #expect(HTTPTransport.retryDelay(status: 400, retryAfter: nil, attempt: 1) == nil)
        #expect(HTTPTransport.retryDelay(status: 404, retryAfter: nil, attempt: 1) == nil)
        // "O servidor não faz isso" não muda por insistência.
        #expect(HTTPTransport.retryDelay(status: 501, retryAfter: nil, attempt: 1) == nil)
    }

    @Test("A espera cresce a cada tentativa")
    func backoffGrows() throws {
        let primeira = try #require(HTTPTransport.retryDelay(status: 500, retryAfter: nil, attempt: 1))
        let terceira = try #require(HTTPTransport.retryDelay(status: 500, retryAfter: nil, attempt: 3))
        #expect(terceira > primeira)
        #expect(terceira <= 4.25)
    }

    @Test("Retry-After longo sobe como erro em vez de virar espera escondida")
    func longRetryAfterIsNotSwallowed() {
        #expect(HTTPTransport.retryDelay(status: 429, retryAfter: 120, attempt: 1) == nil)
        #expect(HTTPTransport.retryDelay(status: 429, retryAfter: 2, attempt: 1) != nil)
    }
}

// MARK: - Cache

@Suite("Cache de respostas")
struct ResponseCacheTests {

    @Test("As duas políticas pedidas: uma hora e um dia")
    func policies() {
        #expect(CachePolicy.oneHour.ttl == 3_600)
        #expect(CachePolicy.oneDay.ttl == 86_400)
        #expect(CachePolicy.oneHour.writesToDisk)
        #expect(CachePolicy.oneDay.writesToDisk)
        #expect(!CachePolicy.oneHourInMemory.writesToDisk)
        #expect(!CachePolicy.none.isEnabled)
    }

    @Test("Fresco, vencido, e vencido demais")
    func freshnessWindows() {
        let agora = Date(timeIntervalSince1970: 1_800_000_000)
        let entrada = CachedPayload(
            data: Data(),
            storedAt: agora,
            expiresAt: agora.addingTimeInterval(3_600),
            staleUntil: agora.addingTimeInterval(86_400)
        )
        #expect(entrada.isFresh(now: agora.addingTimeInterval(60)))
        #expect(!entrada.isFresh(now: agora.addingTimeInterval(3_601)))
        #expect(entrada.isServableWhenStale(now: agora.addingTimeInterval(3_601)))
        #expect(!entrada.isServableWhenStale(now: agora.addingTimeInterval(86_401)))
    }

    /// Duas contas no mesmo aparelho não podem se ver.
    @Test("A chave separa contas")
    func keyIsScoped() {
        let uma = ResponseCache.key(scope: "empresa-a", canonical: "GET /v1/painel")
        let outra = ResponseCache.key(scope: "empresa-b", canonical: "GET /v1/painel")
        #expect(uma != outra)
        #expect(uma == ResponseCache.key(scope: "empresa-a", canonical: "GET /v1/painel"))
        // O nome do arquivo no disco não pode dizer de quem é o dado.
        #expect(!uma.contains("empresa"))
        #expect(uma.count == 64)
    }

    @Test("Guarda, lê de volta e apaga")
    func roundTrip() async throws {
        let cache = ResponseCache(directory: tempDirectory())
        let chave = ResponseCache.key(scope: "t", canonical: "GET /v1/painel")
        let corpo = json(Painel(titulo: "painel", total: 3))

        await cache.store(corpo, for: chave, policy: .oneHour)
        let guardado = await cache.read(chave)
        let lido = try #require(guardado)
        #expect(lido.data == corpo)
        #expect(lido.isFresh())

        await cache.purgeAll()
        let depoisDaLimpeza = await cache.read(chave)
        #expect(depoisDaLimpeza == nil)
    }

    @Test("Sobrevive a um novo objeto sobre o mesmo diretório")
    func survivesRelaunch() async throws {
        let diretorio = tempDirectory()
        let chave = ResponseCache.key(scope: "t", canonical: "GET /v1/contratos")
        let corpo = json(Painel(titulo: "contratos", total: 9))

        await ResponseCache(directory: diretorio).store(corpo, for: chave, policy: .oneDay)

        // Outro objeto sobre o mesmo diretório é o que acontece no relançamento.
        let depois = ResponseCache(directory: diretorio)
        let relido = await depois.read(chave)
        #expect(relido?.data == corpo)
    }

    @Test("Política de memória não escreve no disco")
    func memoryOnlyStaysInMemory() async throws {
        let diretorio = tempDirectory()
        let chave = ResponseCache.key(scope: "t", canonical: "GET /v1/url-assinada")
        await ResponseCache(directory: diretorio).store(Data("x".utf8), for: chave, policy: .oneHourInMemory)

        let arquivos = try FileManager.default.contentsOfDirectory(at: diretorio, includingPropertiesForKeys: nil)
        #expect(arquivos.isEmpty)
    }

    @Test("A limpeza tira o que passou da janela de emergência")
    func purgesExpired() async throws {
        let cache = ResponseCache(directory: tempDirectory())
        let chave = ResponseCache.key(scope: "t", canonical: "GET /v1/velho")
        let passado = Date.now.addingTimeInterval(-10_000)
        await cache.write(
            CachedPayload(
                data: Data("velho".utf8),
                storedAt: passado,
                expiresAt: passado.addingTimeInterval(60),
                staleUntil: passado.addingTimeInterval(120)
            ),
            for: chave,
            toDisk: true
        )
        await cache.purgeExpired()
        let sobrou = await cache.read(chave)
        #expect(sobrou == nil)
    }
}

// MARK: - Log

@Suite("Redação do log")
struct NetworkLogTests {

    @Test("Tira identificador da rota")
    func masksIdentifiers() {
        #expect(NetworkLog.redact("/v1/cases/8B2F1C4A-1111-2222-3333-444455556666/movements") == "/v1/cases/{id}/movements")
        #expect(NetworkLog.redact("/v1/cases/0012345-16.2025.5.17.0004") == "/v1/cases/{id}")
        #expect(NetworkLog.redact("/v1/empresas/48291") == "/v1/empresas/{id}")
    }

    @Test("Descarta a consulta inteira")
    func dropsQuery() {
        #expect(NetworkLog.redact("/v1/casos?email=financeiro@costalog.com.br") == "/v1/casos")
    }

    @Test("Preserva a forma da rota")
    func keepsShape() {
        #expect(NetworkLog.redact("/v1/painel") == "/v1/painel")
        #expect(NetworkLog.redact("/v1/documentos/contratos") == "/v1/documentos/contratos")
    }
}

// MARK: - Cliente ponta a ponta

/// Em série porque compartilham o servidor de mentira, que é estado global.
@Suite("Cliente", .serialized)
struct APIClientTests {

    private func makeClient(
        cacheDirectory: URL? = nil,
        gate: SecurityGate = SecurityGate(probe: { false })
    ) -> LiveAPIClient {
        LiveAPIClient(
            baseURL: testBaseURL,
            session: stubbedSession(),
            cache: ResponseCache(directory: cacheDirectory ?? tempDirectory()),
            gate: gate
        )
    }

    @Test("Resposta boa vem da rede e decodifica")
    func decodesFromNetwork() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(body: json(Painel(titulo: "painel", total: 2))))

        let client = makeClient()
        let resultado = try await client.send(Endpoint<Painel>.get("/v1/painel"))

        #expect(resultado.value == Painel(titulo: "painel", total: 2))
        #expect(resultado.source == .network)
        #expect(!resultado.isFromCache)
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test("Dentro da validade, a segunda chamada não toca na rede")
    func servesFromCacheWithoutNetwork() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(body: json(Painel(titulo: "painel", total: 2))))

        let client = makeClient()
        let endpoint = Endpoint<Painel>.get("/v1/painel", cache: .oneHour)

        _ = try await client.send(endpoint)
        let segunda = try await client.send(endpoint)

        #expect(segunda.source == .cache)
        #expect(segunda.value.total == 2)
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test("Sem cache declarado, toda chamada vai à rede")
    func noCachePolicyMeansNoCache() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(body: json(Painel(titulo: "painel", total: 2))))

        let client = makeClient()
        let endpoint = Endpoint<Painel>.get("/v1/painel")
        _ = try await client.send(endpoint)
        _ = try await client.send(endpoint)

        #expect(StubURLProtocol.requestCount == 2)
    }

    /// O cliente no elevador do fórum: sem rede, o app mostra o que guardou e
    /// diz desde quando — não uma tela vazia.
    @Test("Sem rede, responde o cache vencido marcado como velho")
    func fallsBackToStaleCacheWhenOffline() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(error: URLError(.notConnectedToInternet)))

        let diretorio = tempDirectory()
        let cache = ResponseCache(directory: diretorio)
        let endpoint = Endpoint<Painel>.get("/v1/painel", cache: .oneHour)
        let chave = ResponseCache.key(scope: "empresa-1", canonical: endpoint.canonicalKey)

        let ontem = Date.now.addingTimeInterval(-7_200)
        await cache.write(
            CachedPayload(
                data: json(Painel(titulo: "guardado", total: 7)),
                storedAt: ontem,
                expiresAt: ontem.addingTimeInterval(3_600),
                staleUntil: ontem.addingTimeInterval(86_400)
            ),
            for: chave,
            toDisk: false
        )

        let client = LiveAPIClient(
            baseURL: testBaseURL,
            session: stubbedSession(),
            cache: cache,
            gate: SecurityGate(probe: { false })
        )
        await client.setScope("empresa-1")

        let resultado = try await client.send(endpoint)
        #expect(resultado.source == .staleCache)
        #expect(resultado.isStale)
        #expect(resultado.value.titulo == "guardado")
        // A data que a tela mostra é a de quando o dado saiu do servidor.
        #expect(abs(resultado.servedAt.timeIntervalSince(ontem)) < 1)
    }

    @Test("401 derrubando a sessão apaga o que estava guardado")
    func unauthorizedPurgesCache() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(status: 401, body: Data(#"{"error":"token_expired"}"#.utf8)))

        let cache = ResponseCache(directory: tempDirectory())
        let chave = ResponseCache.key(scope: "empresa-1", canonical: "GET /v1/contratos")
        await cache.store(json(Painel(titulo: "contratos", total: 4)), for: chave, policy: .oneDay)

        let client = LiveAPIClient(
            baseURL: testBaseURL,
            session: stubbedSession(),
            cache: cache,
            gate: SecurityGate(probe: { false })
        )
        await client.setScope("empresa-1")

        await #expect(throws: APIError.unauthorized(APIProblem(code: "token_expired"))) {
            _ = try await client.send(Endpoint<Painel>.get("/v1/painel"))
        }
        let sobrou = await cache.read(chave)
        #expect(sobrou == nil)
    }

    /// 403 é "você não pode ver este processo", não "você não é você". Derrubar
    /// o login aqui viraria chamado de suporte recorrente.
    @Test("403 não apaga o cache nem derruba a sessão")
    func forbiddenKeepsSession() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(status: 403))

        let cache = ResponseCache(directory: tempDirectory())
        let chave = ResponseCache.key(scope: "empresa-1", canonical: "GET /v1/contratos")
        await cache.store(json(Painel(titulo: "contratos", total: 4)), for: chave, policy: .oneDay)

        let client = LiveAPIClient(
            baseURL: testBaseURL,
            session: stubbedSession(),
            cache: cache,
            gate: SecurityGate(probe: { false })
        )
        await client.setScope("empresa-1")

        await #expect(throws: APIError.self) {
            _ = try await client.send(Endpoint<Painel>.get("/v1/processos/9"))
        }
        let intacto = await cache.read(chave)
        #expect(intacto != nil)
    }

    @Test("Duas telas pedindo a mesma coisa viram uma requisição")
    func coalescesIdenticalRequests() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(body: json(Painel(titulo: "painel", total: 2)), delay: 1.0))

        let client = makeClient()
        let endpoint = Endpoint<Painel>.get("/v1/painel")

        async let primeira = client.send(endpoint)
        async let segunda = client.send(endpoint)
        let (a, b) = try await (primeira, segunda)

        #expect(a.value == b.value)
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test("Corpo vazio responde EmptyResponse")
    func decodesEmptyBody() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(status: 204, headers: [:]))

        let client = makeClient()
        let resultado = try await client.send(Endpoint<EmptyResponse>.get("/v1/ping"))
        #expect(resultado.source == .network)
    }

    @Test("Resposta fora do formato vira erro de resposta malformada")
    func malformedBody() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(body: Data(#"{"titulo":"x"}"#.utf8)))

        let client = makeClient()
        await #expect(throws: APIError.self) {
            _ = try await client.send(Endpoint<Painel>.get("/v1/painel"))
        }
    }

    /// Num aparelho com jailbreak ou com biblioteca de interceptação carregada,
    /// tudo que o app faz é observável. A jogada honesta é não colocar processo
    /// e contrato de uma empresa na memória dele.
    @Test("Ambiente comprometido bloqueia a chamada e apaga o cache")
    func compromisedEnvironmentBlocksAndPurges() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(body: json(Painel(titulo: "painel", total: 2))))

        let cache = ResponseCache(directory: tempDirectory())
        let chave = ResponseCache.key(scope: "anonimo", canonical: "GET /v1/painel")
        await cache.store(json(Painel(titulo: "painel", total: 2)), for: chave, policy: .oneDay)

        let client = LiveAPIClient(
            baseURL: testBaseURL,
            session: stubbedSession(),
            cache: cache,
            gate: SecurityGate(probe: { true })
        )

        await #expect(throws: APIError.insecureEnvironment) {
            _ = try await client.send(Endpoint<Painel>.get("/v1/painel", cache: .oneDay))
        }
        let apagado = await cache.read(chave)
        #expect(apagado == nil)
        #expect(StubURLProtocol.requestCount == 0)
    }

    @Test("Trocar de conta não deixa o cache da anterior responder")
    func scopeSeparatesAccounts() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(.init(body: json(Painel(titulo: "da-empresa-a", total: 1))))
        StubURLProtocol.enqueue(.init(body: json(Painel(titulo: "da-empresa-b", total: 2))))

        let client = makeClient()
        let endpoint = Endpoint<Painel>.get("/v1/painel", cache: .oneHour)

        await client.setScope("empresa-a")
        let primeira = try await client.send(endpoint)
        #expect(primeira.value.titulo == "da-empresa-a")

        await client.setScope("empresa-b")
        let segunda = try await client.send(endpoint)
        #expect(segunda.source == .network)
        #expect(segunda.value.titulo == "da-empresa-b")
        #expect(StubURLProtocol.requestCount == 2)
    }
}

// MARK: - Sessão

@Suite("Configuração da sessão")
struct NetworkSecurityTests {

    /// O cache do sistema grava o corpo das respostas em claro numa pasta que
    /// entra em backup de aparelho.
    @Test("O cache do sistema fica desligado")
    func systemCacheIsOff() {
        let configuration = NetworkSecurity.makeConfiguration()
        #expect(configuration.urlCache == nil)
        #expect(configuration.requestCachePolicy == .reloadIgnoringLocalAndRemoteCacheData)
    }

    @Test("Sem cookie e sem credencial guardada")
    func noCookiesNoCredentials() {
        let configuration = NetworkSecurity.makeConfiguration()
        #expect(configuration.httpCookieStorage == nil)
        #expect(configuration.httpShouldSetCookies == false)
        #expect(configuration.urlCredentialStorage == nil)
    }

    @Test("TLS 1.2 no mínimo")
    func minimumTLS() {
        #expect(NetworkSecurity.makeConfiguration().tlsMinimumSupportedProtocolVersion == .TLSv12)
    }

    /// Sem rede, a chamada tem que falhar rápido para o cache guardado assumir.
    @Test("Não espera a conectividade voltar em silêncio")
    func failsFastWhenOffline() {
        #expect(NetworkSecurity.makeConfiguration().waitsForConnectivity == false)
    }

    @Test("O User-Agent não carrega mais do que versão e plataforma")
    func userAgentIsMinimal() {
        let agent = NetworkSecurity.userAgent
        #expect(agent.contains("iOS"))
        #expect(!agent.contains("@"))
    }
}
