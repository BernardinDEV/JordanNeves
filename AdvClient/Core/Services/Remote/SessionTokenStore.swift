import Foundation

/// O token da sessão do cliente na API do produto.
///
/// Guardado no Keychain, só neste aparelho — nunca em `UserDefaults`, que entra
/// em backup em claro. Vencido, deixa de ser enviado: a chamada sai sem
/// autorização, volta 401 e o `AppState` encerra a sessão, que é o
/// comportamento seguro enquanto não há renovação.
actor SessionTokenStore: AuthorizationProviding {

    struct Token: Codable, Equatable, Sendable {
        let value: String
        let expiresAt: Date
    }

    static let keychainKey = "session.token"

    private var token: Token?
    private var didLoad = false

    init() {}

    func store(_ token: Token) {
        self.token = token
        didLoad = true
        if let data = try? JSONEncoder().encode(token), let json = String(data: data, encoding: .utf8) {
            KeychainHelper.save(json, forKey: Self.keychainKey)
        }
    }

    func authorizationHeader() async -> String? {
        loadIfNeeded()
        guard let token, token.expiresAt > .now else { return nil }
        return "Bearer \(token.value)"
    }

    func invalidate() async {
        token = nil
        didLoad = true
        Self.clearPersisted()
    }

    /// Para a limpeza de instalação nova, que roda antes de existir uma sessão.
    nonisolated static func clearPersisted() {
        KeychainHelper.delete(forKey: keychainKey)
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        guard let json = KeychainHelper.load(forKey: Self.keychainKey),
              let data = json.data(using: .utf8) else { return }
        token = try? JSONDecoder().decode(Token.self, from: data)
    }
}
