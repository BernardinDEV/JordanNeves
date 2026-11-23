import SwiftUI

/// Estado, título e número do processo, no topo do detalhe.
struct CaseHeader: View {
    let legalCase: LegalCase
    let state: CaseState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatePill(state: state)
            Text(legalCase.title)
                .font(Theme.font(25, weight: .bold))
                .foregroundStyle(Theme.primary)
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(legalCase.number)
                .font(Theme.mono(12))
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sideMargin()
        .padding(.top, 8)
        .padding(.bottom, 18)
    }
}
