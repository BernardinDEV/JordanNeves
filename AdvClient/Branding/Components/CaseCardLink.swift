import SwiftUI

/// Um cartão de caso que abre o caso. Painel e lista de casos usam o mesmo,
/// então estado e prazo vêm do mesmo lugar nas duas telas.
struct CaseCardLink: View {
    @Environment(AppState.self) private var appState
    let legalCase: LegalCase
    /// Força o estado exibido. O painel usa em "Exige você", onde o estado já
    /// está decidido pela seção em que o cartão aparece.
    var state: CaseState?

    var body: some View {
        NavigationLink(value: AppRoute.legalCase(legalCase.id)) {
            CaseCard(
                legalCase: legalCase,
                state: state ?? appState.state(of: legalCase),
                deadline: appState.nextDeadline(for: legalCase)
            )
        }
        .buttonStyle(CardPressStyle())
    }
}
