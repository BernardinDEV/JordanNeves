import SwiftUI

/// The only way out of the app to the firm. Rendered as a secondary action
/// everywhere it appears, and it always carries context in the message it opens.
struct WhatsAppButton: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    let context: WhatsAppLink.Context
    var caseID: UUID?
    var titleKey: LocalizedStringKey = "wa.button"

    var body: some View {
        Button(action: open) {
            Label {
                Text(titleKey)
            } icon: {
                Image(systemName: "bubble.left.and.text.bubble.right")
            }
        }
        .buttonStyle(WhatsAppButtonStyle())
    }

    private func open() {
        if let url = appState.whatsAppURL(context, caseID: caseID) { openURL(url) }
    }
}
