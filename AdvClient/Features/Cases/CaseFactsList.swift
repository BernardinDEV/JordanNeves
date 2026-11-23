import SwiftUI

/// Os fatos frios do caso — parte contrária, vara, valor, risco, responsável.
/// Cada linha só aparece quando a fonte informa o dado.
struct CaseFactsList: View {
    let legalCase: LegalCase

    var body: some View {
        VStack(spacing: 0) {
            if let opposing = legalCase.opposingParty, !opposing.isEmpty {
                KeyValueRow(label: "case.field.opposing", value: opposing)
            }
            if let role = legalCase.clientRole {
                KeyValueRow(label: "case.field.role", value: role)
            }
            if let caseClass = legalCase.caseClass {
                KeyValueRow(label: "case.field.class", value: caseClass)
            }
            // A fonte somente leitura usa a vara como título: não repete.
            if !legalCase.court.isEmpty, legalCase.court != legalCase.title {
                KeyValueRow(label: "case.field.court", value: legalCase.court)
            }
            if let claimValue = legalCase.claimValue {
                KeyValueRow(label: "case.field.value", value: Format.money(claimValue), isMono: true)
            }
            if let provision = legalCase.provision {
                KeyValueRow(
                    label: "case.field.risk",
                    value: "\(Format.string(.init(legalCase.risk.labelKey))) · \(Format.string("case.field.provision \(Format.money(provision))"))",
                    tint: legalCase.risk == .high ? Theme.critical : Theme.attention
                )
            }
            if !legalCase.responsibleLawyer.isEmpty {
                KeyValueRow(label: "case.field.lawyer", value: legalCase.responsibleLawyer)
            }
        }
    }
}
