import SwiftUI
import UIKit

@main
struct MCPocketApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    /// `mcpocket://pair?...`        → bounce to SettingsView, prefill pairing
    /// `mcpocket://project/<id>`    → switch Portfolio tab to that project's chat
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "mcpocket" else { return }
        switch url.host {
        case "pair":
            Task { try? await store.pair(withURL: url.absoluteString) }
        case "project":
            let projectId = url.lastPathComponent
            store.deepLinkProjectId = projectId
        default:
            break
        }
    }
}

/// Top-level app state. Wraps the paired server (if any) and the most recent
/// fetched project snapshot. Auto-refreshes every 8 seconds when paired so the
/// portfolio view feels live without each tab having to schedule its own poll.
@MainActor
final class AppStore: ObservableObject {
    @Published var pairing: PairedServer?
    @Published var projects: [Project] = []
    @Published var isUsingMockData: Bool = true
    @Published var lastError: String?
    @Published var isRefreshing: Bool = false
    @Published var deviceToken: String?
    @Published var deepLinkProjectId: String?

    private var pollTask: Task<Void, Never>?

    init() {
        self.pairing = PairedServer.loadFromKeychain()
        self.projects = Project.previewSet
        self.isUsingMockData = (pairing == nil)
        installPushHooks()
        if pairing != nil {
            startPolling()
            Task { await refresh() }
        }
    }

    // MARK: - Push hooks (called from AppDelegate)

    private func installPushHooks() {
        AppDelegate.onTokenReceived = { [weak self] hex in
            Task { @MainActor [weak self] in
                self?.deviceToken = hex
                await self?.registerDeviceTokenIfPaired()
            }
        }
        AppDelegate.onPushReceived = { [weak self] userInfo in
            // Pull only Sendable scalars out on the calling thread; the dict
            // itself ([AnyHashable: Any]) isn't Sendable and can't cross
            // actor boundaries under Swift 6 strict concurrency.
            let projectId = userInfo["projectId"] as? String
            let kind = (userInfo["kind"] as? String) ?? "waitingForInput"
            Task { @MainActor [weak self] in
                self?.handlePush(projectId: projectId, kind: kind)
            }
        }
    }

    private func registerDeviceTokenIfPaired() async {
        guard let pairing, let deviceToken else { return }
        let nickname = UIDevice.current.name
        do {
            try await MissionControlClient(server: pairing)
                .register(deviceToken: deviceToken, nickname: nickname)
        } catch {
            self.lastError = "Couldn't register device with Mac: \(error.localizedDescription)"
        }
    }

    private func handlePush(projectId: String?, kind: String) {
        guard let projectId else { return }
        // Start (or update) a Live Activity for waiting-state pushes only —
        // completed/error are surfaced as plain banners.
        if kind == "waitingForInput",
           let project = projects.first(where: { $0.id == projectId }) {
            Task { await LiveActivityController.shared.start(project: project, preview: nil) }
        } else if kind == "completed" || kind == "error" {
            Task { await LiveActivityController.shared.end(projectId: projectId) }
        }
        deepLinkProjectId = projectId
    }

    // MARK: - Pairing

    /// Decode + save + verify in one shot. Throws if any step fails so the UI
    /// can show a precise error.
    func pair(withURL urlString: String) async throws {
        guard let server = PairedServer.parse(pairingURL: urlString) else {
            throw NSError(domain: "MCPocket.Pair", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "QR is not a valid mcpocket pairing URL."])
        }
        let client = MissionControlClient(server: server)
        let ok = (try? await client.ping()) ?? false
        if !ok {
            throw NSError(domain: "MCPocket.Pair", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Could not reach \(server.host):\(server.port). Make sure the Mac is on the same network or Tailscale tailnet."])
        }
        try server.saveToKeychain()
        self.pairing = server
        self.isUsingMockData = false
        startPolling()
        await refresh()
        // If we already had an APNs token before pairing, register it now.
        await registerDeviceTokenIfPaired()
    }

    func unpair() {
        pollTask?.cancel()
        pollTask = nil
        PairedServer.removeFromKeychain()
        self.pairing = nil
        self.projects = Project.previewSet
        self.isUsingMockData = true
        self.lastError = nil
        Task { await LiveActivityController.shared.endAll() }
    }

    // MARK: - Data flow

    func refresh() async {
        guard let pairing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let client = MissionControlClient(server: pairing)
            self.projects = try await client.fetchProjects()
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                await self?.refresh()
            }
        }
    }
}
