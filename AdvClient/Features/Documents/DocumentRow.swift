import SwiftUI

/// Um documento como linha de lista.
struct DocumentRow: View {
    enum Style {
        /// Lista geral: validade ou data de envio, selo de situação.
        case validity
        /// "Precisa de você": o prazo que força a decisão, selo da ação.
        case deadline
    }

    let document: ClientDocument
    let alert: ContractAlert?
    var style: Style = .validity

    var body: some View {
        let badge = self.badge
        AppListRow(
            title: document.title,
            subtitle: subtitle,
            systemImage: document.uploadedByClient ? "arrow.up.doc" : "doc.text",
            iconTone: style == .deadline ? (badge?.tone ?? .attention) : .neutral,
            isMonoSubtitle: true,
            trailingPill: badge.map { (text: $0.text, tone: $0.tone) }
        )
    }

    private var badge: DocumentBadge? {
        switch style {
        case .validity: DocumentBadge(document: document, alert: alert)
        case .deadline: .action(for: document, alert: alert)
        }
    }

    private var subtitle: String? {
        switch style {
        case .deadline:
            return document.effectiveDeadline.map(Self.deadlineText(for: document))
        case .validity:
            if let expiry = document.expiresAt {
                return Format.string("docs.validUntil \(Format.date(expiry))")
            }
            return Format.string("docs.uploadedOn \(Format.date(document.uploadedAt))")
        }
    }

    /// `Aviso até 14/09/2026 · em 54 dias` quando o contrato renova sozinho —
    /// a data é a do aviso prévio, e o texto precisa dizer isso.
    static func deadlineText(for document: ClientDocument) -> (Date) -> String {
        { deadline in
            document.autoRenews
                ? Format.string("docs.noticeBy \(Format.deadline(deadline))")
                : Format.deadline(deadline)
        }
    }
}
