import Foundation
import OSLog

/// Log da camada de rede, redigido na origem.
///
/// A regra é uma só: **nada que identifique o cliente entra em log.** Não é
/// zelo excessivo — log de app iOS vai para o relatório de diagnóstico que o
/// aparelho compartilha, aparece no console de quem estiver com o iPhone
/// plugado, e sai do controle do escritório no instante em que é escrito. Um
/// número de processo em log é o processo de uma empresa real.
///
/// Por isso, o que passa por aqui:
///
/// - **caminho sem identificador** — `/v1/cases/{id}/movements`, nunca o UUID;
/// - **sem parâmetros de consulta** — é onde vai e-mail, CNPJ e filtro;
/// - **sem corpo**, nem de requisição nem de resposta;
/// - **sem cabeçalho** — `Authorization` acima de todos;
/// - de erro, só `APIError.diagnostic`: status, código estável e `requestID`.
enum NetworkLog {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "br.adv.advclient",
        category: "network"
    )

    // MARK: Ciclo da requisição

    static func request(method: String, path: String) {
        logger.debug("→ \(method, privacy: .public) \(redact(path), privacy: .public)")
    }

    static func served(path: String, status: Int, source: String, duration: TimeInterval) {
        let millis = Int((duration * 1000).rounded())
        logger.info("← \(status, privacy: .public) \(redact(path), privacy: .public) [\(source, privacy: .public)] \(millis, privacy: .public)ms")
    }

    static func failure(_ error: APIError, path: String) {
        logger.error("✕ \(redact(path), privacy: .public) — \(error.diagnostic, privacy: .public)")
    }

    static func retry(path: String, attempt: Int, delay: TimeInterval) {
        logger.debug("↻ \(redact(path), privacy: .public) tentativa \(attempt, privacy: .public) em \(delay, privacy: .public)s")
    }

    // MARK: Segurança

    /// Requisição barrada antes de sair. Registrada no nível de falha porque é
    /// um evento de segurança, não um erro de rede.
    static func blocked(path: String, reason: String) {
        logger.fault("⛔︎ \(redact(path), privacy: .public) bloqueado: \(reason, privacy: .public)")
    }

    static func warning(_ message: String) {
        logger.warning("⚠︎ \(message, privacy: .public)")
    }

    // MARK: Redação

    /// Tira da rota tudo que identifica alguém.
    ///
    /// Descarta a consulta inteira e troca por `{id}` todo trecho que pareça
    /// identificador — UUID, número de processo, sequência de dígitos. O que
    /// sobra é a forma da rota, que é o que serve para diagnosticar.
    static func redact(_ path: String) -> String {
        let withoutQuery = path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? path
        let components = withoutQuery.split(separator: "/", omittingEmptySubsequences: false)
        let masked = components.map { component -> String in
            let text = String(component)
            guard !text.isEmpty else { return text }
            let digits = text.filter(\.isNumber).count
            // Quatro dígitos já bastam para ser ano, número de contrato ou id.
            if digits >= 4 { return "{id}" }
            // UUID e número CNJ formatado: hífen com dígito ao lado.
            if text.contains("-") && digits > 0 { return "{id}" }
            if text.count > 24 { return "{id}" }
            return text
        }
        return masked.joined(separator: "/")
    }
}
