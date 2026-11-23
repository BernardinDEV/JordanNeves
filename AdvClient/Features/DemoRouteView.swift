#if DEBUG
import SwiftUI

/// A tela de cada `DemoRoute`.
struct DemoRouteView: View {
    @Environment(AppState.self) private var appState
    let route: DemoRoute
    private let dataset = DemoDataset.current

    var body: some View {
        switch route {
        case .onboarding:
            OnboardingView()
        case .signIn:
            SignInFlow()
        case .code:
            NavigationStack {
                CodeStep(
                    challenge: CodeChallenge(
                        email: DemoDataset.current.company.userEmail,
                        issuedAt: .now,
                        expiresAt: .now.addingTimeInterval(600),
                        resendAllowedAt: .now.addingTimeInterval(45)
                    ),
                    onResend: { _ in }
                )
                .background(Theme.background)
            }
        // Cada rota de aba abre na sua aba — antes as quatro caíam no painel.
        case .home:
            MainTabView(initialTab: .home)
        case .cases:
            MainTabView(initialTab: .cases)
        case .documents:
            MainTabView(initialTab: .documents)
        case .contact:
            MainTabView(initialTab: .contact)
        case .profile:
            MainTabView(initialTab: .profile)
        case .notifications:
            NavigationStack { NotificationsView().appRouteDestinations() }
        case .caseDetail:
            NavigationStack { CaseDetailView(caseID: dataset.hearingCaseID).appRouteDestinations() }
        case .sealedCase:
            NavigationStack { CaseDetailView(caseID: dataset.sealedCaseID).appRouteDestinations() }
        case .movement:
            NavigationStack {
                if let movement = appState.legalCase(id: dataset.hearingCaseID)?.visibleMovements.first {
                    MovementDetailView(caseID: dataset.hearingCaseID, movementID: movement.id)
                }
            }
        case .hearing:
            if let legalCase = appState.legalCase(id: dataset.hearingCaseID), let hearing = legalCase.hearing {
                HearingSheet(caseID: legalCase.id, caseNumber: legalCase.number, hearing: hearing)
            }
        case .hearingConfirmed:
            if let hearing = appState.legalCase(id: dataset.hearingCaseID)?.hearing {
                HearingConfirmedView(hearing: hearing, onClose: {})
                    .background(Theme.background)
            }
        case .uploadSent:
            UploadSentView(fileName: "contrato-social-2026.pdf", onClose: {})
                .background(Theme.background)
        case .contract:
            NavigationStack { ContractDetailView(documentID: dataset.renewalContractID) }
        case .upload:
            UploadSheet()
        }
    }
}
#endif
