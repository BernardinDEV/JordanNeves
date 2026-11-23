/// Os momentos da sessão que a infraestrutura precisa saber.
///
/// O README listava três ganchos a ligar "quando o backend existir": escopo do
/// cache na entrada, limpeza do cache na saída e nova checagem do ambiente na
/// volta ao primeiro plano. Este protocolo é onde eles moram, para o `AppState`
/// chamar sem saber se há rede, cache ou token por trás.
protocol SessionLifecycle: Sendable {
    func didSignIn(companyID: String) async
    func didSignOut() async
    func willEnterForeground() async
}

/// Sem rede, sem cache, sem token: nada a fazer.
struct NoSessionLifecycle: SessionLifecycle {
    func didSignIn(companyID: String) async {}
    func didSignOut() async {}
    func willEnterForeground() async {}
}
