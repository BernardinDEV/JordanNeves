import SwiftUI

/// O escritório: marca, razão social e a frase de posicionamento.
struct FirmCard: View {
    let legalName: String
    let tagline: String

    var body: some View {
        HStack(spacing: 14) {
            BrandMark()
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: legalName)
                    .font(Theme.font(16.5, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: tagline)
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card()
        .sideMargin()
        .accessibilityElement(children: .combine)
    }
}
