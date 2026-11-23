import SwiftUI

/// "Exige você". Some inteira quando não há nada esperando o cliente.
struct HomeRequiresYouSection: View {
    let cases: [LegalCase]

    var body: some View {
        if !cases.isEmpty {
            SectionHeader("home.section.requiresYou")
            VStack(spacing: 12) {
                ForEach(cases) { legalCase in
                    CaseCardLink(legalCase: legalCase, state: .requiresYou)
                }
            }
            .sideMargin()
        }
    }
}
