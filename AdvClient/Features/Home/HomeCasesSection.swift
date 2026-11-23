import SwiftUI

/// "Seus casos": os ativos que não estão em "Exige você".
struct HomeCasesSection: View {
    let cases: [LegalCase]
    /// Falso só quando a empresa não tem caso ativo nenhum — aí entra o estado
    /// vazio. Com casos ativos todos em "Exige você", a lista fica só curta.
    let hasOpenCases: Bool
    var isPersonal = false
    let seeAll: () -> Void

    var body: some View {
        SectionHeader(title: "home.section.cases") {
            Button("common.seeAll", action: seeAll)
                .buttonStyle(LinkButtonStyle(compact: true))
        }

        if hasOpenCases {
            VStack(spacing: 12) {
                ForEach(cases) { legalCase in
                    CaseCardLink(legalCase: legalCase)
                }
            }
            .sideMargin()
        } else {
            EmptyStateView(
                systemImage: "text.document",
                title: "home.empty.cases.title",
                message: isPersonal ? "home.empty.cases.message.personal" : "home.empty.cases.message"
            )
            .card()
            .sideMargin()
        }
    }
}
