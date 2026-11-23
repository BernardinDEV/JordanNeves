import Foundation

// MARK: - Corpo de erro do serviço

/// O que o servidor manda junto com um status de erro.
///
/// Aceita as duas convenções que aparecem na prática — a do RFC 9457
/// (`type`/`title`/`detail`) e a informal (`code`/`message`/`errors`) — porque a
/// camada de rede não pode quebrar quando o backend troca de framework.
///
/// **Nada aqui vai para a tela do cliente.** `detail` é texto do servidor: pode
/// vir em inglês, pode citar tabela, pode citar CPF. Quem decide o que o cliente
/// lê é `APIError.userMessage`, que resolve no idioma escolhido no app. O que
/// atravessa para o suporte é `code` e `requestID`, e só.
struct APIProblem: Equatable, Sendable, Decodable {
    /// Identificador estável do erro, legível por máquina (`contract_locked`).
    /// É o único campo em que a UI pode ramificar.
    let code: String?
    /// Texto do servidor. Serve para o log de suporte, nunca para a tela.
    let detail: String?
    /// Correlaciona esta falha com o log do backend.
    let requestID: String?
    /// Erros por campo, quando o serviço valida um formulário.
    let fields: [String: String]

    init(code: String? = nil, detail: String? = nil, requestID: String? = nil, fields: [String: String] = [:]) {
        self.code = code
        self.detail = detail
        self.requestID = requestID
        self.fields = fields
    }

    private enum CodingKeys: String, CodingKey {
        case code, error, type
        case detail, message, title
        case descriptionText = "description"
        case requestID = "requestId"
        case requestIDSnake = "request_id"
        case fields, errors
    }

    /// Decodificação deliberadamente tolerante: um corpo de erro malformado não
    /// pode virar um segundo erro por cima do primeiro e apagar o original.
    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)

        func text(_ keys: CodingKeys...) -> String? {
            guard let container else { return nil }
            for key in keys {
                // `try?` achata o opcional: isto já é `String?`, não `String??`.
                // Chave ausente e chave com tipo errado chegam as duas como nil,
                // que é exatamente o que a tolerância aqui quer.
                if let value = try? container.decodeIfPresent(String.self, forKey: key),
                   !value.isEmpty {
                    return value
                }
            }
            return nil
        }

        func map(_ key: CodingKeys) -> [String: String]? {
            guard let container else { return nil }
            if let flat = try? container.decodeIfPresent([String: String].self, forKey: key), !flat.isEmpty {
                return flat
            }
            if let listed = try? container.decodeIfPresent([String: [String]].self, forKey: key), !listed.isEmpty {
                return listed.mapValues { $0.joined(separator: " ") }
            }
            return nil
        }

        code = text(.code, .error, .type)
        detail = text(.detail, .message, .title, .descriptionText)
        requestID = text(.requestID, .requestIDSnake)
        fields = map(.fields) ?? map(.errors) ?? [:]
    }

    /// Cópia com o `requestID` do cabeçalho, quando o corpo não trouxe um.
    func withRequestID(_ id: String?) -> APIProblem {
        guard requestID == nil, let id, !id.isEmpty else { return self }
        return APIProblem(code: code, detail: detail, requestID: id, fields: fields)
    }
}

// MARK: - O erro do serviço

/// O único erro que a camada de rede lança. Não existe caminho por onde um
/// `URLError`, um `DecodingError` ou um `NSError` cru chegue a quem chamou:
/// tudo passa por `APIError.mapping(_:)` antes.
///
/// Isso existe por três razões, nesta ordem:
///
/// 1. **A tela precisa decidir.** `isRetryable`, `endsSession` e
///    `allowsStaleFallback` respondem, sem `switch` gigante espalhado, se cabe
///    botão de "tentar de novo", se é para derrubar a sessão, e se vale mostrar
///    o dado guardado em vez da tela de erro.
/// 2. **O cliente é leigo em direito e em HTTP.** `userMessage` é a frase que
///    ele lê, no idioma escolhido no app, sem status, sem código, sem inglês.
/// 3. **O suporte precisa rastrear.** `diagnostic` é o que pode ir para o log:
///    status, código e `requestID`. Nunca o corpo, nunca o cabeçalho.
enum APIError: Error, Equatable, Sendable {

