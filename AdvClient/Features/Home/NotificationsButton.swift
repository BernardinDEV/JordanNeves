import SwiftUI

/// O sino do painel, na barra de navegação.
///
/// Era um botão desenhado à mão de 42 pt dentro do conteúdo. Como item de
/// barra ele ganha a área de toque, o material e a posição do sistema — e
/// continua visível quando a lista rola.
struct NotificationsButton: View {
    let unreadCount: Int
    let action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                // A barra do iOS 26 desenha o selo sozinha.
                Button("notifications.title", systemImage: "bell", action: action)
                    .badge(unreadCount)
            } else {
                // Antes do iOS 26 a barra só aproveita o rótulo do botão: o
                // selo precisa estar dentro dele, ou é descartado.
                Button(action: action) {
                    Image(systemName: "bell")
                        .overlay(alignment: .topTrailing) {
                            if unreadCount > 0 {
                                Text(unreadCount, format: .number)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .frame(minWidth: 17, minHeight: 17)
                                    .background(Theme.critical, in: .capsule)
                                    .offset(x: 9, y: -7)
                            }
                        }
                }
            }
        }
        .accessibilityLabel(Text("home.notifications.a11y \(unreadCount)"))
    }
}
