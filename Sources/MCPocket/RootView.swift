import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView {
            PortfolioView()
                .tabItem { Label("Portfolio", systemImage: "square.grid.2x2") }

            // Chat is reached via NavigationLink from Portfolio; this tab is a
            // standalone "all recent messages" feed for quick triage.
            FeedView()
                .tabItem { Label("Feed", systemImage: "bubble.left.and.bubble.right") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task { await store.refresh() }
    }
}

#Preview {
    RootView().environmentObject(AppStore())
}
