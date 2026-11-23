import Foundation

/// Um andamento publicado junto do caso a que pertence — o par que as listas
/// de "Para saber" precisam para montar a linha e abrir o detalhe.
struct MovementReference: Identifiable, Equatable, Sendable {
    let movement: CaseMovement
    let legalCase: LegalCase

    var id: UUID { movement.id }
}
