import SwiftUI

struct AppListRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    var subtitle: String?
    var systemImage: String
    var iconTone: StatePill.Tone = .neutral
    var isMonoSubtitle = false
    var trailingPill: (text: String, tone: StatePill.Tone)?
    /// Só para linhas que levam a algum lugar. Chevron em linha que não
    /// responde ao toque é uma promessa que a tela não cumpre.
    var showsChevron = true

    var body: some View {
        // Em tamanho de acessibilidade o selo desce para baixo do texto, em vez
        // de disputar a largura com o título.
        let stacksPill = dynamicTypeSize.isAccessibilitySize

        HStack(spacing: 13) {
            RowIcon(systemImage: systemImage, tone: iconTone)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.font(15, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(isMonoSubtitle ? Theme.mono(12) : Theme.font(12.5))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let trailingPill, stacksPill {
                    StatePill(trailingPill.text, tone: trailingPill.tone)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let trailingPill {
                if !stacksPill {
                    StatePill(trailingPill.text, tone: trailingPill.tone)
                }
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.muted.opacity(0.55))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .frame(minHeight: Theme.minTouchTarget + 12)
        .contentShape(.rect)
    }
}
