import SwiftUI

/// O arquivo escolhido, com a barra de progresso enquanto é enviado.
struct PickedFileRow: View {
    let fileName: String
    /// `nil` enquanto o envio não começou.
    let progress: Double?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 17))
                .foregroundStyle(Theme.primary)
                .frame(width: 38, height: 38)
                .background(Theme.card, in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(fileName)
                    .font(Theme.font(14, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let progress {
                    ProgressView(value: progress)
                        .tint(Theme.primary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.fill, in: .rect(cornerRadius: Theme.Radius.control))
    }
}
