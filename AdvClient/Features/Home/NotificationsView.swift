import SwiftUI

/// Two inboxes, never one. "Exige você" and "Para saber" is the same cut the
/// dashboard makes, repeated here — it is the rule that holds the whole app
/// together, and only the first box would ever earn a push notification.
struct NotificationsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if appState.openPendencies.isEmpty && appState.informationalMovements.isEmpty {
                    EmptyStateView(
                        systemImage: "bell.slash",
                        title: "notifications.empty.title",
                        message: "notifications.empty.message"
                    )
                    .card()
                    .sideMargin()
                    .padding(.top, 24)
                }

                if !appState.openPendencies.isEmpty {
                    SectionHeader("home.section.requiresYou")
                    RowCard {
                        ForEach(Array(appState.openPendencies.enumerated()), id: \.element.id) { index, pendency in
                            NavigationLink {
                                pendencyDestination(pendency)
                            } label: {
                                AppListRow(
                                    title: pendency.title,
                                    subtitle: Format.deadline(pendency.dueDate),
                                    systemImage: pendency.kind.systemImage,
                                    iconTone: .critical,
                                    isMonoSubtitle: true
                                )
                            }
                            .buttonStyle(.plain)
                            if index < appState.openPendencies.count - 1 { RowDivider() }
                        }
                    }
                    .sideMargin()
                }

                if !appState.informationalMovements.isEmpty {
                    SectionHeader("notifications.section.forInfo")
                    RowCard {
                        ForEach(Array(appState.informationalMovements.enumerated()), id: \.element.movement.id) { index, item in
                            NavigationLink {
                                MovementDetailView(caseID: item.legalCase.id, movementID: item.movement.id)
                            } label: {
                                AppListRow(
                                    title: item.movement.displayHeadline,
                                    subtitle: "\(Format.string(.init(item.legalCase.area.labelKey))) · \(Format.date(item.movement.date)) · \(Format.string("notifications.nothingToDo"))",
                                    systemImage: "text.document",
                                    iconTone: appState.readMovementIDs.contains(item.movement.id) ? .neutral : .brass
                                )
                            }
                            .buttonStyle(.plain)
                            if index < appState.informationalMovements.count - 1 { RowDivider() }
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

    @ViewBuilder
    private func pendencyDestination(_ pendency: Pendency) -> some View {
        switch pendency.kind {
        case .hearing:
            if let caseID = pendency.caseID {
                CaseDetailView(caseID: caseID)
            }
        case .contractDecision, .documentRequest:
            if let documentID = pendency.documentID {
                ContractDetailView(documentID: documentID)
            } else if let caseID = pendency.caseID {
                CaseDetailView(caseID: caseID)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView().environment(AppState.signedInPreview())
    }
}
