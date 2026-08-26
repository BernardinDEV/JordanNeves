import SwiftUI

enum MainTab: Hashable {
    case home, cases, documents, profile
}

/// Four tabs. The conversation tab went out with the in-app channel — contact now
/// lives as a WhatsApp exit on the screens where a question actually comes up.
struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: MainTab = .home
    @State private var askBiometrics = false

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selectedTab: $selection)
                .tabItem { Label("tab.home", systemImage: "house") }
                .tag(MainTab.home)

            CasesListView()
                .tabItem { Label("tab.cases", systemImage: "text.document") }
                .tag(MainTab.cases)

            DocumentsView()
                .tabItem { Label("tab.documents", systemImage: "folder") }
                .tag(MainTab.documents)

            ProfileView()
                .tabItem { Label("tab.profile", systemImage: "person") }
                .tag(MainTab.profile)
        }
        .tint(Theme.primary)
        .task {
            await appState.refresh()
            // O convite ao Face ID mora aqui, e não no fim do login: assim que o
            // código é aceito a sessão existe e a árvore do login sai da tela,
            // então um passo a mais lá dentro nunca chegaria a aparecer.
            askBiometrics = appState.canUseBiometrics && !appState.didAskBiometrics
        }
        .onChange(of: appState.didAskBiometrics) { _, asked in
            if asked { askBiometrics = false }
        }
        .fullScreenCover(isPresented: $askBiometrics) {
            BiometricOptInStep()
        }
    }
}

#Preview {
    MainTabView().environment(AppState.signedInPreview())
}
