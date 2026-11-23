import SwiftUI

/// The dashboard. Ordered by obligation, not by volume: "Exige você" comes before
/// "Seus casos" even when it holds a single item — and disappears entirely when
/// there is nothing waiting on the client.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Binding var selectedTab: MainTab
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    Text(Format.weekdayDate(.now))
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sideMargin()
                        .padding(.bottom, 14)

                    SyncFailureBanner()

                    if appState.isAwaitingFirstLoad {
                        FirstLoadPlaceholder()
                    } else {
                        PositionCard(
                            position: appState.position,
                            openCaseCount: appState.openCases.count,
                            contractCount: appState.capabilities.documents ? appState.contracts.count : nil
                        )
                        HomeRequiresYouSection(cases: appState.casesRequiringClient)
                        HomeCasesSection(
                            cases: appState.index.otherOpenCases,
                            hasOpenCases: !appState.openCases.isEmpty,
                            isPersonal: appState.isPersonalAccount,
                            seeAll: showAllCases
                        )
                        // O painel também leva a Documentos: a capacidade cobre os
                        // dois caminhos, não só a aba.
                        if appState.capabilities.documents {
                            HomeContractsSection(
                                documents: appState.documentsNeedingAttention,
                                seeAll: showAllDocuments
                            )
                        }
                        SyncFooter()
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .refreshable { await appState.refresh() }
            .navigationTitle(appState.company?.tradeName ?? "")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NotificationsButton(unreadCount: appState.unreadCount, action: showNotifications)
                }
            }
            .appRouteDestinations()
        }
    }

    private func showNotifications() {
        path.append(.notifications)
    }

    private func showAllCases() {
        selectedTab = .cases
    }

    private func showAllDocuments() {
        selectedTab = .documents
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environment(AppState.signedInPreview())
}
