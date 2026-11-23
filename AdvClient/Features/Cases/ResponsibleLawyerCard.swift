import SwiftUI

/// A quem perguntar: o advogado responsável e a saída para o WhatsApp, já com
/// o processo e a data do andamento na mensagem.
struct ResponsibleLawyerCard: View {
    let legalCase: LegalCase
    let movementDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 11) {
                Text(Format.initials(of: legalCase.responsibleLawyer))
                    .font(Theme.font(13, weight: .semibold))
                    .foregroundStyle(Theme.onBrand)
                    .frame(width: 38, height: 38)
                    .background(Theme.primary, in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(legalCase.responsibleLawyer)
                        .font(Theme.font(14.5, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                    Text("movement.responsible")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)

            Text("movement.anyDoubt")
                .font(Theme.font(14))
                .foregroundStyle(Theme.body)

            WhatsAppButton(
                context: .movement(
                    caseNumber: legalCase.number,
                    caseTitle: legalCase.title,
                    movementDate: movementDate
                ),
                caseID: legalCase.id,
                titleKey: "movement.action.ask"
            )
        }
        .card()
    }
}
