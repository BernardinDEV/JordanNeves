#if DEBUG
import SwiftUI

/// Debug-only jump straight to a screen, driven by the `DEMO_ROUTE` environment
/// variable.
///
/// Exists so screenshots can be captured deterministically without tapping
/// through the whole flow:
///
///     xcrun simctl launch <device> <bundle-id-da-marca> \
///         --setenv DEMO_ROUTE=contract
///
/// Compiled out of Release builds entirely.
enum DemoRoute: String {
    case onboarding
    case signIn
    case home
    case notifications
    case cases
    case caseDetail
    case sealedCase
    case movement
    case hearing
    case documents
    case contract
    case upload
    case profile

    static var current: DemoRoute? {
        guard let raw = ProcessInfo.processInfo.environment["DEMO_ROUTE"] else { return nil }
        return DemoRoute(rawValue: raw)
    }
}

struct DemoRouteView: View {
    @Environment(AppState.self) private var appState
    let route: DemoRoute

    var body: some View {
        switch route {
        case .onboarding:
            OnboardingView()
        case .signIn:
            SignInFlow()
        case .home, .cases, .documents, .profile:
            MainTabView()
        case .notifications:
            NavigationStack { NotificationsView() }
        case .caseDetail:
            NavigationStack { CaseDetailView(caseID: MockData.laborCaseID) }
        case .sealedCase:
            NavigationStack { CaseDetailView(caseID: MockData.sealedCaseID) }
        case .movement:
            NavigationStack {
                if let movement = appState.legalCase(id: MockData.laborCaseID)?.visibleMovements.first {
                    MovementDetailView(caseID: MockData.laborCaseID, movementID: movement.id)
                }
            }
        case .hearing:
            if let hearing = appState.legalCase(id: MockData.laborCaseID)?.hearing {
                HearingSheet(
                    caseID: MockData.laborCaseID,
                    caseNumber: appState.legalCase(id: MockData.laborCaseID)?.number ?? "",
                    hearing: hearing
                )
            }
        case .contract:
            NavigationStack { ContractDetailView(documentID: MockData.suzanoContractID) }
        case .upload:
            UploadSheet()
        }
    }
}
#endif