    /// Sem rede. Já se sabe que tentar de novo agora não adianta.
    case offline
    /// A requisição estourou o tempo. Vale tentar de novo.
    case timedOut
    /// A tarefa foi cancelada (a tela saiu antes da resposta). Não é falha:
    /// nenhuma UI deve mostrar erro para este caso.
    case cancelled

    /// O aparelho não está em condições de receber dado do cliente: jailbreak,
    /// depurador acoplado ou biblioteca de interceptação carregada. A requisição
    /// não chega a sair.
    case insecureEnvironment
    /// A conexão não pôde ser feita nos termos que o app exige — TLS recusado,
    /// certificado inválido, redirecionamento para outro host ou para `http://`.
    case insecureTransport(reason: String)

    /// Erro de programação: caminho inválido, URL base sem HTTPS, corpo que não
    /// codifica. Nunca deveria chegar a produção — por isso é distinto de 4xx.
    case invalidRequest(reason: String)

    /// 401 — sessão inválida ou expirada. A única que derruba o login.
    case unauthorized(APIProblem?)
    /// 403 — autenticado, mas sem direito a este recurso.
    case forbidden(APIProblem?)
    /// 404 — o recurso não existe (ou o servidor prefere dizer isso).
    case notFound(APIProblem?)
    /// 409/412 — o recurso mudou embaixo do cliente.
    case conflict(APIProblem?)
    /// 400/422 — o servidor recusou os dados enviados. `problem.fields` diz onde.
    case invalidData(APIProblem?)
    /// 429 — excesso de chamadas. `retryAfter` vem do cabeçalho `Retry-After`.
    case rateLimited(retryAfter: TimeInterval?, problem: APIProblem?)
    /// 5xx — o problema é do outro lado.
    case server(status: Int, problem: APIProblem?)
    /// Qualquer outro status que o app não sabe interpretar.
    case unexpectedStatus(status: Int, problem: APIProblem?)

    /// A resposta veio, mas não no formato combinado.
    case malformedResponse(reason: String)

    // MARK: Construção a partir do status

    /// Traduz um status HTTP no caso correspondente. Devolve `nil` para 2xx —
    /// é o que permite escrever `if let error = APIError.from(...) { throw error }`.
    static func from(status: Int, problem: APIProblem?, retryAfter: TimeInterval? = nil) -> APIError? {
        switch status {
        case 200..<300:
            return nil
        case 300..<400:
            // Redirecionamento que sobrou: a política de redirecionamento já
            // recusou o salto, então o 3xx chegando aqui é justamente o caso
            // bloqueado — não um sucesso.
            return .insecureTransport(reason: "redirecionamento recusado (\(status))")
        case 400, 422:
            return .invalidData(problem)
        case 401:
            return .unauthorized(problem)
        case 403:
            return .forbidden(problem)
        case 404, 410:
            return .notFound(problem)
        case 409, 412:
            return .conflict(problem)
        case 429:
            return .rateLimited(retryAfter: retryAfter, problem: problem)
        case 500...599:
            return .server(status: status, problem: problem)
        default:
            return .unexpectedStatus(status: status, problem: problem)
        }
    }

