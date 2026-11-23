import SwiftUI

/// Three benefits, one action. The illustrations are miniatures of the real
/// interface rather than generic art, so the client recognises the screens before
/// arriving at them.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pageCount = 3
    private var isLastPage: Bool { page == pageCount - 1 }
    private var advanceTitle: LocalizedStringKey { isLastPage ? "onb.enter" : "onb.continue" }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingPage(title: "onb.1.title", message: "onb.1.body") { TriageArt() }
                    .tag(0)
                OnboardingPage(title: "onb.2.title", message: "onb.2.body") { WhatsAppArt() }
                    .tag(1)
                OnboardingPage(title: "onb.3.title", message: "onb.3.body") { ContractsArt() }
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 7) {
                OnboardingPageIndicator(page: page, pageCount: pageCount)
                    .padding(.bottom, 12)

                Button(advanceTitle, action: advance)
                    .buttonStyle(PrimaryButtonStyle())

                Button("onb.skip", action: finish)
                    .buttonStyle(LinkButtonStyle())
                    .opacity(isLastPage ? 0 : 1)
                    .disabled(isLastPage)
                    .accessibilityHidden(isLastPage)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 8)
        }
        .background(Theme.background)
    }

    private func advance() {
        if isLastPage {
            finish()
        } else {
            withAnimation(reduceMotion ? nil : .default) { page += 1 }
        }
    }

    private func finish() {
        appState.completeOnboarding()
    }
}

#Preview {
    OnboardingView().environment(AppState())
}
