import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials

    var errorDescription: String? {
        String(localized: "login.error.invalidCredentials")
    }
}

protocol AuthService: Sendable {
    func login(identifier: String, password: String) async throws -> Client
}

/// Accepts any non-empty identifier with password "123456" (demo).
struct MockAuthService: AuthService {
    func login(identifier: String, password: String) async throws -> Client {
        try? await Task.sleep(for: .milliseconds(600))
        guard !identifier.trimmingCharacters(in: .whitespaces).isEmpty,
              password == "123456" else {
            throw AuthError.invalidCredentials
        }
        return MockData.client
    }
}
