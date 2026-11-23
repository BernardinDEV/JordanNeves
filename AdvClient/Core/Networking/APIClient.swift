import Foundation

// MARK: - Autorização

/// De onde sai o cabeçalho `Authorization`.
///
/// Costura, não implementação: hoje o app entra por código de seis dígitos mais
/// biometria e ainda não carrega token. Quando o backend existir, o token vive
/// atrás deste protocolo — **no Keychain**, nunca em `UserDefaults`, nunca numa
/// propriedade que sobreviva em um dump de memória mais do que o necessário — e
/// nenhuma tela precisa saber disso.
///
/// A renovação automática em 401 ainda não está aqui, de propósito: fazer isso
/// direito envolve uma única renovação concorrente para não disparar uma
/// tempestade de refresh, e é trabalho para quando o contrato do backend estiver
/// definido. Até lá, 401 derruba a sessão, que é o comportamento seguro.
protocol AuthorizationProviding: Sendable {
    /// Valor do cabeçalho (`Bearer …`), ou `nil` para sair anônimo.
    func authorizationHeader() async -> String?
    /// Chamado depois de um 401, para o provedor descartar o que tem.
    func invalidate() async
}

/// Padrão enquanto não há backend: toda chamada sai sem autorização.
struct NoAuthorization: AuthorizationProviding {
    func authorizationHeader() async -> String? { nil }
    func invalidate() async {}
}

// MARK: - Resultado

/// Uma resposta e **de onde ela veio**.
///
/// O `source` não é diagnóstico, é conteúdo: este app mostra `lastSyncedAt` ao
/// cliente literalmente, e a regra da casa é que ele nunca sugira que o dado é
/// mais recente do que é. Uma tela que recebe `.staleCache` tem a obrigação de
/// dizer que está mostrando o que guardou, e desde quando.
struct Fetched<Value: Sendable>: Sendable {

    enum Source: String, Sendable, Equatable {
        /// Veio do servidor agora.
        case network
        /// Veio do cache, dentro da validade.
        case cache
        /// Veio do cache **vencido**, porque a rede falhou.
        case staleCache
    }

    let value: Value
    let source: Source
    /// Quando este dado saiu do servidor — não quando esta chamada aconteceu.
    let servedAt: Date

    var isFromCache: Bool { source != .network }
    var isStale: Bool { source == .staleCache }
}

// MARK: - Contrato

/// A única porta de saída de rede do app.
///
/// Nenhuma tela, nenhum repositório e nenhum serviço monta `URLRequest` por
/// conta própria. Não é preciosismo de arquitetura: cache com escopo de conta,
/// bloqueio de ambiente comprometido, política de redirecionamento e redação de
/// log valem para o que passa por aqui, e só. Uma chamada solta com
/// `URLSession.shared` contorna as quatro coisas de uma vez.
protocol APIClient: Sendable {
    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint<Response>) async throws -> Fetched<Response>
    /// Amarra o cache à conta logada. Chamar no login e no logout.
    func setScope(_ scope: String?) async
    /// Apaga tudo que está guardado. Obrigatório no logout.
    func purgeCache() async
}

extension APIClient {
    /// Quando a origem do dado não importa para a tela.
    func value<Response: Decodable & Sendable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        try await send(endpoint).value
    }
}

// MARK: - Resposta crua

/// O que voltou do transporte, em forma transportável entre tarefas.
///
/// Existe porque `HTTPURLResponse` é classe e não atravessa fronteira de
/// concorrência sem ressalva. Reduzir a resposta a valores aqui deixa o resto
/// da camada livre de `@unchecked`.
struct RawResponse: Sendable, Equatable {
    let data: Data
    let status: Int
    /// Nomes em minúscula: cabeçalho HTTP não distingue caixa, e servidor
    /// nenhum concorda sobre como escrever `X-Request-Id`.
    let headers: [String: String]

    init(data: Data, status: Int, headers: [String: String]) {
        self.data = data
        self.status = status
        self.headers = headers
    }

    init(data: Data, response: HTTPURLResponse) {
        var normalized: [String: String] = [:]
        for (name, value) in response.allHeaderFields {
            guard let name = name as? String else { continue }
            normalized[name.lowercased()] = String(describing: value)
        }
        self.init(data: data, status: response.statusCode, headers: normalized)
    }

    var retryAfterSeconds: TimeInterval? {
        guard let raw = headers["retry-after"], let seconds = TimeInterval(raw) else { return nil }
        return max(0, seconds)
    }

    var requestID: String? {
        headers["x-request-id"] ?? headers["x-correlation-id"]
    }

    private var isJSON: Bool {
        headers["content-type"]?.lowercased().contains("json") ?? false
    }

    /// Interpreta o corpo de erro. Nunca lança: um corpo de erro ilegível não
    /// pode apagar o status, que é a informação que de fato importa.
    func problem() -> APIProblem? {
        if !data.isEmpty, isJSON, let decoded = try? JSONDecoder().decode(APIProblem.self, from: data) {
            return decoded.withRequestID(requestID)
        }
        if let requestID {
            return APIProblem(requestID: requestID)
        }
        return nil
    }
}

