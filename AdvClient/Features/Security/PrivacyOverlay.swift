import SwiftUI

/// Cobre os dados dos processos no seletor de apps, enquanto o app está em
/// segundo plano.
struct PrivacyOverlay: View {
    var body: some View {
        Theme.background
            .ignoresSafeArea()
            .overlay {
                Image("LogoVertical")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180)
                    .opacity(0.5)
                    .accessibilityHidden(true)
            }
    }
}
