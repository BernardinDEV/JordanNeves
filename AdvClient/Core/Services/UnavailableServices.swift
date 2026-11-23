import Foundation

/// Serviços de uma marca mal configurada: toda chamada falha com o mesmo erro.
/// O cliente vê "não foi possível carregar" no login, e não um app que finge
/// funcionar.
struct UnavailableServices: AuthService, ClientDataRepository {
    let error: APIError

    func requestCode(email: String) async throws -> CodeChallenge { throw error }
    func verify(code: String, challenge: CodeChallenge) async throws -> Company { throw error }
    func signOut() async {}

    func snapshot(for companyID: UUID) async throws -> ClientSnapshot { throw error }
    func confirmHearing(caseID: UUID) async throws -> ClientSnapshot { throw error }
    func resolvePendency(id: UUID) async throws -> ClientSnapshot { throw error }
    func upload(_ file: UploadFile, caseID: UUID?) async throws -> ClientSnapshot { throw error }
    func recordWhatsAppHandoff(caseID: UUID?) async {}
}
