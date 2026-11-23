import SwiftUI

/// Brief brand moment on cold launch. No marketing copy: everyone who opens this
/// app is already a client of the firm.
struct SplashView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.primary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                BrandMark(tint: Theme.onBrand)
                    .frame(width: 88, height: 88)
                    // Com "Reduzir movimento" ligado a marca só surge, sem crescer.
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.82)
                    .opacity(appeared ? 1 : 0)

                Text(BrandConfiguration.current.legalName.uppercased())
                    .font(Theme.font(19, weight: .bold))
                    .kerning(3.5)
                    .foregroundStyle(Theme.onBrand)
                    .multilineTextAlignment(.center)
                    .padding(.top, 26)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                Text(BrandConfiguration.current.tagline.resolved())
                    .font(Theme.font(11.5))
                    .kerning(0.6)
                    .foregroundStyle(Theme.onBrand.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 46)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 32)
        }
        .task { await runBrandMoment() }
    }

    private func runBrandMoment() async {
        withAnimation(.easeOut(duration: 0.55)) { appeared = true }
        try? await Task.sleep(for: .milliseconds(1100))
        withAnimation(.easeInOut(duration: 0.25)) { appState.finishSplash() }
    }
}

#Preview {
    SplashView().environment(AppState())
}
