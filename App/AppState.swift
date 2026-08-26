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

/// Where the launch sequence currently is.
enum LaunchPhase: Equatable {
    case splash
    case onboarding
    case signIn
    case ready
}

@MainActor
@Observable
final class AppState {
    // Dependency injection point — swap the mocks for API-backed services later.
    let auth: AuthService = MockAuthService()
    let repository: ClientDataRepository = MockClientRepository()

    // MARK: Session

    private(set) var company: Company?
    var isSignedIn: Bool { company != nil }

    private(set) var hasSeenOnboarding: Bool
    private(set) var didFinishSplash = false

    /// When enabled, the app requires biometric authentication every time it
    /// returns to the foreground. Persisted in the Keychain alongside the session.
    private(set) var biometricEnabled: Bool = false
    /// Set once the user has answered the Face ID question, so the app does not
    /// ask again on every sign-in.
    private(set) var didAskBiometrics: Bool = false

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app.language")
            // Strings built outside SwiftUI's environment (deadlines, WhatsApp
            // message bodies) resolve against this, not the device language.
            Format.uiLocale = language.locale
        }
    }

    // MARK: Client data

    private(set) var snapshot: ClientSnapshot = .empty
    private(set) var isLoading = false
    private(set) var loadFailed = false
    /// Notifications the client has opened, so the badge can settle.
    private(set) var readMovementIDs: Set<UUID> = []

    var phase: LaunchPhase {
        if !didFinishSplash { return .splash }
        if !hasSeenOnboarding { return .onboarding }
        if !isSignedIn { return .signIn }
        return .ready
    }

    private enum Keys {
        static let isSignedIn = "session.isSignedIn"
        static let company = "session.company"
        static let biometricEnabled = "session.biometricEnabled"
        static let didAskBiometrics = "session.didAskBiometrics"
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
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: "app.hasSeenOnboarding")
        Format.uiLocale = language.locale

        // Keychain items survive app uninstall; UserDefaults do not. A missing
        // first-launch flag means a fresh install — clear any stale session left
        // behind by a previous install so a new user can't inherit the old account.
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            Self.clearKeychainSession()
        }
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

        restoreSession()

        #if DEBUG
        // Screenshot runs jump straight to a screen, so the data has to be there
        // before the first frame — no async load to wait on.
        if DemoRoute.current != nil {
            company = MockData.company
            didFinishSplash = true
            hasSeenOnboarding = true
            didAskBiometrics = true
            snapshot = ClientSnapshot(
                cases: MockData.cases,
                documents: MockData.documents,
                pendencies: MockData.pendencies,
                invoices: MockData.invoices,
                lastSyncedAt: Rules.calendar.date(bySettingHour: 8, minute: 30, second: 0, of: .now) ?? .now
            )
        }
        #endif
    }

    // MARK: - Launch flow

    func finishSplash() { didFinishSplash = true }

    func completeOnboarding() {
        hasSeenOnboarding = true
        UserDefaults.standard.set(true, forKey: "app.hasSeenOnboarding")
    }

    // MARK: - Authentication

    func requestCode(email: String) async throws -> CodeChallenge {
        try await auth.requestCode(email: email)
    }

    func verify(code: String, challenge: CodeChallenge) async throws {
        let company = try await auth.verify(code: code, challenge: challenge)
        self.company = company
        persistSession(company)
        await refresh()
    }

    func signOut() {
        company = nil
        biometricEnabled = false
        didAskBiometrics = false
        snapshot = .empty
        readMovementIDs = []
        Self.clearKeychainSession()
    }

    // MARK: - Biometric lock

    var canUseBiometrics: Bool { BiometricAuthenticator.isAvailable }
    var biometryName: String { BiometricAuthenticator.biometryName }

    func setBiometricEnabled(_ enabled: Bool) {
        biometricEnabled = enabled
        KeychainHelper.save(enabled ? "true" : "false", forKey: Keys.biometricEnabled)
        markBiometricsAsked()
    }

    func markBiometricsAsked() {
        didAskBiometrics = true
        KeychainHelper.save("true", forKey: Keys.didAskBiometrics)
    }

    /// Evaluated on every foreground transition. Returns true if the app should
    /// be unlocked. Passes through when the user isn't signed in, hasn't opted in,
    /// or biometrics became unavailable — so a system-level change can't lock a
    /// legitimate user out permanently.
    func evaluateBiometricLock() async -> Bool {
        guard isSignedIn, biometricEnabled, BiometricAuthenticator.isAvailable else { return true }
        // Resolve against the in-app language, not the system locale, so the
        // system prompt matches the rest of the UI.
        let reason = Format.string("biometric.reason", locale: language.locale)
        return await BiometricAuthenticator.evaluate(reason: reason)
    }

    // MARK: - Data

    func refresh() async {
        guard let company else { return }
        isLoading = true
        loadFailed = false
        do {
            snapshot = try await repository.snapshot(for: company.id)
        } catch {
            loadFailed = true
        }
        isLoading = false
    }

    func confirmHearing(caseID: UUID) async {
        guard let updated = try? await repository.confirmHearing(caseID: caseID) else { return }
        snapshot = updated
    }

    func resolvePendency(id: UUID) async {
        guard let updated = try? await repository.resolvePendency(id: id) else { return }
        snapshot = updated
    }

    func upload(fileName: String, caseID: UUID?) async {
        guard let updated = try? await repository.upload(fileName: fileName, caseID: caseID) else { return }
        snapshot = updated
    }

    func markRead(_ movementID: UUID) {
        readMovementIDs.insert(movementID)
    }

    // MARK: - Derived views over the snapshot
    //
    // Everything below goes through `Rules`, so the dashboard, the notification
    // list and the documents screen can never disagree about what is urgent.

    var cases: [LegalCase] { snapshot.cases }
    var openCases: [LegalCase] { snapshot.cases.filter(\.isOpen) }
    var closedCases: [LegalCase] { snapshot.cases.filter { !$0.isOpen } }
    var documents: [ClientDocument] { snapshot.documents.filter { !$0.isArchived } }
    var invoices: [Invoice] { snapshot.invoices }

    var nextInvoice: Invoice? {
        snapshot.invoices.filter { !$0.isPaid }.min { $0.dueDate < $1.dueDate }
    }

    var position: PortfolioPosition {
        Rules.position(cases: snapshot.cases, pendencies: snapshot.pendencies)
    }

    var openPendencies: [Pendency] {
        Rules.openPendencies(snapshot.pendencies)
    }

    var casesRequiringClient: [LegalCase] {
        Rules.casesRequiringClient(snapshot.cases, pendencies: snapshot.pendencies)
    }

    var documentsNeedingAttention: [ClientDocument] {
        Rules.documentsNeedingAttention(snapshot.documents)
    }

    var contracts: [ClientDocument] {
        documents.filter { $0.kind == .contract }
    }

    func state(of legalCase: LegalCase) -> CaseState {
        Rules.state(of: legalCase, pendencies: snapshot.pendencies)
    }

    func nextDeadline(for legalCase: LegalCase) -> Date? {
        Rules.nextDeadline(for: legalCase, pendencies: snapshot.pendencies)
    }

    func contractAlert(for document: ClientDocument) -> ContractAlert? {
        Rules.contractAlert(for: document)
    }

    func legalCase(id: UUID?) -> LegalCase? {
        guard let id else { return nil }
        return snapshot.cases.first { $0.id == id }
    }

    func document(id: UUID?) -> ClientDocument? {
        guard let id else { return nil }
        return snapshot.documents.first { $0.id == id }
    }

    /// Movements the client hasn't opened yet — everything that would have been
    /// a push, minus what they already read.
    var unreadCount: Int {
        let pending = openPendencies.count
        let unreadInfo = snapshot.cases
            .flatMap(\.visibleMovements)
            .filter { !$0.requiresClient && !readMovementIDs.contains($0.id) && Rules.days(from: $0.date, to: .now) <= 14 }
            .count
        return pending + unreadInfo
    }

    /// Movements worth listing under "Para saber" — published, no action needed.
    var informationalMovements: [(movement: CaseMovement, legalCase: LegalCase)] {
        snapshot.cases
            .flatMap { legalCase in legalCase.visibleMovements.map { ($0, legalCase) } }
            .filter { !$0.0.requiresClient }
            .sorted { $0.0.date > $1.0.date }
            .prefix(8)
            .map { (movement: $0.0, legalCase: $0.1) }
    }

    // MARK: - WhatsApp

    var firmPhone: String { BrandConfiguration.current.contact.whatsapp }

    func whatsAppURL(_ context: WhatsAppLink.Context, caseID: UUID? = nil) -> URL? {
        Task { await repository.recordWhatsAppHandoff(caseID: caseID) }
        return WhatsAppLink.url(
            phone: firmPhone,
            context: context,
            companyName: company?.tradeName ?? BrandConfiguration.current.displayName
        )
    }

    // MARK: - Session persistence

    private func restoreSession() {
        guard KeychainHelper.load(forKey: Keys.isSignedIn) == "true",
              let json = KeychainHelper.load(forKey: Keys.company),
              let data = json.data(using: .utf8),
              let restored = try? JSONDecoder().decode(Company.self, from: data) else { return }
        company = restored
        biometricEnabled = KeychainHelper.load(forKey: Keys.biometricEnabled) == "true"
        didAskBiometrics = KeychainHelper.load(forKey: Keys.didAskBiometrics) == "true"
    }

    private func persistSession(_ company: Company) {
        KeychainHelper.save("true", forKey: Keys.isSignedIn)
        if let data = try? JSONEncoder().encode(company),
           let json = String(data: data, encoding: .utf8) {
            KeychainHelper.save(json, forKey: Keys.company)
        }
    }

    private static func clearKeychainSession() {
        KeychainHelper.delete(forKey: Keys.isSignedIn)
        KeychainHelper.delete(forKey: Keys.company)
        KeychainHelper.delete(forKey: Keys.biometricEnabled)
        KeychainHelper.delete(forKey: Keys.didAskBiometrics)
    }
}

#if DEBUG
extension AppState {
    /// Preview convenience — a signed-in state with demo data, no Keychain writes.
    static func signedInPreview() -> AppState {
        let state = AppState()
        state.company = MockData.company
        state.didFinishSplash = true
        state.hasSeenOnboarding = true
        state.didAskBiometrics = true
        state.snapshot = ClientSnapshot(
            cases: MockData.cases,
            documents: MockData.documents,
            pendencies: MockData.pendencies,
            invoices: MockData.invoices,
            lastSyncedAt: .now
        )
        return state
    }
}
#endif
