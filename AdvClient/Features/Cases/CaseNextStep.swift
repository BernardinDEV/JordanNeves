import SwiftUI

/// O cartão logo abaixo do título: o que este caso pede agora. Segredo de
/// justiça, audiência a confirmar ou audiência já confirmada — ou nada.
struct CaseNextStep: View {
    let legalCase: LegalCase
    let confirm: (Hearing) -> Void

    var body: some View {
        if legalCase.isUnderSeal {
            SealedCaseNotice()
        } else if let hearing = legalCase.hearing {
            if hearing.isConfirmed {
                HearingConfirmedCard(hearing: hearing)
            } else {
                HearingNextStepCard(hearing: hearing) { confirm(hearing) }
            }
        }
    }
}