    /// Traduz qualquer erro do sistema. É o funil por onde `URLError`,
    /// `DecodingError` e `CancellationError` obrigatoriamente passam.
    static func mapping(_ error: Error) -> APIError {
        if let api = error as? APIError { return api }
        if error is CancellationError { return .cancelled }

        if let decoding = error as? DecodingError {
            return .malformedResponse(reason: describe(decoding))
        }

        let urlError = error as? URLError
            ?? URLError(URLError.Code(rawValue: (error as NSError).code) ?? .unknown)
        switch urlError.code {
        case .cancelled:
            return .cancelled
        case .timedOut:
            return .timedOut
        case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff:
            return .offline
        case .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .resourceUnavailable:
            // Não é "sem internet" — é servidor fora do ar ou rota quebrada.
            // Vale uma nova tentativa, ao contrário de `.offline`.
            return .server(status: 0, problem: nil)
        case .secureConnectionFailed,
             .serverCertificateUntrusted,
             .serverCertificateHasBadDate,
             .serverCertificateHasUnknownRoot,
             .serverCertificateNotYetValid,
             .clientCertificateRejected,
             .clientCertificateRequired,
             .appTransportSecurityRequiresSecureConnection:
            return .insecureTransport(reason: "TLS: \(urlError.code.rawValue)")
        case .cannotDecodeContentData, .cannotDecodeRawData, .cannotParseResponse, .zeroByteResource:
            return .malformedResponse(reason: "resposta ilegível (\(urlError.code.rawValue))")
        default:
            return .unexpectedStatus(status: 0, problem: nil)
        }
    }

    /// Descrição de um erro de decodificação **sem valores**: só o caminho da
    /// chave. O valor que falhou pode ser o CNPJ do cliente, e log de app vai
    /// para relatório de diagnóstico.
    private static func describe(_ error: DecodingError) -> String {
        func path(_ context: DecodingError.Context) -> String {
            let keys = context.codingPath.map(\.stringValue)
            return keys.isEmpty ? "(raiz)" : keys.joined(separator: ".")
        }
        switch error {
        case let .keyNotFound(key, context):
            return "campo ausente: \(path(context)).\(key.stringValue)"
        case let .typeMismatch(_, context):
            return "tipo inesperado em: \(path(context))"
        case let .valueNotFound(_, context):
            return "valor nulo em: \(path(context))"
        case let .dataCorrupted(context):
            return "dado corrompido em: \(path(context))"
        @unknown default:
            return "falha de decodificação"
        }
    }

    // MARK: Decisões que a UI toma a partir do erro

    /// Vale oferecer "tentar de novo"? Falha de transporte e 5xx, sim. Recusa do
    /// servidor por dado ou permissão, não — repetir dá o mesmo resultado.
    var isRetryable: Bool {
        switch self {
        case .timedOut, .server, .rateLimited:
            return true
        case .offline:
            // Tecnicamente repetível, mas só depois que a rede voltar. A tela
            // trata `.offline` como estado, não como botão.
            return false
        case .cancelled, .insecureEnvironment, .insecureTransport, .invalidRequest,
             .unauthorized, .forbidden, .notFound, .conflict, .invalidData, .unexpectedStatus,
             .malformedResponse:
            return false
        }
    }

    /// Só 401 derruba a sessão. 403 não: o usuário continua sendo quem é, apenas
    /// não pode ver aquele processo — deslogar por isso seria um bug de suporte
    /// recorrente.
    var endsSession: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    /// Se cabe responder com o que está guardado em cache, ainda que vencido.
    ///
    /// Vale para falha de infraestrutura. Não vale para 401/403: mostrar dado
    /// guardado a quem o servidor acabou de recusar é exatamente o vazamento que
    /// o cache não pode causar.
    var allowsStaleFallback: Bool {
        switch self {
        case .offline, .timedOut, .server, .rateLimited:
            return true
        default:
            return false
        }
    }

    /// O status **canônico da classe do erro**, não necessariamente o que veio
    /// no fio: 400 e 422 caem os dois em `.invalidData`, e este acessor devolve
    /// 422 para ambos. Para cruzar com o log do backend use `requestID`, que é
    /// exato. `.server` e `.unexpectedStatus` carregam o status de verdade.
    var httpStatus: Int? {
        switch self {
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .conflict: return 409
        case .invalidData: return 422
        case .rateLimited: return 429
        case let .server(status, _): return status == 0 ? nil : status
        case let .unexpectedStatus(status, _): return status == 0 ? nil : status
        default: return nil
        }
    }

