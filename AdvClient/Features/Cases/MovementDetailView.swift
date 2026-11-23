import SwiftUI

/// A single movement, translated. The plain-Portuguese version comes first and
/// larger; the court's own words sit below in a collapsed block for anyone who
/// wants to check. Every legal portal does this the other way round — which is
/// exactly why nobody uses them.
struct MovementDetailView: View {
    @Environment(AppState.self) private var appState
    let caseID: UUID
    let movementID: UUID

    private var legalCase: LegalCase? { appState.legalCase(id: caseID) }
    private var movement: CaseMovement? {
        legalCase?.visibleMovements.first { $0.id == movementID }
    }

    var body: some View {
        let legalCase = self.legalCase
        let movement = self.movement

        Group {
            if let legalCase, let movement {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(movement.displayHeadline)
                            .font(Theme.font(26, weight: .bold))
                            .foregroundStyle(Theme.primary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 18)
                            .accessibilityAddTraits(.isHeader)

                        MeaningBlock(
                            translation: movement.translation ?? "",
                            reassuranceKey: movement.requiresClient
                                ? nil
                                : (movement.reassuranceKey ?? "movement.reassurance.nothingToDo"),
                            labelKey: appState.isPersonalAccount ? "movement.meaning.label.personal" : "movement.meaning.label"
                        )

                        OfficialTextDisclosure(text: movement.officialText, courtShort: legalCase.courtShort)
                            .padding(.top, 18)

                        ResponsibleLawyerCard(legalCase: legalCase, movementDate: movement.date)
                            .padding(.top, 20)
                    }
                    .sideMargin()
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            } else {
                // Reachable if the firm unpublishes a movement while the client
                // has it open — better an honest message than stale content.
                EmptyStateView(
                    systemImage: "eye.slash",
                    title: "movement.unavailable.title",
                    message: "movement.unavailable.message"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.background)
        .navigationTitle(movement.map { Format.date($0.date) } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: markRead)
    }

    private func markRead() {
        appState.markRead(movementID)
    }
}

#Preview {
    NavigationStack {
        MovementDetailView(
            caseID: DemoDataset.current.hearingCaseID,
            movementID: DemoDataset.current.cases.first { $0.id == DemoDataset.current.hearingCaseID }!.visibleMovements[0].id
        )
        .environment(AppState.signedInPreview())
    }
}
