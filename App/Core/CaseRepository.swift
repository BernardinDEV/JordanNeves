import Foundation

/// Swap `MockCaseRepository` for an API-backed implementation later —
/// the UI only ever talks to this protocol.
protocol CaseRepository: Sendable {
    func cases(for clientID: UUID) async throws -> [LegalCase]
}

struct MockCaseRepository: CaseRepository {
    func cases(for clientID: UUID) async throws -> [LegalCase] {
        try? await Task.sleep(for: .milliseconds(400)) // simulate network
        return MockData.cases
    }
}
