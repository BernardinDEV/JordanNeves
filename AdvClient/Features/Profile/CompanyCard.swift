import SwiftUI

/// A empresa e quem está conectado neste aparelho.
struct CompanyCard: View {
    let company: Company

    var body: some View {
        HStack(spacing: 14) {
            Text(company.initials)
                .font(Theme.font(17, weight: .semibold))
                .foregroundStyle(Theme.onBrand)
                .frame(width: 52, height: 52)
                .background(Theme.brass, in: .circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(company.legalName)
                    .font(Theme.font(16.5, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Format.taxID(company.cnpj))
                    .font(Theme.mono(12.5))
                    .foregroundStyle(Theme.muted)
                Text("profile.signedInAs \(company.userEmail)")
                    .font(Theme.font(12))
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
