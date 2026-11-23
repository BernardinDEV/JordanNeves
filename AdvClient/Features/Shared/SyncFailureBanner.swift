import SwiftUI

/// Aviso de que a última atualização falhou, no topo das listas.
///
/// `AppState.loadFailed` existia e nenhuma tela o lia: sem rede, o app mostrava
/// os dados antigos como se fossem de agora — ou uma tela vazia sem explicação.
/// O aviso diz o que aconteceu, de quando é o que está na tela, e oferece a
/// única ação possível.
struct SyncFailureBanner: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.loadFailed {
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text(message)
                        .font(Theme.font(13.5))
                        .foregroundStyle(Theme.body)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "wifi.exclamationmark")
                        .foregroundStyle(Theme.attention)
                }

                Button("common.tryAgain", action: retry)
                    .buttonStyle(LinkButtonStyle(compact: true))
                    .disabled(appState.isLoading)
            }
            .card(accent: Theme.attention)
            .sideMargin()
            .padding(.bottom, 14)
        }
    }

    private var message: String {
        let lastSync = appState.snapshot.lastSyncedAt
        if lastSync == .distantPast {
            return Format.string("network.error.generic")
        }
        return Format.string("sync.failed.showingDataFrom \(Format.dateTime(lastSync))")
    }

    private func retry() {
        Task { await appState.refresh() }
    }
}

#Preview {
    SyncFailureBanner()
        .environment(AppState.failedRefreshPreview())
}