// MARK: - Transporte

/// A chamada em si, com nova tentativa.
///
/// Só repete o que é seguro repetir: falha de infraestrutura (timeout, conexão
/// perdida, 5xx, 429) **e** método idempotente. Reenviar um `POST` que talvez
/// tenha chegado é como o cliente acaba com dois envios do mesmo documento e o
/// escritório com duas cópias para conferir.
enum HTTPTransport {

    static let maxAttempts = 3

    static func perform(
        _ request: URLRequest,
        session: URLSession,
        idempotent: Bool,
        path: String
    ) async throws -> RawResponse {
        var attempt = 0
        while true {
            attempt += 1
            try Task.checkCancellation()
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw APIError.malformedResponse(reason: "resposta não-HTTP")
                }
                let raw = RawResponse(data: data, response: http)

                if attempt < maxAttempts, idempotent,
                   let delay = retryDelay(status: raw.status, retryAfter: raw.retryAfterSeconds, attempt: attempt) {
                    NetworkLog.retry(path: path, attempt: attempt, delay: delay)
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }
                return raw
            } catch let error as APIError {
                throw error
            } catch {
                let mapped = APIError.mapping(error)
                guard attempt < maxAttempts, idempotent, mapped.isRetryable,
                      let delay = retryDelay(status: nil, retryAfter: nil, attempt: attempt) else {
                    throw mapped
                }
                NetworkLog.retry(path: path, attempt: attempt, delay: delay)
                try await Task.sleep(for: .seconds(delay))
            }
        }
    }

    /// Espera antes da próxima tentativa, ou `nil` quando não se deve repetir.
    ///
    /// Exponencial com um pouco de aleatoriedade: sem o ruído, todos os
    /// aparelhos que falharam no mesmo minuto voltam juntos e derrubam de novo o
    /// servidor que estava se recuperando.
    static func retryDelay(status: Int?, retryAfter: TimeInterval?, attempt: Int) -> TimeInterval? {
        if let status {
            let worthRetrying = status == 429 || (500...599).contains(status)
            // 501 é "o servidor não faz isso". Repetir não muda a resposta.
            guard worthRetrying, status != 501 else { return nil }
        }
        let jitter = Double.random(in: 0...0.25)
        if let retryAfter {
            // Servidor pedindo espera longa não é caso de insistir por baixo dos
            // panos — o erro sobe e a tela decide o que dizer.
            guard retryAfter <= 5 else { return nil }
            return retryAfter + jitter
        }
        return min(4, pow(2, Double(attempt - 1)) * 0.5) + jitter
    }
}

// MARK: - Cliente