    var problem: APIProblem? {
        switch self {
        case let .unauthorized(problem), let .forbidden(problem), let .notFound(problem),
             let .conflict(problem), let .invalidData(problem):
            return problem
        case let .rateLimited(_, problem), let .server(_, problem), let .unexpectedStatus(_, problem):
            return problem
        default:
            return nil
        }
    }

    /// Código estável do serviço, quando veio. É onde a UI pode ramificar sem
    /// depender de texto.
    var code: String? { problem?.code }

    /// Para o suporte cruzar com o log do backend.
    var requestID: String? { problem?.requestID }

    // MARK: O que vai para o log

    /// Resumo seguro para log: status, código e correlação. Sem corpo, sem
    /// cabeçalho, sem `detail`, sem caminho com identificador.
    var diagnostic: String {
        var parts: [String] = [label]
        if let httpStatus { parts.append("status=\(httpStatus)") }
        if let code { parts.append("code=\(code)") }
        if let requestID { parts.append("req=\(requestID)") }
        return parts.joined(separator: " ")
    }

    private var label: String {
        switch self {
        case .offline: return "offline"
        case .timedOut: return "timeout"
        case .cancelled: return "cancelado"
        case .insecureEnvironment: return "ambiente comprometido"
        case let .insecureTransport(reason): return "transporte inseguro (\(reason))"
        case let .invalidRequest(reason): return "requisição inválida (\(reason))"
        case .unauthorized: return "não autenticado"
        case .forbidden: return "sem permissão"
        case .notFound: return "não encontrado"
        case .conflict: return "conflito"
        case .invalidData: return "dados recusados"
        case .rateLimited: return "excesso de chamadas"
        case .server: return "erro do servidor"
        case .unexpectedStatus: return "status inesperado"
        case let .malformedResponse(reason): return "resposta malformada (\(reason))"
        }
    }

    // MARK: O que o cliente lê

    /// A frase que vai para a tela, no idioma escolhido **no app**.
    ///
    /// Passa por `Format.string`, não por `String(localized:)` puro: quem trocou
    /// o idioma no Perfil tem que ver o erro no idioma que escolheu, não no do
    /// aparelho.
    ///
    /// Nenhuma variante cita status, código ou texto do servidor. Um cliente de
    /// escritório de advocacia lendo "502 Bad Gateway" só aprende que o app
    /// quebrou; lendo "tente de novo em alguns minutos" ele sabe o que fazer.
    var userMessage: String {
        switch self {
        case .offline:
            return Format.string("network.error.offline")
        case .timedOut:
            return Format.string("network.error.timedOut")
        case .cancelled:
            // Não deveria chegar à tela. Se chegou, uma frase neutra é melhor
            // do que uma frase de erro para algo que o próprio app cancelou.
            return Format.string("network.error.generic")
        case .insecureEnvironment:
            return Format.string("network.error.insecureEnvironment")
        case .insecureTransport:
            return Format.string("network.error.insecureTransport")
        case .unauthorized:
            return Format.string("network.error.unauthorized")
        case .forbidden:
            return Format.string("network.error.forbidden")
        case .notFound:
            return Format.string("network.error.notFound")
        case .conflict:
            return Format.string("network.error.conflict")
        case .invalidData:
            return Format.string("network.error.invalidData")
        case .rateLimited:
            return Format.string("network.error.rateLimited")
        case .server:
            return Format.string("network.error.server")
        case .invalidRequest, .unexpectedStatus, .malformedResponse:
            return Format.string("network.error.generic")
        }
    }
}

extension APIError: LocalizedError {
    /// Segue o mesmo padrão de `AuthError`: `localizedDescription` é a frase do
    /// cliente, para que qualquer `catch` genérico já mostre a coisa certa.
    var errorDescription: String? { userMessage }
}
