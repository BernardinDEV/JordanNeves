import Foundation

enum AuthError: LocalizedError, Equatable {
    case unknownEmail
    case invalidCode
    case codeExpired
    case malformedEmail

    var errorDescription: String? {
        switch self {
        case .unknownEmail: String(localized: "login.error.unknownEmail")
        case .invalidCode: String(localized: "login.error.invalidCode")
        case .codeExpired: String(localized: "login.error.codeExpired")
        case .malformedEmail: String(localized: "login.error.malformedEmail")
        }
    }
}

/// A one-time code issued for a given e-mail.
struct CodeChallenge: Equatable, Sendable {
    let email: String
    let issuedAt: Date
    let expiresAt: Date

    func isExpired(now: Date = .now) -> Bool { now >= expiresAt }

    /// Seconds left before the client may request a new code.
    func secondsRemaining(now: Date = .now) -> Int {
        max(0, Int(expiresAt.timeIntervalSince(now).rounded(.down)))
    }
}

/// Passwordless sign-in.
///
/// Clients are invited by the firm — they never register themselves — so there is
/// no sign-up flow and no password to forget. A six-digit code by e-mail plus
/// Face ID covers every access and removes the single most common support ticket
/// in legal client portals.
protocol AuthService: Sendable {
    func requestCode(email: String) async throws -> CodeChallenge
    func verify(code: String, challenge: CodeChallenge) async throws -> Company
}

/// Demo implementation. Accepts the invited e-mail and the fixed code below.
struct MockAuthService: AuthService {

    /// Documented in the README and used by the App Store review account.
    static let demoCode = "492718"
    static let codeLifetime: TimeInterval = 60

    /// E-mails the firm has invited. A real backend answers the same way for
    /// unknown addresses to avoid leaking who is a client, but in the demo the
    /// explicit error is more useful than the pretence.
    static let invitedEmails: Set<String> = [
        "financeiro@costalog.com.br",
        "diretoria@costalog.com.br",
        "juridico@costalog.com.br"
    ]

    static func isPlausibleEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let at = trimmed.firstIndex(of: "@"), at != trimmed.startIndex else { return false }
        let domain = trimmed[trimmed.index(after: at)...]
        return domain.contains(".") && !domain.hasSuffix(".") && !domain.hasPrefix(".")
    }

    func requestCode(email: String) async throws -> CodeChallenge {
        try? await Task.sleep(for: .milliseconds(500))
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.isPlausibleEmail(normalized) else { throw AuthError.malformedEmail }
        guard Self.invitedEmails.contains(normalized) else { throw AuthError.unknownEmail }
        let now = Date.now
        return CodeChallenge(email: normalized, issuedAt: now, expiresAt: now.addingTimeInterval(Self.codeLifetime))
    }

    func verify(code: String, challenge: CodeChallenge) async throws -> Company {
        try? await Task.sleep(for: .milliseconds(500))
        guard !challenge.isExpired() else { throw AuthError.codeExpired }
        guard code.filter(\.isNumber) == Self.demoCode else { throw AuthError.invalidCode }
        var company = MockData.company
        company.userEmail = challenge.email
        return company
    }
}
