import Foundation

/// Endpoints da fonte somente leitura.
enum ReadOnlyAPI {
    /// O ngrok devolve uma página de aviso em HTML em vez do JSON quando
    /// este cabeçalho falta.
    static let headers = ["ngrok-skip-browser-warning": "1"]

    /// Um minuto sem rede; depois, até uma semana servindo o guardado se a
    /// fonte cair — o túnel de teste não fica no ar o tempo todo.
    static let cache = CachePolicy.custom(ttl: 60, staleWindow: 7 * 86_400)

    static func processes() -> Endpoint<ProcessListDTO> {
        Endpoint(method: .get, path: "/app/v1/processos", headers: headers, cache: cache)
    }
}

/// `ClientDataRepository` sobre a fonte somente leitura: processos do próprio
/// escritório, sem explicação, sem documentos, sem ações.
///
/// Serve para testar o app com processos reais antes de a API do produto
/// existir. Não separa clientes: mostra tudo o que a chave enxerga.
struct ReadOnlyCasesRepository: ClientDataRepository {
    let client: APIClient

    func snapshot(for companyID: UUID) async throws -> ClientSnapshot {
        do {
            return try await client.value(ReadOnlyAPI.processes()).domain()
        } catch APIError.unauthorized(let problem) {
            // Chave errada ou ausente é configuração, não sessão vencida: o
            // app avisa a falha e mantém o login.
            throw APIError.forbidden(problem)
        }
    }

    func confirmHearing(caseID: UUID) async throws -> ClientSnapshot {
        throw APIError.forbidden(nil)
    }

    func resolvePendency(id: UUID) async throws -> ClientSnapshot {
        throw APIError.forbidden(nil)
    }

    func upload(_ file: UploadFile, caseID: UUID?) async throws -> ClientSnapshot {
        throw APIError.forbidden(nil)
    }

    func recordWhatsAppHandoff(caseID: UUID?) async {}
}
