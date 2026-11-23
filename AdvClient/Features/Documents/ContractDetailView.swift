import SwiftUI

/// One contract. "Pontos de atenção" is the real value here — a lawyer already
/// read the PDF and marked what matters. The document itself is a consequence,
/// not the content.
struct ContractDetailView: View {
    @Environment(AppState.self) private var appState
    let documentID: UUID

    private var document: ClientDocument? { appState.document(id: documentID) }

    var body: some View {
        let document = self.document

        Group {
            if let document {
                let alert = appState.contractAlert(for: document)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ContractPagePreview(title: document.title)

                        Text(document.title)
                            .font(Theme.font(25, weight: .bold))
                            .foregroundStyle(Theme.primary)
                            .padding(.top, 16)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)

                        ContractBadges(document: document, alert: alert)
                            .padding(.top, 10)

                        ContractFactsList(document: document, alert: alert)
                            .padding(.top, 18)

                        if !document.attentionPoints.isEmpty {
                            Text("docs.section.attention")
                                .font(Theme.font(13, weight: .semibold))
                                .textCase(.uppercase)
                                .kerning(0.4)
                                .foregroundStyle(Theme.muted)
                                .padding(.top, 26)
                                .padding(.bottom, 10)
                                .accessibilityAddTraits(.isHeader)

                            VStack(spacing: 9) {
                                ForEach(document.attentionPoints) { point in
                                    ClauseCard(point: point)
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
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            } else {
                EmptyStateView(systemImage: "questionmark.folder", title: "docs.notFound")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.background)
        .navigationTitle(document.map { Format.string(.init($0.kind.labelKey(personal: appState.isPersonalAccount))) } ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ContractDetailView(documentID: DemoDataset.current.renewalContractID)
            .environment(AppState.signedInPreview())
    }
}
