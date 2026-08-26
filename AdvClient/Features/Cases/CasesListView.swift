import SwiftUI

struct CasesListView: View {
    @Environment(AppState.self) private var appState
    @State private var filter: Filter = .active

    enum Filter: CaseIterable, Identifiable {
        case active, closed, all
        var id: Self { self }
        var labelKey: LocalizedStringKey {
            switch self {
            case .active: "cases.filter.active"
            case .closed: "cases.filter.closed"
            case .all: "cases.filter.all"
            }
        }
    }

    private var visibleCases: [LegalCase] {
        let list = switch filter {
        case .active: appState.openCases
        case .closed: appState.closedCases
        case .all: appState.cases
        }
        // Most urgent first — the same order the dashboard uses.
        return list.sorted { lhs, rhs in
            let l = appState.state(of: lhs), r = appState.state(of: rhs)
            if l != r { return sortRank(l) < sortRank(r) }
            return lhs.lastVisibleUpdate > rhs.lastVisibleUpdate
        }
    }

    private func sortRank(_ state: CaseState) -> Int {
        switch state {
        case .requiresYou: 0
        case .deadlineNear: 1
        case .onTrack: 2
        case .withCourt: 3
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("cases.title")
                            .font(Theme.font(34, weight: .bold))
                            .foregroundStyle(Theme.primary)
                        Text("cases.count \(appState.openCases.count) \(appState.closedCases.count)")
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .sideMargin()
                    .padding(.top, 14)
                    .padding(.bottom, 16)

                    Picker("cases.filter", selection: $filter) {
                        ForEach(Filter.allCases) { option in
                            Text(option.labelKey).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .sideMargin()

                    if visibleCases.isEmpty {
                        EmptyStateView(
                            systemImage: "tray",
                            title: "cases.empty.title",
                            message: "cases.empty.message"
                        )
                        .card()
                        .sideMargin()
                        .padding(.top, 16)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(visibleCases) { legalCase in
                                NavigationLink(value: legalCase.id) {
                                    CaseCard(
                                        legalCase: legalCase,
                                        state: appState.state(of: legalCase),
                                        deadline: appState.nextDeadline(for: legalCase)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .sideMargin()
                        .padding(.top, 16)
                    }

                    Text("home.lastSync \(Format.dateTime(appState.snapshot.lastSyncedAt))")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 22)
                }
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .refreshable { await appState.refresh() }
            .navigationDestination(for: UUID.self) { CaseDetailView(caseID: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    CasesListView().environment(AppState.signedInPreview())
}
