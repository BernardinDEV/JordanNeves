import SwiftUI

/// A tela de cada `AppRoute`.
struct AppRouteDestination: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .legalCase(let id):
            CaseDetailView(caseID: id)
        case .document(let id):
            ContractDetailView(documentID: id)
        case .movement(let caseID, let movementID):
            MovementDetailView(caseID: caseID, movementID: movementID)
        case .notifications:
            NotificationsView()
        }
    }
}

extension View {
    /// Registra os destinos de `AppRoute`. Uma vez por `NavigationStack`, na
    /// raiz — nunca dentro de uma tela empilhada.
    func appRouteDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            AppRouteDestination(route: route)
        }
    }
}
