import SwiftUI

/// "Precisa de você", no topo de Documentos. Some quando não há nada.
struct DocumentsAttentionSection: View {
    @Environment(AppState.self) private var appState
    let documents: [ClientDocument]

    var body: some View {
        if !documents.isEmpty {
            SectionHeader("docs.section.needsYou")
            VStack(spacing: 9) {
                ForEach(documents) { document in
                    NavigationLink(value: AppRoute.document(document.id)) {
                        DocumentAttentionCard(
                            document: document,
                            alert: appState.contractAlert(for: document)
                        )
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
            .sideMargin()
        }
    }
}
