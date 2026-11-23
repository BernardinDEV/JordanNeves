import SwiftUI

/// Contratos que pedem decisão, no painel. Some quando não há nenhum.
struct HomeContractsSection: View {
    @Environment(AppState.self) private var appState
    let documents: [ClientDocument]
    let seeAll: () -> Void

    var body: some View {
        if !documents.isEmpty {
            SectionHeader(title: "home.section.contracts") {
                Button("common.seeAll", action: seeAll)
                    .buttonStyle(LinkButtonStyle(compact: true))
            }
            RowCard {
                ForEach(documents) { document in
                    VStack(spacing: 0) {
                        if document.id != documents.first?.id { RowDivider() }
                        NavigationLink(value: AppRoute.document(document.id)) {
                            DocumentRow(
                                document: document,
                                alert: appState.contractAlert(for: document),
                                style: .deadline
                            )
                        }
                        .buttonStyle(RowPressStyle())
                    }
                }
            }
            .sideMargin()
        }
    }
}
