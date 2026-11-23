import SwiftUI

/// A área tracejada que abre o seletor de arquivos.
struct UploadDropZone: View {
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "arrow.up.doc")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.primary)
                .accessibilityHidden(true)
            Text("upload.choose")
                .font(Theme.font(15, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .padding(.top, 5)
            Text("upload.sources")
                .font(Theme.font(12.5))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Theme.line, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
        .contentShape(.rect)
    }
}
