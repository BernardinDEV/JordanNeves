import Foundation

/// O contrato do app com a API canônica do produto — versão 1.
///
/// Toda chamada que o app faz está aqui, e só aqui. A tabela completa, com o
/// que cada uma devolve, está em `docs/camada-de-servico.md`. As três ações
/// devolvem o snapshot inteiro já atualizado, como a demonstração faz, para a
/// tela nunca precisar adivinhar o que mudou.
enum BackendAPI {

    /// O snapshot sempre tenta a rede (um segundo de validade só absorve telas
    /// que pedem juntas) e, sem rede, responde com o guardado por até sete dias.
    /// Validade longa faria um "atualizar" depois de confirmar uma audiência
    /// devolver o estado de antes — o cache não vê os `POST`.
    static let snapshotCache = CachePolicy.custom(ttl: 1, staleWindow: 7 * 86_400)

    // MARK: Acesso

    static func requestCode(email: String) throws -> Endpoint<CodeChallengeDTO> {
        Endpoint(
            method: .post,
            path: "/v1/auth/code",
            body: try .json(["email": email]),
            requiresAuthentication: false
        )
    }

    static func createSession(email: String, code: String) throws -> Endpoint<SessionDTO> {
        Endpoint(
            method: .post,
            path: "/v1/auth/session",
            body: try .json(["email": email, "code": code]),
            requiresAuthentication: false
        )
    }

    static func deleteSession() -> Endpoint<EmptyResponse> {
        .delete("/v1/auth/session")
    }

    // MARK: Dados

    static func snapshot() -> Endpoint<SnapshotDTO> {
        .get("/v1/snapshot", cache: snapshotCache)
    }

    static func confirmHearing(caseID: UUID) -> Endpoint<SnapshotDTO> {
        .post("/v1/cases/\(caseID.uuidString)/hearing/confirmation")
    }

    static func resolvePendency(id: UUID) -> Endpoint<SnapshotDTO> {
        .post("/v1/pendencies/\(id.uuidString)/resolution")
    }

    /// Corpo cru, sem multipart: um arquivo por chamada, metadados na query.
    static func upload(_ file: UploadFile, caseID: UUID?) -> Endpoint<SnapshotDTO> {
        var query = ["fileName": file.name]
        if let caseID { query["caseId"] = caseID.uuidString }
        return .post(
            "/v1/documents",
            body: .raw(file.data, contentType: file.contentType),
            query: query,
            timeout: 120
        )
    }

    static func whatsAppHandoff(caseID: UUID?) throws -> Endpoint<EmptyResponse> {
        .post("/v1/events/whatsapp-handoff", body: try .json(["caseId": caseID?.uuidString]))
    }
}
