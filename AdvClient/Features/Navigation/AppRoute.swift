import Foundation

/// Todo destino para onde uma lista do app pode levar.
///
/// Antes os links carregavam um `UUID` solto, e o painel descobria se era caso
/// ou documento procurando o id nas duas coleções; outras telas montavam o
/// destino dentro do próprio link. Com a rota tipada, cada aba registra os
/// destinos uma única vez (`appRouteDestinations()`) e qualquer tela empilha
/// com `NavigationLink(value:)`.
enum AppRoute: Hashable {
    case legalCase(UUID)
    case document(UUID)
    case movement(caseID: UUID, movementID: UUID)
    case notifications

    /// Para onde uma pendência leva. `nil` quando ela não aponta para nada que
    /// o app saiba abrir — a linha então não se oferece como link.
    init?(pendency: Pendency) {
        switch pendency.kind {
        case .hearing:
            guard let caseID = pendency.caseID else { return nil }
            self = .legalCase(caseID)
        case .contractDecision, .documentRequest:
            if let documentID = pendency.documentID {
                self = .document(documentID)
            } else if let caseID = pendency.caseID {
                self = .legalCase(caseID)
            } else {
                return nil
            }
        }
    }
}
