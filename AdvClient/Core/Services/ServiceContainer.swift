import Foundation

/// Raiz de composição: o único lugar que sabe de onde vêm os dados.
///
/// As telas e o `AppState` falam com `AuthService` e `ClientDataRepository` e
/// mais nada. Trocar demonstração por API — ou um provedor jurídico por outro —
/// é decisão daqui, nunca de uma tela.
///
/// O provedor do escritório (Projuris ADV, outro sistema jurídico, DataJud)
/// **não aparece no app**: fica atrás da API canônica, num conector do servidor.
/// O motivo está em `docs/camada-de-servico.md` — em resumo, a credencial desses
/// provedores dá acesso à carteira inteira do escritório e não pode ir dentro
/// de um app que qualquer cliente instala.
struct ServiceContainer: Sendable {
    let auth: AuthService
    let repository: ClientDataRepository
    let session: SessionLifecycle

    /// Dados de demonstração, sem rede.
    static func demo() -> ServiceContainer {
        ServiceContainer(
            auth: MockAuthService(),
            repository: MockClientRepository(),
            session: NoSessionLifecycle()
        )
    }

    /// O que o `Brand.json` da marca pede.
    static func forCurrentBrand() -> ServiceContainer {
        switch BrandConfiguration.current.api.resolvedMode {
        case .demo:
            return .demo()
        case .remote:
            do {
                return try .remote()
            } catch {
                // Marca configurada para a API com endereço inválido: falha
                // visível em cada chamada, nunca dados de demonstração no lugar
                // dos reais.
                return .unavailable(error)
            }
        case .readonly:
            do {
                return try .readOnly()
            } catch {
                // Sem `Config/Secrets.xcconfig`: a falha aparece na tela, e
                // nenhum dado de demonstração passa por processo real.
                return .readOnlyUnavailable(APIError.invalidRequest(reason: "fonte somente leitura sem endereço ou chave"))
            }
        }
    }

    /// Processos do escritório pela fonte somente leitura de teste. O login
    /// é o de demonstração — a fonte não tem login de cliente.
    static func readOnly(
        source: ReadOnlySource? = nil,
        gate: SecurityGate = .shared
    ) throws -> ServiceContainer {
        let source = try source ?? ReadOnlySource.current()
        let authorization = StaticBearerAuthorization(key: source.apiKey)
        let client = LiveAPIClient(baseURL: source.baseURL, authorization: authorization, gate: gate)
        return ServiceContainer(
            auth: MockAuthService(),
            repository: ReadOnlyCasesRepository(client: client),
            session: RemoteSessionLifecycle(client: client, tokens: authorization, gate: gate)
        )
    }

    /// Fonte somente leitura mal configurada: entra com o login de
    /// demonstração e cada carga falha, dizendo que falhou.
    private static func readOnlyUnavailable(_ error: APIError) -> ServiceContainer {
        let failing = UnavailableServices(error: error)
        return ServiceContainer(auth: MockAuthService(), repository: failing, session: NoSessionLifecycle())
    }

    /// A API canônica do produto.
    static func remote(
        tokens: SessionTokenStore = SessionTokenStore(),
        gate: SecurityGate = .shared
    ) throws -> ServiceContainer {
        let client = try LiveAPIClient.forCurrentBrand(authorization: tokens)
        return ServiceContainer(
            auth: RemoteAuthService(client: client, tokens: tokens),
            repository: RemoteClientRepository(client: client),
            session: RemoteSessionLifecycle(client: client, tokens: tokens, gate: gate)
        )
    }

    /// Toda chamada lança `error`.
    static func unavailable(_ error: Error) -> ServiceContainer {
        let failing = UnavailableServices(error: APIError.mapping(error))
        return ServiceContainer(auth: failing, repository: failing, session: NoSessionLifecycle())
    }
}
