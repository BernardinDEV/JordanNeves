import SwiftUI

/// Cinco abas. O canal de conversa dentro do app continua fora de escopo: a aba
/// Contato reúne os caminhos para falar com o escritório — WhatsApp, telefone,
/// e-mail e endereço — e as saídas para o WhatsApp seguem existindo nas telas
/// onde a dúvida realmente aparece, com o contexto do processo junto.
struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: MainTab
    @State private var askBiometrics = false

    init(initialTab: MainTab = .home) {
        _selection = State(initialValue: initialTab)
    }

    var body: some View {
        // `tabItem` de propósito: a API `Tab` exige iOS 18 e o app parte do 17.
        TabView(selection: $selection) {
            HomeView(selectedTab: $selection)
                .tabItem { Label("tab.home", systemImage: "house") }
                .tag(MainTab.home)

            CasesListView()
                .tabItem { Label("tab.cases", systemImage: "text.document") }
                .tag(MainTab.cases)

            // Escritório cujo provedor não guarda documentos: a aba não existe.
            if appState.capabilities.documents {
                DocumentsView()
                    .tabItem { Label("tab.documents", systemImage: "folder") }
                    .tag(MainTab.documents)
            }

            ContactView()
                .tabItem { Label("tab.contact", systemImage: "bubble.left.and.text.bubble.right") }
                .tag(MainTab.contact)

            ProfileView()
                .tabItem { Label("tab.profile", systemImage: "person") }
                .tag(MainTab.profile)
        }
        .tint(Theme.primary)
        .task { await loadAndOfferBiometrics() }
        .onChange(of: appState.didAskBiometrics) { _, asked in
            if asked { askBiometrics = false }
        }
        .fullScreenCover(isPresented: $askBiometrics) {
            BiometricOptInStep()
        }
    }

    private func loadAndOfferBiometrics() async {
        await appState.refresh()
        // O convite ao Face ID mora aqui, e não no fim do login: assim que o
        // código é aceito a sessão existe e a árvore do login sai da tela,
        // então um passo a mais lá dentro nunca chegaria a aparecer.
        askBiometrics = appState.canUseBiometrics && !appState.didAskBiometrics
    }
}

#Preview {
    MainTabView().environment(AppState.signedInPreview())
}
