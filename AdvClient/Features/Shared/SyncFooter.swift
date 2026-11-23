import SwiftUI

/// "Atualizado em …" no pé das listas. A data é mostrada ao cliente
/// literalmente — o app nunca sugere que o dado é mais novo do que é.
struct SyncFooter: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.snapshot.lastSyncedAt != .distantPast {
            Text("home.lastSync \(Format.dateTime(appState.snapshot.lastSyncedAt))")
                .font(Theme.font(12))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .sideMargin()
                .padding(.top, 24)
        }
    }
}
