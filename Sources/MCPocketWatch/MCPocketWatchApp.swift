import SwiftUI

@main
struct MCPocketWatchApp: App {
    @StateObject private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(store)
        }
    }
}

@MainActor
final class WatchStore: ObservableObject {
    @Published var pairing: PairedServer?
    @Published var projects: [Project] = []
    @Published var lastError: String?

    init() {
        // Watch reads its own keychain entry — pair separately on Watch for
        // v1.0. v1.1 will sync via WatchConnectivity from the iPhone.
        self.pairing = PairedServer.loadFromKeychain()
    }

    func refresh() async {
        guard let pairing else { return }
        do {
            let client = MissionControlClient(server: pairing)
            self.projects = try await client.fetchProjects()
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }
}
