import SwiftUI

/// One case. "Seu próximo passo" is the only filled button on the screen; the
/// cold facts — value, court, risk — come *after* the action, not before it.
struct CaseDetailView: View {
    @Environment(AppState.self) private var appState
    let caseID: UUID

    @State private var showHearingSheet = false

    private var legalCase: LegalCase? { appState.legalCase(id: caseID) }

    var body: some View {
        Group {
            if let legalCase {
                content(for: legalCase)
            } else {
                EmptyStateView(systemImage: "questionmark.folder", title: "case.notFound")
            }
        }
        .background(Theme.background)
        .navigationTitle(Text(legalCase.map { String(localized: .init($0.area.labelKey)) } ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHearingSheet) {
            if let legalCase, let hearing = legalCase.hearing {
                HearingSheet(caseID: legalCase.id, caseNumber: legalCase.number, hearing: hearing)
            }
        }
    }

    private func content(for legalCase: LegalCase) -> some View {
        let state = appState.state(of: legalCase)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 0) {
                    StatePill(state: state)
                    Text(legalCase.title)
                        .font(Theme.font(25, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .padding(.top, 10)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(legalCase.number)
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 6)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .sideMargin()
                .padding(.top, 16)
                .padding(.bottom, 18)

                if legalCase.isUnderSeal {
                    sealedNotice
                } else if let hearing = legalCase.hearing, !hearing.isConfirmed {
                    nextStepCard(hearing: hearing)
                } else if let hearing = legalCase.hearing, hearing.isConfirmed {
                    confirmedCard(hearing: hearing)
                }

                // Facts
                VStack(spacing: 0) {
                    KeyValueRow(label: "case.field.opposing", value: legalCase.opposingParty)
                    KeyValueRow(label: "case.field.court", value: legalCase.court)
                    KeyValueRow(label: "case.field.value", value: Format.money(legalCase.claimValue), isMono: true)
                    if let provision = legalCase.provision {
                        KeyValueRow(
                            label: "case.field.risk",
                            value: "\(String(localized: .init(legalCase.risk.labelKey))) · \(String(localized: "case.field.provision \(Format.money(provision))"))",
                            tint: legalCase.risk == .high ? Theme.critical : Theme.attention
                        )
                    }
                    KeyValueRow(label: "case.field.lawyer", value: legalCase.responsibleLawyer)
                }
                .sideMargin()
                .padding(.top, 20)

                // Timeline
                SectionHeader("case.section.timeline")

                if legalCase.isUnderSeal {
                    EmptyStateView(
                        systemImage: "lock.shield",
                        title: "case.underSeal.timelineTitle",
                        message: "case.underSeal.timelineMessage"
                    )
                    .card()
                    .sideMargin()
                } else if legalCase.visibleMovements.isEmpty {
                    EmptyStateView(
                        systemImage: "clock.badge.questionmark",
                        title: "case.timeline.empty.title",
                        message: "case.timeline.empty.message"
                    )
                    .card()
                    .sideMargin()
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(legalCase.visibleMovements.enumerated()), id: \.element.id) { index, movement in
                            NavigationLink {
                                MovementDetailView(caseID: legalCase.id, movementID: movement.id)
                            } label: {
                                TimelineRow(
                                    movement: movement,
                                    isFirst: index == 0,
                                    isLast: index == legalCase.visibleMovements.count - 1
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .card()
                    .sideMargin()
                }

                WhatsAppButton(
                    context: .movement(
                        caseNumber: legalCase.number,
                        caseTitle: legalCase.title,
                        movementDate: legalCase.lastVisibleUpdate
                    ),
                    caseID: legalCase.id,
                    titleKey: "case.action.ask"
                )
                .sideMargin()
                .padding(.top, 20)
            }
            .padding(.bottom, 28)
        }
    }

    // MARK: Cards

    private func nextStepCard(hearing: Hearing) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("case.nextStep.label")
                .font(Theme.font(10.5, weight: .semibold))
                .kerning(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Theme.critical)

            Text("case.nextStep.confirmHearing")
                .font(Theme.font(17, weight: .semibold))
                .foregroundStyle(Theme.primary)

            Text("case.nextStep.hearingDetail \(Format.dateTime(hearing.date)) \(hearing.venue) \(hearing.address)")
                .font(Theme.font(13.5))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button("case.action.confirmPresence") { showHearingSheet = true }
                .font(Theme.font(14, weight: .semibold))
                .foregroundStyle(Theme.onBrand)
                .padding(.horizontal, 18)
                .frame(minHeight: Theme.minTouchTarget)
                .background(Theme.primary, in: RoundedRectangle(cornerRadius: 10))
                .padding(.top, 6)
        }
        .card()
        .overlay(alignment: .leading) { Rectangle().fill(Theme.critical).frame(width: 3) }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .sideMargin()
    }

    private func confirmedCard(hearing: Hearing) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.onTrack)
            VStack(alignment: .leading, spacing: 2) {
                Text("case.hearing.confirmedTitle")
                    .font(Theme.font(15, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                Text(Format.dateTime(hearing.date))
                    .font(Theme.mono(12.5))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .card()
        .sideMargin()
    }

    private var sealedNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("case.underSeal.badge").font(Theme.font(13, weight: .semibold))
            } icon: {
                Image(systemName: "lock.shield")
            }
            .foregroundStyle(Theme.brass)

            Text("case.underSeal.explanation")
                .font(Theme.font(14))
                .foregroundStyle(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
        .overlay(alignment: .leading) { Rectangle().fill(Theme.brass).frame(width: 3) }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .sideMargin()
    }
}

#Preview {
    NavigationStack {
        CaseDetailView(caseID: MockData.laborCaseID)
            .environment(AppState.signedInPreview())
    }
}
