import SwiftUI

/// A tela de cada fase do lançamento.
struct LaunchFlow: View {
    let phase: LaunchPhase

    var body: some View {
        switch phase {
        case .splash:
            SplashView().transition(.opacity)
        case .onboarding:
            OnboardingView().transition(.opacity)
        case .signIn:
            SignInFlow().transition(.opacity)
        case .ready:
            MainTabView().transition(.opacity)
        }
    }
}
