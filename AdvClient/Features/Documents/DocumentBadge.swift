/// O selo de um documento nas listas: o que fazer e com que urgência.
///
/// A regra vivia em três telas e elas discordavam — a lista de contratos
/// escolhia "Decidir" ou "Renovar" pela urgência, o cartão de atenção pela
/// renovação automática, e o mesmo contrato aparecia com dois rótulos.
/// Agora: a **palavra** vem do contrato (renova sozinho → decidir; não renova →
/// renovar) e a **cor** vem da urgência.
struct DocumentBadge {
    let text: String
    let tone: StatePill.Tone

    /// Selo para a lista geral. `nil` para o que não é contrato — arquivo de
    /// processo não tem prazo a decidir.
    init?(document: ClientDocument, alert: ContractAlert?) {
        guard document.kind == .contract else { return nil }
        switch alert {
        case .urgent, .decide:
            self = .action(for: document, alert: alert)
        case .watch, nil:
            text = Format.string("state.onTrack")
            tone = .onTrack
        }
    }

    private init(text: String, tone: StatePill.Tone) {
        self.text = text
        self.tone = tone
    }

    /// Selo de um documento que já está em "Precisa de você".
    static func action(for document: ClientDocument, alert: ContractAlert?) -> DocumentBadge {
        DocumentBadge(
            text: Format.string(document.autoRenews ? "docs.action.decide" : "docs.action.renew"),
            tone: alert == .urgent ? .critical : .attention
        )
    }
}
