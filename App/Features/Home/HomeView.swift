import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState

    @State private var cases: [LegalCase] = []
    @State private var isLoading = true

    private var openCases: [LegalCase] {
        cases.filter(\.status.isOpen).sorted { $0.lastUpdate > $1.lastUpdate }
    }

    private var closedCases: [LegalCase] {
        cases.filter { !$0.status.isOpen }.sorted { $0.lastUpdate > $1.lastUpdate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("home.loading")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    content
                }
            }
            .background(Theme.background)
            .navigationTitle("home.title")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("LogoHorizontal")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 26)
                }
            }
        }
        .task { await load() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                greeting

                HStack(spacing: 12) {
                    SummaryChip(count: openCases.count, labelKey: "home.summary.open", color: Theme.primary)
                    SummaryChip(count: closedCases.count, labelKey: "home.summary.closed", color: Theme.muted)
                }

                if !openCases.isEmpty {
                    Text("home.section.open")
                        .font(Theme.font(18, weight: .bold))
                        .foregroundStyle(Theme.primary)
                    ForEach(openCases) { item in
                        NavigationLink(value: item) { CaseRowView(legalCase: item) }
                            .buttonStyle(.plain)
                    }
                }

                if !closedCases.isEmpty {
                    Text("home.section.closed")
                        .font(Theme.font(18, weight: .bold))
                        .foregroundStyle(Theme.primary)
                    ForEach(closedCases) { item in
                        NavigationLink(value: item) { CaseRowView(legalCase: item) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .navigationDestination(for: LegalCase.self) { CaseDetailView(legalCase: $0) }
        .refreshable { await load() }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("home.greeting \(appState.client?.name.components(separatedBy: " ").first ?? "")")
                .font(Theme.font(22, weight: .bold))
                .foregroundStyle(Theme.primary)
            Text("home.subtitle")
                .font(Theme.font(14))
                .foregroundStyle(Theme.muted)
        }
    }

    private func load() async {
        guard let client = appState.client else { return }
        if cases.isEmpty { isLoading = true }
        cases = (try? await appState.repository.cases(for: client.id)) ?? []
        isLoading = false
    }
}

private struct SummaryChip: View {
    let count: Int
    let labelKey: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(Theme.font(26, weight: .bold))
                .foregroundStyle(color)
            Text(labelKey)
                .font(Theme.font(12, weight: .medium))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

#Preview {
    HomeView().environment(AppState.loggedInPreview())
}
