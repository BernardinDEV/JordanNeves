import Foundation

/// Resposta de `POST /v1/auth/code`.
struct CodeChallengeDTO: Decodable, Sendable {
    let expiresAt: Date
    let resendAllowedAt: Date
}

/// Resposta de `POST /v1/auth/session`.
struct SessionDTO: Decodable, Sendable {
    let token: String
    let expiresAt: Date
    let company: CompanyDTO
}

struct CompanyDTO: Decodable, Sendable {
    let id: UUID
    let legalName: String
    let tradeName: String
    let cnpj: String
    let userEmail: String

    func domain() -> Company {
        Company(id: id, legalName: legalName, tradeName: tradeName, cnpj: cnpj, userEmail: userEmail)
    }
}
