import SwiftUI

/// Three benefits, one action. The illustrations are miniatures of the real
/// interface rather than generic art, so the client recognises the screens before
/// arriving at them.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var page = 0

    private let pageCount = 3

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                page(index: 0, title: "onb.1.title", body: "onb.1.body") { TriageArt() }
                page(index: 1, title: "onb.2.title", body: "onb.2.body") { WhatsAppArt() }
                page(index: 2, title: "onb.3.title", body: "onb.3.body") { ContractsArt() }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 7) {
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Theme.primary : Theme.line)
                            .frame(width: index == page ? 20 : 6, height: 6)
                            .animation(.snappy(duration: 0.25), value: page)
                    }
                }
                .padding(.bottom, 12)
                .accessibilityHidden(true)

                Button(page == pageCount - 1 ? "onb.enter" : "onb.continue") {
                    if page == pageCount - 1 {
                        appState.completeOnboarding()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("onb.skip") { appState.completeOnboarding() }
                    .font(Theme.font(15, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .frame(minHeight: Theme.minTouchTarget)
                    .opacity(page == pageCount - 1 ? 0 : 1)
                    .disabled(page == pageCount - 1)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 8)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func page<Art: View>(
        index: Int,
        title: LocalizedStringKey,
        body: LocalizedStringKey,
        @ViewBuilder art: () -> Art
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            art()
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .background(Theme.fill, in: RoundedRectangle(cornerRadius: 18))

            Text(title)
                .font(Theme.font(28, weight: .bold))
                .foregroundStyle(Theme.primary)
                .padding(.top, 32)
                .fixedSize(horizontal: false, vertical: true)

            Text(body)
                .font(Theme.font(15.5))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 26)
        .padding(.top, 20)
        .tag(index)
    }
}

// MARK: - Illustrations

private struct TriageArt: View {
    var body: some View {
        VStack(spacing: 11) {
            miniCard(pill: "state.requiresYou", tone: .critical, title: "onb.art.case1", dim: false)
            miniCard(pill: "state.withCourt", tone: .neutral, title: "onb.art.case2", dim: true)
            miniCard(pill: "state.onTrack", tone: .onTrack, title: "onb.art.case3", dim: true)
        }
        .padding(22)
    }

    private func miniCard(pill: String.LocalizationValue, tone: StatePill.Tone, title: LocalizedStringKey, dim: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            StatePill(Format.string(pill), tone: tone)
            Text(title)
                .font(Theme.font(14, weight: .semibold))
                .foregroundStyle(Theme.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 11))
        .opacity(dim ? 0.42 : 1)
    }
}

private struct WhatsAppArt: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("onb.art.waMessage")
                .font(Theme.font(14))
                .foregroundStyle(Theme.onBrand)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Theme.primary, in: RoundedRectangle(cornerRadius: 15))
                .frame(maxWidth: 250, alignment: .trailing)

            Label {
                Text("onb.art.waPrefilled").font(Theme.font(12))
            } icon: {
                Image(systemName: "bubble.left.and.text.bubble.right").font(.system(size: 12))
            }
            .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(22)
    }
}

private struct ContractsArt: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.primary)
                .padding(.bottom, 12)

            row("onb.art.contracts", value: "18", tone: Theme.primary)
            row("onb.art.expiring", value: "3", tone: Theme.attention)
            row("onb.art.autoRenew", value: "2", tone: Theme.critical)
        }
        .padding(22)
    }

    private func row(_ label: LocalizedStringKey, value: String, tone: Color) -> some View {
        HStack {
            Text(label).font(Theme.font(13.5)).foregroundStyle(Theme.muted)
            Spacer()
            Text(value).font(Theme.mono(16, weight: .semibold)).foregroundStyle(tone)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1) }
    }
}

#Preview {
    OnboardingView().environment(AppState())
}
