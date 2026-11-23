/// Os três ganchos que o README pedia, ligados à infraestrutura real.
struct RemoteSessionLifecycle: SessionLifecycle {
    let client: APIClient
    /// O token da sessão, ou a chave fixa da fonte somente leitura.
    let tokens: AuthorizationProviding
    let gate: SecurityGate

    /// Amarra o cache à conta. Idempotente — o `AppState` chama a cada
    /// atualização, o que cobre também a sessão restaurada no lançamento.
    func didSignIn(companyID: String) async {
        await client.setScope(companyID)
    }

    /// Obrigatório: a chave com escopo evita colisão entre contas, não apaga.
    func didSignOut() async {
        await tokens.invalidate()
        await client.purgeCache()
        await client.setScope(nil)
    }

    /// Quem acopla um depurador faz isso com o app já aberto.
    func willEnterForeground() async {
        await gate.invalidate()
    }
}
