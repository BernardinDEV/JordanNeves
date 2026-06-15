import SwiftUI

@main
struct JordanNevesApp: App {
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

                // Hides sensitive case data in the app switcher while backgrounded.
                if showPrivacyScreen { privacyOverlay }

                // Biometric gate after returning to the foreground.
                if isLocked { lockedOverlay }

                // Blocking screen instead of exit(0) — programmatic termination
                // is rejected by App Review and reads as a crash to the user.
                if isCompromisedDevice { tamperOverlay }
            }
            .environment(\.locale, appState.language.locale)
            // Cold launch: onChange(scenePhase) does not fire for the initial
            // .active value, so run the checks once here too.
            .task { runSecurityChecks() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                withAnimation(.easeOut(duration: 0.2)) { showPrivacyScreen = false }
                if didEnterBackground {
                    didEnterBackground = false
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
    }

    /// Runs tamper detection and the biometric gate. Locks the UI synchronously
    /// before the (async) biometric prompt resolves so sensitive content never
    /// flashes underneath it.
    private func runSecurityChecks() {
        if appState.isLoggedIn, appState.biometricEnabled, appState.canUseBiometrics {
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
            let unlocked = await appState.evaluateBiometricLock()
            withAnimation { isLocked = !unlocked }
        }
    }

    // MARK: - Overlays

    private var privacyOverlay: some View {
        Theme.background
            .ignoresSafeArea()
            .overlay(
                Image("LogoVertical")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180)
                    .opacity(0.5)
            )
    }

    private var lockedOverlay: some View {
        Theme.background
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.primary)
                    Button("lock.unlock") {
                        Task {
                            let unlocked = await appState.evaluateBiometricLock()
                            withAnimation { isLocked = !unlocked }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: 220)
                }
                .padding(32)
            )
    }

    private var tamperOverlay: some View {
        Theme.background
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    Text("tamper.title")
                        .font(Theme.font(20, weight: .bold))
                        .foregroundStyle(Theme.primary)
                    Text("tamper.message")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
            )
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isLoggedIn {
            MainTabView()
                .transition(.opacity)
        } else {
            LoginView()
                .transition(.opacity)
        }
    }
}
