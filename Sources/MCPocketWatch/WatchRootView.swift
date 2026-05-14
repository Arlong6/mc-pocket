import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject private var store: WatchStore

    var body: some View {
        NavigationStack {
            if store.pairing == nil {
                unpairedView
            } else {
                pairedView
            }
        }
    }

    private var unpairedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone")
                .font(.system(size: 36))
                .foregroundStyle(.tint)
            Text("Pair on iPhone first")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Open MC Pocket on your iPhone and scan the Mac's QR code.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var pairedView: some View {
        List {
            if let err = store.lastError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption2)
            }

            let waiting = store.projects.filter { $0.status == .waitingForInput }
            let errored = store.projects.filter { $0.hasError }

            if !waiting.isEmpty {
                Section("Waiting (\(waiting.count))") {
                    ForEach(waiting) { project in
                        NavigationLink {
                            WatchProjectActions(project: project)
                        } label: {
                            WatchProjectRow(project: project, accent: .yellow)
                        }
                    }
                }
            }

            if !errored.isEmpty {
                Section("Errors (\(errored.count))") {
                    ForEach(errored) { project in
                        NavigationLink {
                            WatchProjectActions(project: project)
                        } label: {
                            WatchProjectRow(project: project, accent: .red)
                        }
                    }
                }
            }

            if waiting.isEmpty && errored.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                    Text("All clear")
                        .font(.headline)
                    Text("\(store.projects.count) projects idle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("MC Pocket")
        .refreshable { await store.refresh() }
        .task { await store.refresh() }
    }
}

private struct WatchProjectRow: View {
    let project: Project
    let accent: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(accent).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name).font(.headline).lineLimit(1)
                Text(project.lastActivity, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WatchProjectActions: View {
    let project: Project
    @EnvironmentObject private var store: WatchStore
    @State private var sending = false
    @State private var lastResult: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(project.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await send("keep going") }
                } label: {
                    Label("Continue", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)

                Button {
                    Task { await send("stop here, summarise what you did") }
                } label: {
                    Label("Stop + summarise", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.orange)

                Button {
                    Task { await send("commit and push") }
                } label: {
                    Label("Commit + push", systemImage: "arrow.up.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)

                if let result = lastResult {
                    Text(result)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Action")
        .disabled(sending)
    }

    private func send(_ text: String) async {
        guard let pairing = store.pairing else { return }
        sending = true
        defer { sending = false }
        do {
            try await MissionControlClient(server: pairing).send(sessionId: project.id, text: text)
            lastResult = "Sent ✓"
        } catch {
            lastResult = "Failed: \(error.localizedDescription)"
        }
    }
}
