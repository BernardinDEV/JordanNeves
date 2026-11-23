import Foundation

/// Acesso sem senha contra a API canônica: código por e-mail, depois sessão.
///
/// O código é **do produto**, não do provedor jurídico — o Projuris ADV, por
/// exemplo, não tem login de cliente final. Quem convida o e-mail é o
/// escritório, no painel interno.
struct RemoteAuthService: AuthService {
    let client: APIClient
    let tokens: SessionTokenStore

    func requestCode(email: String) async throws -> CodeChallenge {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard MockAuthService.isPlausibleEmail(normalized) else { throw AuthError.malformedEmail }
        do {
            let issued = try await client.value(BackendAPI.requestCode(email: normalized))
            return CodeChallenge(
                email: normalized,
                issuedAt: .now,
                expiresAt: issued.expiresAt,
                resendAllowedAt: issued.resendAllowedAt
            )
        } catch {
            throw Self.authError(from: error)
        }
    }

    func verify(code: String, challenge: CodeChallenge) async throws -> Company {
        guard !challenge.isExpired() else { throw AuthError.codeExpired }
        do {
            let session = try await client.value(
                BackendAPI.createSession(email: challenge.email, code: code.filter(\.isNumber))
            )
            await tokens.store(.init(value: session.token, expiresAt: session.expiresAt))
            return session.company.domain()
        } catch {
            throw Self.authError(from: error)
        }
    }

    func signOut() async {
        // Primeiro avisa o servidor, com o token ainda válido; depois esquece.
        _ = try? await client.value(BackendAPI.deleteSession())
        await tokens.invalidate()
    }

    /// Erros de acesso que o servidor identifica por `code` viram os de
    /// `AuthError`, que já têm a frase certa nas telas de login. O resto segue
    /// como `APIError`, com a frase genérica de rede.
    static func authError(from error: Error) -> Error {
        guard let apiError = error as? APIError, let code = apiError.code else { return error }
        switch code {
        case "unknown_email": return AuthError.unknownEmail
        case "invalid_code": return AuthError.invalidCode
        case "code_expired": return AuthError.codeExpired
        case "malformed_email": return AuthError.malformedEmail
        default: return apiError
        }
    }
}
