import SwiftUI

/// A single movement, translated. The plain-Portuguese version comes first and
/// larger; the court's own words sit below in a collapsed block for anyone who
/// wants to check. Every legal portal does this the other way round — which is
/// exactly why nobody uses them.
struct MovementDetailView: View {
    @Environment(AppState.self) private var appState
    let caseID: UUID
    let movementID: UUID

    @State private var showsOfficialText = false

    private var legalCase: LegalCase? { appState.legalCase(id: caseID) }
    private var movement: CaseMovement? {
        legalCase?.visibleMovements.first { $0.id == movementID }
    }

    var body: some View {
        Group {
            if let legalCase, let movement {
                content(legalCase: legalCase, movement: movement)
            } else {
                // Reachable if the firm unpublishes a movement while the client
                // has it open — better an honest message than stale content.
                EmptyStateView(
                    systemImage: "eye.slash",
                    title: "movement.unavailable.title",
                    message: "movement.unavailable.message"
                )
            }
        }
        .background(Theme.background)
        .navigationTitle(Text(movement.map { Format.date($0.date) } ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appState.markRead(movementID) }
    }

    private func content(legalCase: LegalCase, movement: CaseMovement) -> some View {
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
                    reassuranceKey: movement.requiresClient ? nil : (movement.reassuranceKey ?? "movement.reassurance.nothingToDo")
                )

                // Collapsed, and deliberately styled as secondary.
                DisclosureGroup(isExpanded: $showsOfficialText) {
                    Text(movement.officialText)
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                } label: {
                    Text("movement.officialText.toggle \(legalCase.courtShort)")
                        .font(Theme.font(13.5))
                        .foregroundStyle(Theme.primary)
                }
                .tint(Theme.primary)
                .padding(13)
                .background(Theme.fill, in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, 18)

                // Who to ask
                VStack(alignment: .leading, spacing: 11) {
                    HStack(spacing: 11) {
                        Text(initials(of: legalCase.responsibleLawyer))
                            .font(Theme.font(13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Theme.primary, in: Circle())
                        VStack(alignment: .leading, spacing: 1) {
                            Text(legalCase.responsibleLawyer)
                                .font(Theme.font(14.5, weight: .semibold))
                                .foregroundStyle(Theme.primary)
                            Text("movement.responsible")
                                .font(Theme.font(12))
                                .foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 0)
                    }

                    Text("movement.anyDoubt")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.body)

                    WhatsAppButton(
                        context: .movement(
                            caseNumber: legalCase.number,
                            caseTitle: legalCase.title,
                            movementDate: movement.date
                        ),
                        caseID: legalCase.id,
                        titleKey: "movement.action.ask"
                    )
                }
                .card()
                .padding(.top, 20)
            }
            .sideMargin()
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private func initials(of name: String) -> String {
        name.split(separator: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined().uppercased()
    }
}

#Preview {
    NavigationStack {
        MovementDetailView(
            caseID: MockData.laborCaseID,
            movementID: MockData.cases[0].visibleMovements[0].id
        )
        .environment(AppState.signedInPreview())
    }
}
