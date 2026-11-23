import SwiftUI

@main
struct AdvClientApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    @State private var showPrivacyScreen = false
    @State private var isLocked = false
    @State private var isCompromisedDevice = false

    // Tracks whether the app actually went to the background since it was last
    // active. The biometric prompt itself bounces the scene through .inactive,
    // so gating re-checks on a real background round-trip avoids re-prompting
    // right after a successful unlock (and re-locking on a Control Center pull).
    @State private var didEnterBackground = false

    init() {
        Theme.registerBundledFonts()
        Theme.applyNavigationBarAppearance()
    }

    /// Algo cobre o conteúdo: tela de privacidade, bloqueio ou aparelho comprometido.
    private var isObscured: Bool {
        showPrivacyScreen || isLocked || isCompromisedDevice
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(appState)
                    .tint(Theme.primary)
                    // The design uses fixed light surfaces (white cards on light gray);
                    // lock light appearance until a dark palette is designed.
                    .preferredColorScheme(.light)
                    // Coberto para os olhos tem que estar coberto para o
                    // VoiceOver: sem isto ele lia os processos por baixo da
                    // tela de bloqueio.
                    .accessibilityHidden(isObscured)

                // Hides sensitive case data in the app switcher while backgrounded.
                if showPrivacyScreen { PrivacyOverlay() }

                // Biometric gate after returning to the foreground.
                if isLocked { LockedOverlay(unlock: unlock) }

                // Blocking screen instead of exit(0) — programmatic termination
                // is rejected by App Review and reads as a crash to the user.
                if isCompromisedDevice { TamperOverlay() }
            }
            .environment(\.locale, appState.language.locale)
            // Cold launch: onChange(scenePhase) does not fire for the initial
            // .active value, so run the checks once here too.
            .task { runSecurityChecks() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            scenePhaseChanged(to: newPhase)
        }
    }

    private func scenePhaseChanged(to phase: ScenePhase) {
        switch phase {
        case .active:
            withAnimation(.easeOut(duration: 0.2)) { showPrivacyScreen = false }
            if didEnterBackground {
                didEnterBackground = false
                // Prazos e contagens dependem do dia: quem volta depois da
                // meia-noite não pode ver "em 3 dias" de ontem.
                appState.didReturnToForeground()
                runSecurityChecks()
            }
        case .background:
            didEnterBackground = true
            withAnimation(.easeIn(duration: 0.15)) { showPrivacyScreen = true }
        case .inactive:
            withAnimation(.easeIn(duration: 0.15)) { showPrivacyScreen = true }
        @unknown default:
            break
        }
    }

    /// Runs tamper detection and the biometric gate. Locks the UI synchronously
    /// before the (async) biometric prompt resolves so sensitive content never
    /// flashes underneath it.
    private func runSecurityChecks() {
        if appState.isSignedIn, appState.biometricEnabled, appState.canUseBiometrics {
            isLocked = true
        }
        Task {
            // Detached: the probe does synchronous file I/O and must
            // not run on the main actor.
            let compromised = await Task.detached(priority: .utility) {
                TamperDetection.isCompromised()
            }.value
            if compromised {
                isCompromisedDevice = true
                return
            }
            await evaluateLock()
        }
    }

    private func unlock() {
        Task { await evaluateLock() }
    }

    private func evaluateLock() async {
        let unlocked = await appState.evaluateBiometricLock()
        withAnimation { isLocked = !unlocked }
    }
}
