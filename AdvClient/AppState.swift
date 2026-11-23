import SwiftUI

@MainActor
@Observable
final class AppState {
    /// De onde vêm os dados: demonstração ou a API do produto, conforme o
    /// `Brand.json`. O `AppState` não sabe qual — nem qual provedor jurídico
    /// está atrás da API.
    private let services: ServiceContainer

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
    /// Tudo o que as telas derivam do snapshot, calculado uma vez por snapshot.
    /// Só `apply(_:)` e `rebuildIndex()` escrevem aqui.
    private(set) var index: PortfolioIndex = .empty
    private(set) var isLoading = false
    /// A última atualização falhou. As telas avisam e continuam mostrando o que
    /// já tinham — com a data de quando é.
    private(set) var loadFailed = false
    /// Notifications the client has opened, so the badge can settle.
    private(set) var readMovementIDs: Set<UUID> = []

    /// Atualização em andamento. Quem pedir outra enquanto esta corre espera
    /// por ela, em vez de disparar uma segunda busca — o login e a primeira
    /// tela pediam as duas ao mesmo tempo.
    private var refreshTask: Task<Void, Never>?

    var phase: LaunchPhase {
        if !didFinishSplash { return .splash }
        if !hasSeenOnboarding { return .onboarding }
        if !isSignedIn { return .signIn }
        return .ready
    }

    /// Ainda não chegou nenhum dado: as telas mostram carregamento, não o
    /// estado vazio — "nenhum caso" antes da resposta é uma mentira breve.
    var isAwaitingFirstLoad: Bool {
        !hasLoadedSnapshot && !loadFailed
    }

    /// Algum snapshot já chegou nesta sessão. Não dá para deduzir da data de
    /// sincronização: a fonte somente leitura responde sem ela.
    private(set) var hasLoadedSnapshot = false

    private enum Keys {
        static let isSignedIn = "session.isSignedIn"
        static let company = "session.company"
        static let biometricEnabled = "session.biometricEnabled"
        static let didAskBiometrics = "session.didAskBiometrics"
    }

    init(services: ServiceContainer? = nil) {
        #if DEBUG
        // Rotas de captura usam sempre a demonstração, qualquer que seja a marca.
        self.services = services ?? (DemoRoute.current != nil ? .demo() : .forCurrentBrand())
        #else
        self.services = services ?? .forCurrentBrand()
        #endif

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
            let dataset = DemoDataset.current
            company = dataset.company
            didFinishSplash = true
            hasSeenOnboarding = true
            didAskBiometrics = true
            apply(dataset.snapshot)
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
        try await services.auth.requestCode(email: email)
    }

    func verify(code: String, challenge: CodeChallenge) async throws {
        let company = try await services.auth.verify(code: code, challenge: challenge)
        await services.session.didSignIn(companyID: company.id.uuidString)
        self.company = company
        persistSession(company)
        await refresh()
    }

    func signOut() {
        // Servidor, token e cache em segundo plano: a tela de login aparece na
        // hora, com ou sem rede.
        let services = services
        Task {
            await services.auth.signOut()
            await services.session.didSignOut()
        }
        refreshTask?.cancel()
        refreshTask = nil
        company = nil
        biometricEnabled = false
        didAskBiometrics = false
        isLoading = false
        loadFailed = false
        apply(.empty)
        hasLoadedSnapshot = false
        readMovementIDs = []
        Self.clearKeychainSession()
    }

    // MARK: - Biometric lock

    var canUseBiometrics: Bool { BiometricAuthenticator.isAvailable }
    var biometryName: String { BiometricAuthenticator.biometryName }

    /// Face ID ligado ou não, como propriedade gravável — é o que o `Toggle` do
    /// perfil liga com `$appState.biometricLockEnabled`. Gravar persiste.
    var biometricLockEnabled: Bool {
        get { biometricEnabled }
        set { setBiometricEnabled(newValue) }
    }

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
        if let refreshTask {
            await refreshTask.value
            return
        }
        guard let company else { return }

