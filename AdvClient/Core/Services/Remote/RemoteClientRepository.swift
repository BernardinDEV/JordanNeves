import Foundation

/// `ClientDataRepository` sobre a API canônica.
///
/// Não sabe qual provedor jurídico o escritório usa — essa é a ideia. O
/// `companyID` não vai na chamada: o servidor sabe de quem é o token, e um
/// cliente pedindo os dados de outra empresa por id é exatamente o furo que o
/// isolamento no servidor existe para fechar.
struct RemoteClientRepository: ClientDataRepository {
    let client: APIClient

    func snapshot(for companyID: UUID) async throws -> ClientSnapshot {
        try await client.value(BackendAPI.snapshot()).domain()
    }

    func confirmHearing(caseID: UUID) async throws -> ClientSnapshot {
        try await client.value(BackendAPI.confirmHearing(caseID: caseID)).domain()
    }

    func resolvePendency(id: UUID) async throws -> ClientSnapshot {
        try await client.value(BackendAPI.resolvePendency(id: id)).domain()
    }

    func upload(_ file: UploadFile, caseID: UUID?) async throws -> ClientSnapshot {
        try await client.value(BackendAPI.upload(file, caseID: caseID)).domain()
    }

    /// Só o rastro — quem, qual caso, quando. Falhar aqui não pode impedir o
    /// cliente de abrir o WhatsApp.
    func recordWhatsAppHandoff(caseID: UUID?) async {
        guard let endpoint = try? BackendAPI.whatsAppHandoff(caseID: caseID) else { return }
        _ = try? await client.value(endpoint)
    }
}
