import SwiftUI

/// One case. "Seu próximo passo" is the only filled button on the screen; the
/// cold facts — value, court, risk — come *after* the action, not before it.
struct CaseDetailView: View {
    @Environment(AppState.self) private var appState
    let caseID: UUID

    /// A audiência cuja confirmação está aberta. Guardar a própria audiência,
    /// e não um booleano, garante que a folha sempre tem o que mostrar.
    @State private var hearingToConfirm: Hearing?

    private var legalCase: LegalCase? { appState.legalCase(id: caseID) }

    var body: some View {
        Group {
            if let legalCase {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        CaseHeader(legalCase: legalCase, state: appState.state(of: legalCase))

                        CaseNextStep(legalCase: legalCase, confirm: confirmHearing)

                        CaseFactsList(legalCase: legalCase)
                            .sideMargin()
                            .padding(.top, 20)

                        SectionHeader("case.section.timeline")
                        CaseTimeline(legalCase: legalCase)
                            .sideMargin()

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
            } else {
                EmptyStateView(systemImage: "questionmark.folder", title: "case.notFound")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.background)
        .navigationTitle(legalCase.map { Format.string(.init($0.area.labelKey)) } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $hearingToConfirm) { hearing in
            HearingSheet(caseID: caseID, caseNumber: legalCase?.number ?? "", hearing: hearing)
        }
    }

    private func confirmHearing(_ hearing: Hearing) {
        hearingToConfirm = hearing
    }
}

#Preview {
    NavigationStack {
        CaseDetailView(caseID: DemoDataset.current.hearingCaseID)
            .appRouteDestinations()
            .environment(AppState.signedInPreview())
    }
}
