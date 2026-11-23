import SwiftUI

/// Ilustração da página 2: a mensagem que o app já leva pronta para o WhatsApp.
struct WhatsAppArt: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("onb.art.waMessage")
                .font(Theme.font(14))
                .foregroundStyle(Theme.onBrand)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Theme.primary, in: .rect(cornerRadius: 15))
                .frame(maxWidth: 250, alignment: .trailing)

            Label("onb.art.waPrefilled", systemImage: "bubble.left.and.text.bubble.right")
                .font(Theme.font(12))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(22)
    }
}
