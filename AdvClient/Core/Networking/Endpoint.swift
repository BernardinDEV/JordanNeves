import Foundation

// MARK: - Método

enum HTTPMethod: String, Sendable, Equatable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    /// Repetir a chamada produz o mesmo efeito. É o que autoriza uma nova
    /// tentativa automática: reenviar um `POST` que talvez tenha chegado é como
    /// o cliente acaba com dois envios do mesmo contrato.
    var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete: return true
        case .post, .patch: return false
        }
    }
}

// MARK: - Corpo

/// Corpo já serializado. A serialização acontece na montagem do `Endpoint`, não
/// na hora do envio, para que um modelo que não codifica falhe onde o
/// programador está olhando e não dentro de um retry.
struct HTTPBody: Sendable, Equatable {
    let data: Data
    let contentType: String

    static func raw(_ data: Data, contentType: String) -> HTTPBody {
        HTTPBody(data: data, contentType: contentType)
    }

    static func json<Value: Encodable>(_ value: Value, encoder: JSONEncoder = .api) throws -> HTTPBody {
        do {
            return HTTPBody(data: try encoder.encode(value), contentType: "application/json; charset=utf-8")
        } catch {
            throw APIError.invalidRequest(reason: "corpo não codificável (\(Value.self))")
        }
    }
}

// MARK: - Política de cache

/// Por quanto tempo a resposta desta chamada vale, e onde ela pode ficar
/// guardada.
///
/// São duas janelas, não uma:
///
/// - `ttl` — enquanto durar, o app responde do cache **sem tocar na rede**.
/// - `staleWindow` — passado o `ttl`, o dado deixa de ser servido em condições
///   normais, mas continua guardado; se a rede falhar, ele é entregue marcado
///   como velho (`Fetched.source == .staleCache`) em vez de uma tela de erro.
///
/// A segunda janela existe porque este app já mostra `lastSyncedAt` ao cliente
/// literalmente. Entregar dado de ontem, dizendo que é de ontem, é melhor do que
/// uma tela vazia — e é honesto, que é a regra da casa.
struct CachePolicy: Sendable, Equatable {

    enum Storage: Sendable, Equatable {
        /// Não guarda nada. Padrão de tudo que não é `GET`.
        case none
        /// Só memória: morre ao encerrar o app. Para o que não pode tocar o disco.
        case memory
        /// Memória e disco criptografado. Sobrevive ao relançamento.
        case memoryAndDisk
    }

    /// Enquanto durar, responde do cache sem ir à rede.
    var ttl: TimeInterval
    /// Depois do `ttl`, por quanto tempo ainda serve como resposta de emergência.
    var staleWindow: TimeInterval
    var storage: Storage

    /// Sempre rede. É o padrão de qualquer `Endpoint` que não declare outra coisa.
    static let none = CachePolicy(ttl: 0, staleWindow: 0, storage: .none)

    /// **Uma hora.** Para o que muda ao longo do dia e o cliente reabre várias
    /// vezes: painel, lista de processos, notificações. Guardado em disco, com
    /// um dia de janela de emergência.
    static let oneHour = CachePolicy(ttl: 3_600, staleWindow: 86_400, storage: .memoryAndDisk)

    /// **Um dia.** Para o que muda por decisão do escritório, não pelo relógio:
    /// contratos, dados cadastrais da empresa, catálogos. Uma semana de janela
    /// de emergência.
    static let oneDay = CachePolicy(ttl: 86_400, staleWindow: 7 * 86_400, storage: .memoryAndDisk)

    /// Uma hora **sem tocar o disco**. Para resposta que contém algo que não
    /// deve sobreviver ao processo — URL assinada de documento, por exemplo.
    static let oneHourInMemory = CachePolicy(ttl: 3_600, staleWindow: 0, storage: .memory)

    static func custom(ttl: TimeInterval, staleWindow: TimeInterval = 0, storage: Storage = .memoryAndDisk) -> CachePolicy {
        CachePolicy(ttl: ttl, staleWindow: staleWindow, storage: storage)
    }

    var isEnabled: Bool { storage != .none && ttl > 0 }
    var writesToDisk: Bool { storage == .memoryAndDisk }
}

// MARK: - Endpoint

/// Uma resposta vazia (`204`, `200` sem corpo). Use como `Response` quando a
/// chamada só confirma que algo aconteceu.
struct EmptyResponse: Decodable, Sendable, Equatable {
    init() {}
    init(from decoder: Decoder) throws {}
}

/// A descrição de uma chamada — o que ela pede, e sob que regras.
///
/// É um valor, não uma função: dá para construir, comparar e testar sem rede.
/// O tipo da resposta viaja no genérico, então `client.send(.painel)` já devolve
/// `Fetched<ClientSnapshotDTO>` sem ninguém precisar repetir o tipo.
struct Endpoint<Response: Decodable & Sendable>: Sendable {

