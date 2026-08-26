import SwiftUI

/// The dashboard. Ordered by obligation, not by volume: "Exige você" comes before
/// "Seus casos" even when it holds a single item — and disappears entirely when
/// there is nothing waiting on the client.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Binding var selectedTab: MainTab
    @State private var showNotifications = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    header
                    positionCard

                    if !appState.casesRequiringClient.isEmpty {
                        SectionHeader("home.section.requiresYou")
                        VStack(spacing: 12) {
                            ForEach(appState.casesRequiringClient) { legalCase in
                                NavigationLink(value: legalCase.id) {
                                    CaseCard(
                                        legalCase: legalCase,
                                        state: .requiresYou,
                                        deadline: appState.nextDeadline(for: legalCase)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .sideMargin()
                    }

                    SectionHeader(title: "home.section.cases") {
                        Button("common.seeAll") { selectedTab = .cases }
                            .font(Theme.font(13.5))
                            .foregroundStyle(Theme.primary)
                    }

                    if appState.openCases.isEmpty {
                        EmptyStateView(
                            systemImage: "text.document",
                            title: "home.empty.cases.title",
                            message: "home.empty.cases.message"
                        )
                        .card()
                        .sideMargin()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(otherCases) { legalCase in
                                NavigationLink(value: legalCase.id) {
                                    CaseCard(legalCase: legalCase, state: appState.state(of: legalCase))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .sideMargin()
                    }

                    if !appState.documentsNeedingAttention.isEmpty {
                        SectionHeader(title: "home.section.contracts") {
                            Button("common.seeAll") { selectedTab = .documents }
                                .font(Theme.font(13.5))
                                .foregroundStyle(Theme.primary)
                        }
                        RowCard {
                            ForEach(Array(appState.documentsNeedingAttention.enumerated()), id: \.element.id) { index, document in
                                NavigationLink(value: document.id) {
                                    documentRow(document)
                                }
                                .buttonStyle(.plain)
                                if index < appState.documentsNeedingAttention.count - 1 { RowDivider() }
                            }
                        }
                        .sideMargin()
                    }

                    syncFooter
                }
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .refreshable { await appState.refresh() }
            .navigationDestination(for: UUID.self) { id in
                destination(for: id)
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    /// Cases already surfaced under "Exige você" are not repeated below.
    private var otherCases: [LegalCase] {
        let urgent = Set(appState.casesRequiringClient.map(\.id))
        return appState.openCases.filter { !urgent.contains($0.id) }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Format.weekdayDate(.now))
                    .font(Theme.font(12.5))
                    .foregroundStyle(Theme.muted)
                Text(appState.company?.tradeName ?? "")
                    .font(Theme.font(25, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Button {
                showNotifications = true
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .frame(width: 42, height: 42)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Theme.primary.opacity(0.06), radius: 6, y: 2)
                    .overlay(alignment: .topTrailing) {
                        if appState.unreadCount > 0 {
                            Text("\(appState.unreadCount)")
                                .font(Theme.font(11, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(Theme.critical, in: Capsule())
                                .offset(x: 5, y: -5)
                        }
                    }
            }
            .accessibilityLabel(Text("home.notifications.a11y \(appState.unreadCount)"))
        }
        .sideMargin()
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    // MARK: Position card

    private var positionCard: some View {
        let position = appState.position
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                BrandMark()
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("home.position.title")
                        .font(Theme.font(15, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                    Text("home.position.summary \(appState.openCases.count) \(appState.contracts.count)")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.muted)
                }
            }

            if !position.isEmpty {
                // Proportional to the real counts, not decorative. Critical sits
                // on the left so the eye lands on the problem first.
                GeometryReader { geo in
                    let fractions = position.fractions
                    let gap: CGFloat = 3
                    let segments = [position.requiresYou, position.deadlineNear, position.onTrack].filter { $0 > 0 }.count
                    let available = geo.size.width - gap * CGFloat(max(0, segments - 1))
                    HStack(spacing: gap) {
                        if position.requiresYou > 0 {
                            Capsule().fill(Theme.critical).frame(width: available * fractions.requiresYou)
                        }
                        if position.deadlineNear > 0 {
                            Capsule().fill(Theme.attention).frame(width: available * fractions.deadlineNear)
                        }
                        if position.onTrack > 0 {
                            Capsule().fill(Theme.onTrack).frame(width: available * fractions.onTrack)
                        }
                    }
                }
                .frame(height: 7)
                .accessibilityElement()
                .accessibilityLabel(Text("home.position.a11y \(position.requiresYou) \(position.deadlineNear) \(position.onTrack)"))

                FlowRow(spacing: 14, rowSpacing: 6) {
                    if position.requiresYou > 0 {
                        legend(color: Theme.critical, text: Format.string("home.legend.requiresYou \(position.requiresYou)"))
                    }
                    if position.deadlineNear > 0 {
                        legend(color: Theme.attention, text: Format.string("home.legend.deadlineNear \(position.deadlineNear)"))
                    }
                    if position.onTrack > 0 {
                        legend(color: Theme.onTrack, text: Format.string("home.legend.onTrack \(position.onTrack)"))
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .card()
        .sideMargin()
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
                .font(Theme.font(12.5))
                .foregroundStyle(Theme.muted)
        }
    }

    // MARK: Rows

    private func documentRow(_ document: ClientDocument) -> some View {
        let alert = appState.contractAlert(for: document)
        return AppListRow(
            title: document.title,
            subtitle: document.effectiveDeadline.map {
                document.autoRenews
                    ? Format.string("docs.noticeBy \(Format.deadline($0))")
                    : Format.deadline($0)
            },
            systemImage: "doc.text",
            iconTone: alert == .urgent ? .critical : .attention,
            isMonoSubtitle: true,
            trailingPill: (
                text: Format.string(document.autoRenews ? "docs.action.decide" : "docs.action.renew"),
                tone: alert == .urgent ? .critical : .attention
            )
        )
    }

    private var syncFooter: some View {
        Text("home.lastSync \(Format.dateTime(appState.snapshot.lastSyncedAt))")
            .font(Theme.font(12))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
    }

    @ViewBuilder
    private func destination(for id: UUID) -> some View {
        if appState.legalCase(id: id) != nil {
            CaseDetailView(caseID: id)
        } else if appState.document(id: id) != nil {
            ContractDetailView(documentID: id)
        }
    }
}

/// Minimal wrapping stack — the legend must not clip when Dynamic Type grows.
struct FlowRow: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environment(AppState.signedInPreview())
}
