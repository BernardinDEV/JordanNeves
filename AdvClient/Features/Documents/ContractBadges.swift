import SwiftUI

/// Os selos sob o título do contrato: contagem do prazo, versão, renovação.
/// Em `FlowRow`, para descerem de linha quando a letra cresce.
struct ContractBadges: View {
    let document: ClientDocument
    let alert: ContractAlert?

    var body: some View {
        FlowRow(spacing: 7, rowSpacing: 7) {
            if let alert, let deadline = document.effectiveDeadline {
                StatePill(Format.countdown(to: deadline), tone: tone(for: alert))
            }
            StatePill("v\(document.version)", tone: .neutral)
            if document.autoRenews {
                StatePill(Format.string("docs.autoRenews"), tone: .brass)
            }
        }
    }

    private func tone(for alert: ContractAlert) -> StatePill.Tone {
        switch alert {
        case .urgent: .critical
        case .decide: .attention
        case .watch: .neutral
        }
    }
}