        let task = Task { [services] in
            isLoading = true
            defer {
                isLoading = false
                refreshTask = nil
            }
            do {
                // Idempotente; cobre a sessão restaurada no lançamento, que
                // nunca passou por `verify`.
                await services.session.didSignIn(companyID: company.id.uuidString)
                let fetched = try await services.repository.snapshot(for: company.id)
                // Saiu da conta enquanto a resposta vinha: ela não é mais de ninguém.
                guard !Task.isCancelled, self.company?.id == company.id else { return }
                apply(fetched)
                loadFailed = false
            } catch {
                guard !Task.isCancelled else { return }
                if (error as? APIError)?.endsSession == true {
                    // Token vencido ou revogado: de volta ao login, sem
                    // mostrar dado que o servidor já não autoriza.
                    signOut()
                    return
                }
                loadFailed = true
            }
        }
        refreshTask = task
        await task.value
    }

    /// Refaz os derivados com o relógio de agora. Prazos e "há quantos dias"
    /// mudam à meia-noite mesmo sem dado novo — chamado quando o app volta ao
    /// primeiro plano.
    func rebuildIndex() {
        index = PortfolioIndex(snapshot: snapshot)
    }

    /// Volta ao primeiro plano: refaz as contagens de prazo e pede nova
    /// checagem do ambiente antes da próxima chamada de rede.
    func didReturnToForeground() {
        rebuildIndex()
        let services = services
        Task { await services.session.willEnterForeground() }
    }

    // As três ações abaixo **lançam**. Engolir a falha com `try?` fazia a tela
    // dizer "presença confirmada" e "arquivo enviado" quando nada tinha chegado
    // ao escritório.

    func confirmHearing(caseID: UUID) async throws {
        apply(try await services.repository.confirmHearing(caseID: caseID))
    }

    func resolvePendency(id: UUID) async throws {
        apply(try await services.repository.resolvePendency(id: id))
    }

    func upload(_ file: UploadFile, caseID: UUID?) async throws {
        apply(try await services.repository.upload(file, caseID: caseID))
    }

    func markRead(_ movementID: UUID) {
        readMovementIDs.insert(movementID)
    }

    /// A frase que o cliente lê quando uma ação falha — no idioma do app, sem
    /// código de status e sem o texto cru do servidor.
    func userMessage(for error: Error) -> String {
        if let authError = error as? AuthError, let text = authError.errorDescription { return text }
        return (error as? APIError)?.userMessage ?? Format.string("network.error.generic")
    }

    /// O que o escritório oferece no app — aba de documentos, envio de arquivo.
    var capabilities: ProviderCapabilities { snapshot.capabilities }

    /// Conta de pessoa física (CPF). Troca os textos que falam em "empresa".
    var isPersonalAccount: Bool { company?.isPersonal ?? false }

    private func apply(_ snapshot: ClientSnapshot) {
        self.snapshot = snapshot
        index = PortfolioIndex(snapshot: snapshot)
        hasLoadedSnapshot = true
    }

    // MARK: - Derived views over the snapshot
    //
    // Everything below is read from `index`, which goes through `Rules` — so the
    // dashboard, the notification list and the documents screen can never
    // disagree about what is urgent, and none of them recomputes it per frame.

    var cases: [LegalCase] { snapshot.cases }
    var openCases: [LegalCase] { index.openCases }
    var closedCases: [LegalCase] { index.closedCases }
    var documents: [ClientDocument] { index.documents }
    var invoices: [Invoice] { snapshot.invoices }
    var nextInvoice: Invoice? { index.nextInvoice }
    var position: PortfolioPosition { index.position }
    var openPendencies: [Pendency] { index.openPendencies }
    var casesRequiringClient: [LegalCase] { index.casesRequiringClient }
    var documentsNeedingAttention: [ClientDocument] { index.documentsNeedingAttention }
    var contracts: [ClientDocument] { index.contracts }
    var informationalMovements: [MovementReference] { index.informationalMovements }

    func state(of legalCase: LegalCase) -> CaseState { index.state(of: legalCase) }
    func nextDeadline(for legalCase: LegalCase) -> Date? { index.nextDeadline(for: legalCase) }
    func contractAlert(for document: ClientDocument) -> ContractAlert? { index.contractAlert(for: document) }
    func legalCase(id: UUID?) -> LegalCase? { index.legalCase(id: id) }
    func document(id: UUID?) -> ClientDocument? { index.document(id: id) }

    /// Movements the client hasn't opened yet — everything that would have been
    /// a push, minus what they already read.
    var unreadCount: Int { index.unreadCount(excluding: readMovementIDs) }

    // MARK: - WhatsApp

    var firmPhone: String { BrandConfiguration.current.contact.whatsapp }

    func whatsAppURL(_ context: WhatsAppLink.Context, caseID: UUID? = nil) -> URL? {
        let repository = services.repository
        Task { await repository.recordWhatsAppHandoff(caseID: caseID) }
        return WhatsAppLink.url(
            phone: firmPhone,
            context: context,
            companyName: company?.tradeName ?? BrandConfiguration.current.displayName,
            isPersonal: isPersonalAccount
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
        SessionTokenStore.clearPersisted()
    }
}

// Sem `#if DEBUG` de propósito: o `#Preview` é compilado também em Release, e
// o archive quebrava com "AppState has no member 'signedInPreview'" em cada
// tela com prévia. Ninguém chama estas funções fora das prévias.
extension AppState {
    /// Preview convenience — a signed-in state with demo data, no Keychain writes.
    static func signedInPreview() -> AppState {
        let state = AppState(services: .demo())
        let dataset = DemoDataset.current
        state.company = dataset.company
        state.didFinishSplash = true
        state.hasSeenOnboarding = true
        state.didAskBiometrics = true
        state.apply(dataset.snapshot)
        return state
    }

    /// Preview do aviso de falha: dados de demonstração, última atualização falhou.
    static func failedRefreshPreview() -> AppState {
        let state = signedInPreview()
        state.loadFailed = true
        return state
    }
}
