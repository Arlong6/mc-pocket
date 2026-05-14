import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showPairing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Paired Mac") {
                    if let p = store.pairing {
                        LabeledContent("Nickname", value: p.nickname)
                        LabeledContent("Host", value: "\(p.host):\(p.port)")
                        Button("Re-pair") {
                            showPairing = true
                        }
                        Button("Unpair", role: .destructive) {
                            store.unpair()
                        }
                    } else {
                        Button {
                            showPairing = true
                        } label: {
                            Label("Scan pairing QR", systemImage: "qrcode.viewfinder")
                        }
                        Text("Showing mock data until you pair with the Mission Control app on your Mac.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notifications") {
                    NavigationLink {
                        NotificationRulesView()
                    } label: {
                        Label("Quiet hours · per-project · keywords",
                              systemImage: "bell.badge")
                    }
                    LabeledContent("APNs token") {
                        Text(store.deviceToken?.prefix(12).description ?? "—")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Link("Mission Control on GitHub",
                         destination: URL(string: "https://github.com/Arlong6/claude-mission-control")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPairing) {
                PairingSheet().environmentObject(store)
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}

private struct PairingSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var status: PairStatus = .scanning
    @State private var manualURL: String = ""
    @State private var showManualEntry = false

    enum PairStatus: Equatable {
        case scanning
        case verifying(String)
        case failed(String)
        case succeeded
    }

    var body: some View {
        NavigationStack {
            ZStack {
                switch status {
                case .scanning:
                    QRScannerView(
                        onScan: { value in
                            Task { await attemptPair(with: value) }
                        },
                        onError: { error in
                            status = .failed(error.localizedDescription)
                        }
                    )
                    .ignoresSafeArea()

                    VStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("Scan the QR shown by Mission Control on your Mac")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Enter pairing URL manually") {
                                showManualEntry = true
                            }
                            .font(.caption)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                        .padding()
                    }

                case .verifying(let host):
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Connecting to \(host)…")
                    }

                case .failed(let message):
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        Text("Pairing failed")
                            .font(.headline)
                        Text(message)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        Button("Try again") { status = .scanning }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()

                case .succeeded:
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)
                        Text("Paired with \(store.pairing?.nickname ?? "Mac")")
                            .font(.headline)
                        Button("Done") { dismiss() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Pair Mac")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Paste pairing URL", isPresented: $showManualEntry) {
                TextField("mcpocket://pair?...", text: $manualURL)
                    .textInputAutocapitalization(.never)
                Button("Pair") {
                    Task { await attemptPair(with: manualURL) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Copy the URL printed below the QR code on Mission Control and paste it here.")
            }
        }
    }

    private func attemptPair(with rawURL: String) async {
        guard !rawURL.isEmpty else { return }
        let host = PairedServer.parse(pairingURL: rawURL).map { $0.host } ?? "Mac"
        status = .verifying(host)
        do {
            try await store.pair(withURL: rawURL)
            status = .succeeded
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    SettingsView().environmentObject(AppStore())
}
