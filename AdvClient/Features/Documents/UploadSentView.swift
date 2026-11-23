import SwiftUI

/// Confirmação do envio. Diz o que vem a seguir, nunca só "pronto": o
/// escritório foi avisado e o arquivo já está em Documentos.
struct UploadSentView: View {
    let fileName: String
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ConfirmationMark()
                    .padding(.top, 28)

                Text("upload.sent.title")
                    .font(Theme.font(24, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .accessibilityAddTraits(.isHeader)

                Text(verbatim: fileName)
                    .font(Theme.mono(12.5))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.top, 6)

                Text("upload.sent.body")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .sideMargin()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            Button("common.done", action: onClose)
                .buttonStyle(SecondaryButtonStyle())
                .sideMargin()
                .padding(.vertical, 12)
                .background(Theme.background)
        }
    }
}
