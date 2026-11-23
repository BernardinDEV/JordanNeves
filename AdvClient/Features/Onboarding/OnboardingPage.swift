import SwiftUI

/// Uma página do onboarding: ilustração, título e texto. Rola quando não cabe
/// — tela pequena ou letra grande — em vez de cortar o texto.
struct OnboardingPage<Art: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder var art: Art

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                art
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .background(Theme.fill, in: .rect(cornerRadius: 18))
                    .accessibilityHidden(true)

                Text(title)
                    .font(Theme.font(28, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 32)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(Theme.font(15.5))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 26)
            .padding(.top, 20)
            .padding(.bottom, 12)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}
