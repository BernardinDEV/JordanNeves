import SwiftUI

/// Two inboxes, never one. "Exige você" and "Para saber" is the same cut the
/// dashboard makes, repeated here — it is the rule that holds the whole app
/// together, and only the first box would ever earn a push notification.
struct NotificationsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let pendencies = appState.openPendencies
        let informational = appState.informationalMovements

        ScrollView {
            VStack(spacing: 0) {
                if pendencies.isEmpty && informational.isEmpty {
                    EmptyStateView(
                        systemImage: "bell.slash",
                        title: "notifications.empty.title",
                        message: "notifications.empty.message"
                    )
                    .card()
                    .sideMargin()
                    .padding(.top, 24)
                }

                if !pendencies.isEmpty {
                    SectionHeader("home.section.requiresYou")
                    RowCard {
                        ForEach(pendencies) { pendency in
                            VStack(spacing: 0) {
                                if pendency.id != pendencies.first?.id { RowDivider() }
                                PendencyRow(pendency: pendency)
                            }
                        }
                    }
                    .sideMargin()
                }

                if !informational.isEmpty {
                    SectionHeader("notifications.section.forInfo")
                    RowCard {
                        ForEach(informational) { item in
                            VStack(spacing: 0) {
                                if item.id != informational.first?.id { RowDivider() }
                                InformationalMovementRow(
                                    item: item,
                                    isRead: appState.readMovementIDs.contains(item.id)
                                )
                            }
                        }
                    }
                    .sideMargin()

                    Text("notifications.digestNote")
                        .font(Theme.font(12.5))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .sideMargin()
                        .padding(.top, 18)
                }
            }
            .padding(.bottom, 28)
        }
        .background(Theme.background)
        .navigationTitle(Text("notifications.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .appRouteDestinations()
            .environment(AppState.signedInPreview())
    }
}