/// A implementação real.
///
/// Ator porque tem estado que várias telas tocam ao mesmo tempo: o escopo do
/// cache e a tabela de requisições em voo. As duas coisas erradas sob
/// concorrência seriam o cache de uma conta respondendo à outra e a mesma
/// chamada saindo três vezes porque três telas abriram juntas.
actor LiveAPIClient: APIClient {

    private static let anonymousScope = "anonimo"

    private let baseURL: URL
    private let session: URLSession
    private let cache: ResponseCache
    private let authorization: AuthorizationProviding
    private let gate: SecurityGate
    private let decoder: JSONDecoder

    private var scope: String = LiveAPIClient.anonymousScope
    /// Chamadas iguais em voo. Duas telas pedindo o mesmo painel no mesmo
    /// instante viram uma requisição e duas respostas.
    private var inFlight: [String: Task<RawResponse, Error>] = [:]

    init(
        baseURL: URL,
        session: URLSession? = nil,
        cache: ResponseCache = .shared,
        authorization: AuthorizationProviding = NoAuthorization(),
        gate: SecurityGate = .shared,
        decoder: JSONDecoder = .api
    ) {
        self.baseURL = baseURL
        self.session = session ?? NetworkSecurity.makeSession()
        self.cache = cache
        self.authorization = authorization
        self.gate = gate
        self.decoder = decoder
    }

    /// Cliente apontado para a API da marca que está rodando.
    ///
    /// Lança em vez de `fatalError` porque um `Brand.json` de escritório novo
    /// pode chegar com `api.baseURL` por preencher, e isso tem que virar uma
    /// falha visível de configuração — não um crash no lançamento.
    static func forCurrentBrand(
        authorization: AuthorizationProviding = NoAuthorization()
    ) throws -> LiveAPIClient {
        let raw = BrandConfiguration.current.api.baseURL
        guard let url = URL(string: raw), url.scheme?.lowercased() == "https", url.host != nil else {
            throw APIError.invalidRequest(reason: "Brand.json: api.baseURL precisa ser uma URL https")
        }
        return LiveAPIClient(baseURL: url, authorization: authorization)
    }

    // MARK: Sessão

    /// Amarra o cache à conta. O identificador da empresa basta e é o certo:
    /// não é dado sensível, e entra numa função de resumo antes de virar nome
    /// de arquivo.
    func setScope(_ scope: String?) {
        let next = scope ?? Self.anonymousScope
        guard next != self.scope else { return }
        self.scope = next
        inFlight.removeAll()
    }

    func purgeCache() async {
        inFlight.removeAll()
        await cache.purgeAll()
    }

    // MARK: A chamada

    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint<Response>) async throws -> Fetched<Response> {
        try Task.checkCancellation()

        // 1. Portaria. Nada sai de um aparelho comprometido, e o que estava
        //    guardado nele sai de cena junto.
        if await gate.isCompromised() {
            await cache.purgeAll()
            NetworkLog.blocked(path: endpoint.path, reason: "ambiente comprometido")
            throw APIError.insecureEnvironment
        }

        let policy = endpoint.cache
        let cacheable = endpoint.method == .get && policy.isEnabled
        let key = ResponseCache.key(scope: scope, canonical: endpoint.canonicalKey)

        // 2. Cache dentro da validade: responde sem tocar na rede.
        if cacheable, let stored = await cache.read(key), stored.isFresh() {
            if let value = try? decoder.decode(Response.self, from: stored.data) {
                NetworkLog.served(path: endpoint.path, status: 200, source: "cache", duration: 0)
                return Fetched(value: value, source: .cache, servedAt: stored.storedAt)
            }
            // Guardado num formato que o app não entende mais (o modelo mudou):
            // descarta em vez de insistir.
            await cache.remove(key)
        }

        // 3. Monta a requisição.
        var request = try endpoint.makeRequest(baseURL: baseURL)
        if endpoint.requiresAuthentication, let header = await authorization.authorizationHeader() {
            request.setValue(header, forHTTPHeaderField: "Authorization")
        }

        NetworkLog.request(method: endpoint.method.rawValue, path: endpoint.path)
        let startedAt = Date.now

        // 4. Vai à rede.
        let raw: RawResponse
        do {
            raw = try await performCoalesced(
                request: request,
                key: key,
                coalesce: endpoint.method == .get,
                idempotent: endpoint.method.isIdempotent,
                path: endpoint.path
            )
        } catch {
            let mapped = APIError.mapping(error)
            NetworkLog.failure(mapped, path: endpoint.path)
            if let fallback: Fetched<Response> = await staleFallback(for: mapped, key: key, cacheable: cacheable) {
                NetworkLog.served(
                    path: endpoint.path,
                    status: 0,
                    source: "cache-vencido",
                    duration: Date.now.timeIntervalSince(startedAt)
                )
                return fallback
            }
            throw mapped
        }

        // 5. Status.
        if let error = APIError.from(status: raw.status, problem: raw.problem(), retryAfter: raw.retryAfterSeconds) {
            NetworkLog.failure(error, path: endpoint.path)
            if error.endsSession {
                await authorization.invalidate()
                // Sessão recusada: o que estava guardado para ela sai junto. Um
                // cache que sobrevive ao 401 é dado do cliente num aparelho que
                // o servidor acabou de dizer que não deveria ter acesso.
                await cache.purgeAll()
                inFlight.removeAll()
            }
            if let fallback: Fetched<Response> = await staleFallback(for: error, key: key, cacheable: cacheable) {
                return fallback
            }
            throw error
        }

        // 6. Decodifica e guarda.
        let value = try decode(Response.self, from: raw.data)
        if cacheable {
            await cache.store(raw.data, for: key, policy: policy)
        }
        NetworkLog.served(
            path: endpoint.path,
            status: raw.status,
            source: "rede",
            duration: Date.now.timeIntervalSince(startedAt)
        )
        return Fetched(value: value, source: .network, servedAt: .now)
    }

    // MARK: Peças

    private func performCoalesced(
        request: URLRequest,
        key: String,
        coalesce: Bool,
        idempotent: Bool,
        path: String
    ) async throws -> RawResponse {
        if coalesce, let existing = inFlight[key] {
            return try await existing.value
        }

        let session = self.session
        let task = Task.detached(priority: .userInitiated) {
            try await HTTPTransport.perform(request, session: session, idempotent: idempotent, path: path)
        }
        if coalesce {
            inFlight[key] = task
        }
        defer {
            if coalesce {
                inFlight[key] = nil
            }
        }
        return try await task.value
    }

    /// O dado guardado, vencido, quando a rede falhou e o erro permite.
    ///
    /// Não vale para 401 e 403 — `allowsStaleFallback` já corta: entregar o
    /// cache a quem o servidor acabou de recusar é o vazamento que este cache
    /// não pode causar.
    private func staleFallback<Response: Decodable & Sendable>(
        for error: APIError,
        key: String,
        cacheable: Bool
    ) async -> Fetched<Response>? {
        guard cacheable, error.allowsStaleFallback else { return nil }
        guard let stored = await cache.read(key), stored.isServableWhenStale() else { return nil }
        guard let value = try? decoder.decode(Response.self, from: stored.data) else { return nil }
        return Fetched(value: value, source: .staleCache, servedAt: stored.storedAt)
    }

    private func decode<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response {
        // `204 No Content` e afins: o corpo vazio é a resposta.
        if data.isEmpty, let empty = EmptyResponse() as? Response {
            return empty
        }
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.mapping(error)
        }
    }
}
