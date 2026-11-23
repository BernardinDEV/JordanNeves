import SwiftUI

/// The repository, treated as a calendar of deadlines that happens to hold files.
/// "Precisa de você" sits above the list — nobody opens an app to browse
/// forty-one PDFs.
struct DocumentsView: View {
    @Environment(AppState.self) private var appState
    @State private var kind: DocumentKind = .contract
    @State private var query = ""
    @State private var showUpload = false

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    private var filtered: [ClientDocument] {
        let byKind = appState.documents.filter { $0.kind == kind }
        let trimmed = trimmedQuery
        guard !trimmed.isEmpty else { return byKind }
        return byKind.filter {
            $0.title.localizedStandardContains(trimmed)
                || ($0.counterparty ?? "").localizedStandardContains(trimmed)
        }
    }

    var body: some View {
        let filtered = self.filtered
        let isSearching = !trimmedQuery.isEmpty

        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Text("docs.count \(appState.contracts.count) \(appState.documents.count)")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sideMargin()
                        .padding(.bottom, 14)

                    SyncFailureBanner()

                    Picker("docs.kind", selection: $kind) {
                        ForEach(DocumentKind.allCases, id: \.self) { option in
                            Text(LocalizedStringKey(option.labelKey(personal: appState.isPersonalAccount))).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .sideMargin()

                    if appState.isAwaitingFirstLoad {
                        FirstLoadPlaceholder()
                    } else {
                        // Durante a busca a tela é só o resultado.
                        if !isSearching {
                            DocumentsAttentionSection(documents: appState.documentsNeedingAttention)
                        }

                        SectionHeader(LocalizedStringKey(kind == .contract ? "docs.section.allContracts" : "docs.section.allFiles"))

                        if filtered.isEmpty {
                            if isSearching {
                                ContentUnavailableView.search(text: trimmedQuery)
                            } else {
                                EmptyStateView(
                                    systemImage: "folder",
                                    title: "docs.empty.title",
                                    message: "docs.empty.message"
                                )
                                .card()
                                .sideMargin()
                            }
                        } else {
                            RowCard {
                                ForEach(filtered) { document in
                                    VStack(spacing: 0) {
                                        if document.id != filtered.first?.id { RowDivider() }
                                        NavigationLink(value: AppRoute.document(document.id)) {
                                            DocumentRow(
                                                document: document,
                                                alert: appState.contractAlert(for: document)
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
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle(Text("docs.title"))
            // A busca precisa da barra de navegação para existir. Com a barra
            // escondida o campo nunca aparecia: a busca estava no código e
            // fora da tela. `.always` o mantém à vista, sem depender de o
            // cliente descobrir que precisa puxar a lista para baixo.
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("docs.searchPrompt")
            )
            .refreshable { await appState.refresh() }
            .toolbar {
                if appState.capabilities.canUpload {
                    ToolbarItem(placement: .primaryAction) {
                        Button("docs.upload.a11y", systemImage: "plus", action: presentUpload)
                    }
                }
            }
            .appRouteDestinations()
            .sheet(isPresented: $showUpload) { UploadSheet() }
        }
    }

    private func presentUpload() {
        showUpload = true
    }
}

#Preview {
    DocumentsView().environment(AppState.signedInPreview())
}
