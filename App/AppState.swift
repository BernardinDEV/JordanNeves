import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case portuguese = "pt-BR"
    case english = "en"

    var id: String { rawValue }

    var labelKey: LocalizedStringKey {
        switch self {
        case .portuguese: "language.portuguese"
        case .english: "language.english"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }
}

@MainActor
@Observable
final class AppState {
    // Dependency injection point — swap mocks for real services later.
    let auth: AuthService = MockAuthService()
    let repository: CaseRepository = MockCaseRepository()

    private(set) var client: Client?
    var isLoggedIn: Bool { client != nil }

    /// When enabled, the app requires biometric authentication every time it
    /// returns to the foreground. Persisted in the Keychain alongside the session.
    private(set) var biometricEnabled: Bool = false

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app.language") }
    }

    private enum Keys {
        static let isSignedIn = "session.isSignedIn"
        static let client = "session.client"
        static let biometricEnabled = "session.biometricEnabled"
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app.language")
        if let saved, let lang = AppLanguage(rawValue: saved) {
            language = lang
        } else {
            // Follow the device language; default to Portuguese.
            let preferred = Locale.preferredLanguages.first ?? "pt-BR"
            language = preferred.hasPrefix("en") ? .english : .portuguese
        }

        // Keychain items survive app uninstall; UserDefaults do not. A missing
        // first-launch flag means a fresh install — clear any stale session left
        // behind by a previous install so a new user can't inherit the old account.
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            Self.clearKeychainSession()
        }
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

        restoreSession()
    }

    // MARK: - Authentication

    func login(identifier: String, password: String) async throws {
        let client = try await auth.login(identifier: identifier, password: password)
        self.client = client
        persistSession(client)
    }

    func logout() {
        client = nil
        biometricEnabled = false
        Self.clearKeychainSession()
    }

    // MARK: - Biometric lock

    var canUseBiometrics: Bool { BiometricAuthenticator.isAvailable }
    var biometryName: String { BiometricAuthenticator.biometryName }

    func setBiometricEnabled(_ enabled: Bool) {
        biometricEnabled = enabled
        KeychainHelper.save(enabled ? "true" : "false", forKey: Keys.biometricEnabled)
    }

    /// Evaluated on every foreground transition. Returns true if the app should
    /// be unlocked. Passes through when the user isn't signed in, hasn't opted in,
    /// or biometrics became unavailable — so a system-level change can't lock a
    /// legitimate user out permanently.
    func evaluateBiometricLock() async -> Bool {
        guard isLoggedIn, biometricEnabled, BiometricAuthenticator.isAvailable else { return true }
        // Resolve against the in-app language, not the system locale, so the
        // system prompt matches the rest of the UI.
        let reason = String(localized: "biometric.reason", locale: language.locale)
        return await BiometricAuthenticator.evaluate(reason: reason)
    }

    // MARK: - Session persistence

    private func restoreSession() {
        guard KeychainHelper.load(forKey: Keys.isSignedIn) == "true",
              let json = KeychainHelper.load(forKey: Keys.client),
              let data = json.data(using: .utf8),
              let restored = try? JSONDecoder().decode(Client.self, from: data) else { return }
        client = restored
        biometricEnabled = KeychainHelper.load(forKey: Keys.biometricEnabled) == "true"
    }

    private func persistSession(_ client: Client) {
        KeychainHelper.save("true", forKey: Keys.isSignedIn)
        if let data = try? JSONEncoder().encode(client),
           let json = String(data: data, encoding: .utf8) {
            KeychainHelper.save(json, forKey: Keys.client)
        }
    }

    private static func clearKeychainSession() {
        KeychainHelper.delete(forKey: Keys.isSignedIn)
        KeychainHelper.delete(forKey: Keys.client)
        KeychainHelper.delete(forKey: Keys.biometricEnabled)
    }
}

#if DEBUG
extension AppState {
    /// Preview/testing convenience — injects a logged-in client without touching the Keychain.
    static func loggedInPreview(_ client: Client = MockData.client) -> AppState {
        let state = AppState()
        state.client = client
        return state
    }
}
#endif
