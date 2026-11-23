import SwiftUI

/// Launch sequence: brand moment → three benefits → passwordless sign-in → app.
/// Each step is skipped once it has been passed, so a returning client with a
/// stored session goes straight to the dashboard.
struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            #if DEBUG
            if let route = DemoRoute.current {
                DemoRouteView(route: route)
            } else {
                LaunchFlow(phase: appState.phase)
            }
            #else
            LaunchFlow(phase: appState.phase)
            #endif
        }
        .animation(.easeInOut(duration: 0.25), value: appState.phase)
    }
}
