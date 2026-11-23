import Foundation

/// Onde está a fonte somente leitura e com que chave falar com ela.
///
/// A chave **não** mora no código: vem de `Config/Secrets.xcconfig` (fora do
/// git), que o build copia para o `Info.plist`, ou da variável de ambiente
/// `ADV_READONLY_API_KEY` do esquema do Xcode, que tem prioridade. O mesmo
/// vale para o endereço (`ADV_READONLY_API_BASE_URL`).
///
/// Atenção: o que vai para o `Info.plist` viaja dentro do app instalado. Serve
/// para teste com os processos do próprio escritório; não para uma chave que
/// abra dados de clientes.
struct ReadOnlySource: Equatable, Sendable {
    let baseURL: URL
    let apiKey: String

    enum ConfigurationError: Error, Equatable {
        case missingBaseURL
        case missingAPIKey
    }

    /// Lê do ambiente e, na falta, do `Info.plist`.
    static func current(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        info: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) throws -> ReadOnlySource {
        func value(env: String, plist: String) -> String? {
            let raw = environment[env] ?? (info[plist] as? String)
            let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // Variável de build não expandida (`$(READONLY_API_KEY)`) conta como ausente.
            guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else { return nil }
            return trimmed
        }

        guard let urlText = value(env: "ADV_READONLY_API_BASE_URL", plist: "ADVReadOnlyAPIBaseURL"),
              let url = URL(string: urlText), url.scheme?.lowercased() == "https", url.host != nil else {
            throw ConfigurationError.missingBaseURL
        }
        guard let key = value(env: "ADV_READONLY_API_KEY", plist: "ADVReadOnlyAPIKey") else {
            throw ConfigurationError.missingAPIKey
        }
        return ReadOnlySource(baseURL: url, apiKey: key)
    }
}

/// Chave fixa no cabeçalho `Authorization`. Não há sessão a renovar nem a
/// descartar: um 401 aqui é configuração errada, não login vencido.
struct StaticBearerAuthorization: AuthorizationProviding {
    let key: String

    func authorizationHeader() async -> String? { "Bearer \(key)" }
    func invalidate() async {}
}