    var method: HTTPMethod
    /// Caminho relativo à base (`/v1/cases`). A base vem do `Brand.json`.
    var path: String
    /// Parâmetros de consulta. Dicionário, e não lista, para que a chave de
    /// cache seja estável: a mesma chamada com os parâmetros em outra ordem
    /// tem que bater no mesmo cache.
    var query: [String: String]
    var headers: [String: String]
    var body: HTTPBody?
    var cache: CachePolicy
    var timeout: TimeInterval
    /// Quando falso, a chamada sai sem cabeçalho de autorização.
    var requiresAuthentication: Bool

    init(
        method: HTTPMethod = .get,
        path: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        body: HTTPBody? = nil,
        cache: CachePolicy = .none,
        timeout: TimeInterval = 20,
        requiresAuthentication: Bool = true
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
        self.cache = cache
        self.timeout = timeout
        self.requiresAuthentication = requiresAuthentication
    }

    // MARK: Construtores curtos

    static func get(
        _ path: String,
        query: [String: String] = [:],
        cache: CachePolicy = .none,
        timeout: TimeInterval = 20
    ) -> Endpoint {
        Endpoint(method: .get, path: path, query: query, cache: cache, timeout: timeout)
    }

    static func post(
        _ path: String,
        body: HTTPBody? = nil,
        query: [String: String] = [:],
        timeout: TimeInterval = 30
    ) -> Endpoint {
        Endpoint(method: .post, path: path, query: query, body: body, cache: .none, timeout: timeout)
    }

    static func put(
        _ path: String,
        body: HTTPBody? = nil,
        timeout: TimeInterval = 30
    ) -> Endpoint {
        Endpoint(method: .put, path: path, body: body, cache: .none, timeout: timeout)
    }

    static func delete(_ path: String, timeout: TimeInterval = 30) -> Endpoint {
        Endpoint(method: .delete, path: path, cache: .none, timeout: timeout)
    }

    // MARK: Identidade da chamada

    /// Descrição canônica da chamada, usada como base da chave de cache.
    /// Ordenada, para que a ordem em que alguém escreveu os parâmetros não
    /// produza duas entradas para a mesma coisa.
    var canonicalKey: String {
        let sorted = query
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        return sorted.isEmpty
            ? "\(method.rawValue) \(normalizedPath)"
            : "\(method.rawValue) \(normalizedPath)?\(sorted)"
    }

    private var normalizedPath: String {
        path.hasPrefix("/") ? path : "/" + path
    }

    // MARK: Montagem

    /// Constrói a `URLRequest`.
    ///
    /// Recusa base que não seja HTTPS aqui, e não só no ATS: o `Info.plist`
    /// protege o app instalado, esta linha protege contra alguém apontar o
    /// `Brand.json` de um escritório novo para `http://` em um build de teste e
    /// isso passar despercebido até a loja.
    func makeRequest(baseURL: URL) throws -> URLRequest {
        guard baseURL.scheme?.lowercased() == "https" else {
            throw APIError.invalidRequest(reason: "a URL base precisa ser https")
        }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidRequest(reason: "URL base inválida")
        }

        let base = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = base + normalizedPath
        if !query.isEmpty {
            components.queryItems = query
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw APIError.invalidRequest(reason: "caminho inválido")
        }

        var request = URLRequest(
            url: url,
            // O cache é o desta camada, criptografado e com escopo de conta. O
            // `URLCache` do sistema grava JSON em claro numa pasta que qualquer
            // backup de aparelho carrega junto — ele fica fora do caminho.
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: timeout
        )
        request.httpMethod = method.rawValue
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        // Faz o servidor responder erro no idioma escolhido no app, não no do
        // aparelho — mesma regra do resto dos textos.
        request.setValue(Format.uiLocale.identifier, forHTTPHeaderField: "Accept-Language")

        if let body {
            request.httpBody = body.data
            request.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
        }
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}

// MARK: - Codificação

extension JSONDecoder {
    /// O decodificador do serviço.
    ///
    /// Datas em ISO 8601 aceitando com e sem fração de segundo, porque a
    /// diferença entre um backend Java e um Node é exatamente essa e não vale um
    /// incidente. Sem estratégia de chave: o contrato do JSON fica explícito nos
    /// `CodingKeys` de cada DTO, onde dá para ler.
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601Parsing.date(from: text) { return date }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "data fora do formato ISO 8601"
                )
            )
        }
        return decoder
    }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601Parsing.string(from: date))
        }
        return encoder
    }
}

enum ISO8601Parsing {
    nonisolated(unsafe) private static let withFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let withoutFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Só data, sem hora (`2026-09-14`) — comum em prazo processual.
    nonisolated(unsafe) private static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func date(from text: String) -> Date? {
        withFraction.date(from: text)
            ?? withoutFraction.date(from: text)
            ?? dateOnly.date(from: text)
    }

    static func string(from date: Date) -> String {
        withoutFraction.string(from: date)
    }
}
