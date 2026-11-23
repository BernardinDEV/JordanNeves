import SwiftUI

/// Segredo de justiça tem estado próprio: sem linha do tempo automática, com a
/// explicação — para o caso não parecer parado.
struct SealedCaseNotice: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("case.underSeal.badge", systemImage: "lock.shield")
                .font(Theme.font(13, weight: .semibold))
                .foregroundStyle(Theme.brass)

            Text("case.underSeal.explanation")
                .font(Theme.font(14))
                .foregroundStyle(Theme.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card(accent: Theme.brass)
        .sideMargin()
    }
}
