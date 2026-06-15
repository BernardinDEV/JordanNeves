import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("tab.home", systemImage: "folder.fill") }

            ContactView()
                .tabItem { Label("tab.contact", systemImage: "bubble.left.and.bubble.right.fill") }

            ProfileView()
                .tabItem { Label("tab.profile", systemImage: "person.crop.circle.fill") }
        }
    }
}
