import SwiftUI

/// Uma linha que abre algo fora do app. Some quando a URL não se forma —
/// linha morta em tela de contato é pior do que ausência.
struct ContactLinkRow: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let value: String
    let systemImage: String
    let url: URL?
    /// O divisor acompanha a linha: se ela some, ele some junto.
    let showsDivider: Bool

    var body: some View {
        if let url {
            VStack(spacing: 0) {
                if showsDivider { RowDivider() }
                Button {
                    openURL(url)
                } label: {
                    AppListRow(
                        title: title,
                        subtitle: value,
                        systemImage: systemImage,
                        isMonoSubtitle: true
                    )
                }
                .buttonStyle(RowPressStyle())
            }
        }
    }
}
