import Foundation
// `CFNetworkCopySystemProxySettings` mora no CFNetwork; o Foundation costuma
// reexportá-lo em Darwin, mas o import explícito tira a dúvida.
import CFNetwork

// MARK: - Sessão endurecida

/// Como a sessão de rede deste app é montada, e por quê.
///
/// Cada linha aqui fecha um caminho por onde dado de cliente sai do aparelho
/// sem ninguém ter pedido. A ordem abaixo é a do risco, não a do código.
enum NetworkSecurity {

    /// A configuração que toda chamada do app usa.
    ///
    /// - **`ephemeral`** — nem cache, nem cookie, nem credencial tocam o disco
    ///   pelas mãos do sistema. O que fica guardado é só o que a
    ///   `ResponseCache` grava, com proteção de arquivo e escopo de conta.
    /// - **`urlCache = nil` e `reloadIgnoringLocalAndRemoteCacheData`** —
    ///   redundante com `ephemeral`, e de propósito: se algum dia alguém trocar
    ///   `ephemeral` por `default` para depurar, o cache do sistema continua
    ///   desligado.
    /// - **Sem cookie** — este serviço autentica por cabeçalho. Cookie ligado é
    ///   superfície de CSRF e de rastreamento entre requisições que ninguém aqui
    ///   precisa.
    /// - **TLS 1.2 no mínimo** — 1.0 e 1.1 estão quebrados e são reprovação
    ///   direta em qualquer auditoria. O máximo é 1.3, que é o que o sistema
    ///   negocia sozinho quando o servidor acompanha.
    /// - **`waitsForConnectivity = false`** — sem rede, a chamada falha rápido e
    ///   a camada responde com o cache guardado. Esperar em silêncio é o que faz
    ///   o cliente achar que o app travou.
    static func makeConfiguration(timeout: TimeInterval = 20) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral

        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.urlCredentialStorage = nil

        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13

        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 3
        configuration.httpMaximumConnectionsPerHost = 4

        configuration.allowsCellularAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        configuration.allowsExpensiveNetworkAccess = true

        configuration.httpAdditionalHeaders = ["User-Agent": userAgent]

        return configuration
    }

    static func makeSession(timeout: TimeInterval = 20) -> URLSession {
        URLSession(
            configuration: makeConfiguration(timeout: timeout),
            delegate: RedirectPolicy(),
            delegateQueue: nil
        )
    }

    /// `br.adv.exemplo.app/1.0 (iOS 17.4)`. Versão e plataforma, nada além —
    /// User-Agent é enviado a cada requisição e vira impressão digital quando
    /// carrega detalhe demais.
    static var userAgent: String {
        let bundle = Bundle.main.bundleIdentifier ?? "AdvClient"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let system = ProcessInfo.processInfo.operatingSystemVersion
        return "\(bundle)/\(version) (iOS \(system.majorVersion).\(system.minorVersion))"
    }

    // MARK: Proxy

    /// Existe um proxy HTTP configurado no aparelho.
    ///
    /// Não bloqueia nada, e isso é uma decisão, não um esquecimento: rede
    /// corporativa com proxy é o cenário normal do cliente deste app — um
    /// escritório de contabilidade atrás do firewall da empresa — e recusar a
    /// conexão ali derrubaria justamente quem paga.
    ///
    /// Serve como sinal no log. **A defesa de verdade contra interceptação é o
    /// pinning de certificado**, que ainda não está ligado: enquanto ele não
    /// estiver, um proxy com CA instalada no aparelho lê o tráfego, e nenhuma
    /// heurística daqui muda isso.
    static var isBehindHTTPProxy: Bool {
        guard let raw = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else { return false }
        let settings = raw as NSDictionary
        for key in ["HTTPEnable", "HTTPSEnable"] {
            if let number = settings[key] as? NSNumber, number.intValue != 0 { return true }
        }
        return false
    }
}

// MARK: - Política de redirecionamento

/// Recusa redirecionamento que não seja HTTPS para o mesmo host.
///
/// É o vazamento clássico de token: o servidor responde `302` para outro
/// domínio, o `URLSession` segue por padrão e leva o cabeçalho `Authorization`
/// junto — a sessão do cliente entregue a quem controlar o destino. Um
/// downgrade para `http://` é a mesma história com o corpo em claro.
///
/// Ao recusar, o `URLSession` devolve a própria resposta 3xx ao chamador, que a
/// camada traduz em `APIError.insecureTransport`. O erro é deliberado: um
/// redirecionamento inesperado é um evento de segurança, não um detalhe de
/// transporte que se resolve sozinho.
final class RedirectPolicy: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let destination = request.url,
              destination.scheme?.lowercased() == "https",
              let origin = task.originalRequest?.url?.host?.lowercased(),
              let target = destination.host?.lowercased(),
              origin == target
        else {
            NetworkLog.blocked(
                path: task.originalRequest?.url?.path ?? "?",
                reason: "redirecionamento para fora do host ou sem TLS"
            )
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }
}

// MARK: - Portaria do ambiente

/// Decide se este aparelho está em condições de receber dado do cliente.
///
/// `TamperDetection` faz sondagens síncronas de sistema de arquivos — caro
/// demais para rodar a cada requisição e proibido na thread principal. Este ator
/// roda a checagem fora da main, guarda o veredito e o revalida de tempos em
/// tempos, porque um aparelho pode ser comprometido **durante** a sessão: quem
/// acopla um depurador ou injeta uma biblioteca faz isso com o app já aberto.
///
/// Quando o veredito é negativo, a camada de rede não tenta se proteger — ela
/// para. Nenhuma requisição sai, o cache é apagado, e o erro que chega à tela é
/// `APIError.insecureEnvironment`. Num aparelho com jailbreak ou com Frida
/// carregado, qualquer coisa que o app faça é observável; a única jogada honesta
/// é não colocar processo, contrato e honorário de uma empresa na memória dele.
actor SecurityGate {

    static let shared = SecurityGate()

    private let probe: @Sendable () -> Bool
    private let revalidateAfter: TimeInterval
    private var verdict: (compromised: Bool, checkedAt: Date)?

    /// - Parameters:
    ///   - revalidateAfter: cinco minutos. Curto o bastante para pegar um
    ///     depurador acoplado no meio da sessão, longo o bastante para as
    ///     sondagens não pesarem em cada tela aberta.
    ///   - probe: costura de teste. Em produção é `TamperDetection`, que já
    ///     devolve `false` em DEBUG e no simulador.
    init(
        revalidateAfter: TimeInterval = 300,
        probe: @escaping @Sendable () -> Bool = { TamperDetection.isCompromised() }
    ) {
        self.revalidateAfter = revalidateAfter
        self.probe = probe
    }

    func isCompromised(now: Date = .now) async -> Bool {
        if let verdict, now.timeIntervalSince(verdict.checkedAt) < revalidateAfter {
            return verdict.compromised
        }
        let probe = self.probe
        let result = await Task.detached(priority: .utility) { probe() }.value
        verdict = (result, now)
        if result {
            NetworkLog.warning("ambiente comprometido: requisições bloqueadas")
        }
        return result
    }

    /// Força uma nova checagem na próxima requisição. O lugar de chamar é a
    /// volta do app ao primeiro plano.
    func invalidate() {
        verdict = nil
    }
}
