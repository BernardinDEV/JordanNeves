import SwiftUI

/// Ilustração da página 3: contratos contados por situação.
struct ContractsArt: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.primary)
                .padding(.bottom, 12)

            ContractsArtRow(label: "onb.art.contracts", value: "18", tone: Theme.primary)
            ContractsArtRow(label: "onb.art.expiring", value: "3", tone: Theme.attention)
            ContractsArtRow(label: "onb.art.autoRenew", value: "2", tone: Theme.critical)
        }
        .padding(22)
    }
}
