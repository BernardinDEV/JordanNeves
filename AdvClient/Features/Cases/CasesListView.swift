import SwiftUI

struct CasesListView: View {
    @Environment(AppState.self) private var appState
    @State private var filter: CaseFilter = .active

    /// Most urgent first — the same order the dashboard uses. Já vem ordenada
    /// do índice; aqui só se escolhe qual das três listas mostrar.
    private var visibleCases: [LegalCase] {
        switch filter {
        case .active: appState.index.openCasesByUrgency
        case .closed: appState.index.closedCasesByUrgency
        case .all: appState.index.allCasesByUrgency
        }
    }

    var body: some View {
        let visibleCases = self.visibleCases

        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Text("cases.count \(appState.openCases.count) \(appState.closedCases.count)")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sideMargin()
                        .padding(.bottom, 14)

                    SyncFailureBanner()

                    Picker("cases.filter", selection: $filter) {
                        ForEach(CaseFilter.allCases) { option in
                            Text(option.labelKey).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .sideMargin()
                    .padding(.bottom, 16)

                    if appState.isAwaitingFirstLoad {
                        FirstLoadPlaceholder()
                    } else if visibleCases.isEmpty {
                        EmptyStateView(
                            systemImage: "tray",
                            title: "cases.empty.title",
                            message: "cases.empty.message"
                        )
                        .card()
                        .sideMargin()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(visibleCases) { legalCase in
                                CaseCardLink(legalCase: legalCase)
                            }
                        }
                        .sideMargin()
                    }

                    SyncFooter()
                }
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .refreshable { await appState.refresh() }
            .navigationTitle(Text("cases.title"))
            .appRouteDestinations()
        }
    }
}

#Preview {
    CasesListView().environment(AppState.signedInPreview())
}
