import SwiftUI

/// Vigência, valor, contraparte e — em linha própria — o prazo de aviso prévio.
struct ContractFactsList: View {
    let document: ClientDocument
    let alert: ContractAlert?

    var body: some View {
        VStack(spacing: 0) {
            if let from = document.effectiveFrom, let to = document.expiresAt {
                KeyValueRow(
                    label: "docs.field.term",
                    value: "\(Format.date(from)) → \(Format.date(to))",
                    isMono: true
                )
            }
            if let value = document.monthlyValue {
                KeyValueRow(label: "docs.field.monthly", value: Format.money(value), isMono: true)
            }
            if let counterparty = document.counterparty {
                KeyValueRow(label: "docs.field.counterparty", value: counterparty)
            }
            // The date that actually forces a decision gets its own row,
            // ahead of the expiry date it precedes.
            if let notice = document.noticeDeadline {
                KeyValueRow(
                    label: "docs.field.noticeDeadline",
                    value: Format.deadline(notice),
                    isMono: true,
                    tint: alert == .urgent ? Theme.critical : Theme.attention
                )
            }
        }
    }
}
