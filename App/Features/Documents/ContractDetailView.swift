import SwiftUI

/// One contract. "Pontos de atenção" is the real value here — a lawyer already
/// read the PDF and marked what matters. The document itself is a consequence,
/// not the content.
struct ContractDetailView: View {
    @Environment(AppState.self) private var appState
    let documentID: UUID

    private var document: ClientDocument? { appState.document(id: documentID) }

    var body: some View {
        Group {
            if let document {
                content(document)
            } else {
                EmptyStateView(systemImage: "questionmark.folder", title: "docs.notFound")
            }
        }
        .background(Theme.background)
        .navigationTitle(Text(document.map { String(localized: .init($0.kind.labelKey)) } ?? ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ document: ClientDocument) -> some View {
        let alert = appState.contractAlert(for: document)
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                pagePreview(document)

                Text(document.title)
                    .font(Theme.font(25, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    if let alert, let deadline = document.effectiveDeadline {
                        StatePill(
                            Format.countdown(to: deadline),
                            tone: alert == .urgent ? .critical : (alert == .decide ? .attention : .neutral)
                        )
                    }
                    StatePill("v\(document.version)", tone: .neutral)
                    if document.autoRenews {
                        StatePill(String(localized: "docs.autoRenews"), tone: .brass)
                    }
                }
                .padding(.top, 10)

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
                .padding(.top, 18)

                if !document.attentionPoints.isEmpty {
                    Text("docs.section.attention")
                        .font(Theme.font(13, weight: .semibold))
                        .textCase(.uppercase)
                        .kerning(0.4)
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 26)
                        .padding(.bottom, 10)

                    VStack(spacing: 9) {
                        ForEach(document.attentionPoints) { point in
                            clauseCard(point)
                        }
                    }
                }

                WhatsAppButton(
                    context: .contract(title: document.title),
                    titleKey: "docs.action.askReview"
                )
                .padding(.top, 22)
            }
            .sideMargin()
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
    }

    private func clauseCard(_ point: AttentionPoint) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(point.clause)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.muted)
            Text(point.title)
                .font(Theme.font(14.5, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text(point.detail)
                .font(Theme.font(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .overlay(alignment: .leading) {
            Rectangle().fill(point.isWarning ? Theme.attention : Theme.onTrack).frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
    }

    /// Stand-in for the PDF page. The real build renders the first page with
    /// PDFKit from a signed, short-lived URL.
    private func pagePreview(_ document: ClientDocument) -> some View {
        VStack(spacing: 9) {
            VStack(alignment: .leading, spacing: 7) {
                Text(document.title.uppercased())
                    .font(Theme.font(8, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .lineLimit(2)
                    .padding(.bottom, 6)
                ForEach(0..<7, id: \.self) { index in
                    Capsule()
                        .fill(Theme.line)
                        .frame(width: index % 3 == 2 ? 62 : nil, height: 3)
                        .frame(maxWidth: index % 3 == 2 ? 62 : .infinity, alignment: .leading)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(width: 172, height: 214, alignment: .topLeading)
            .background(.white, in: RoundedRectangle(cornerRadius: 5))
            .shadow(color: Theme.primary.opacity(0.16), radius: 6, y: 3)

            Text("docs.pageOf \(1) \(14)")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.fill, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

#Preview {
    NavigationStack {
        ContractDetailView(documentID: MockData.suzanoContractID)
            .environment(AppState.signedInPreview())
    }
}
