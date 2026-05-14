import SwiftUI

struct NotificationRulesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var rules: NotificationRules = NotificationRules.loadLocal()
    @State private var newKeyword: String = ""
    @State private var saveStatus: SaveStatus = .clean

    enum SaveStatus: Equatable {
        case clean, dirty, saving, saved(Date), failed(String)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable push notifications", isOn: binding(\.globalEnabled))
            } footer: {
                Text("When off, the Mac stays silent regardless of every other rule below.")
                    .font(.caption)
            }

            quietHoursSection

            Section("Per project") {
                if store.projects.isEmpty {
                    Text("No projects yet — pair with a Mac first.")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.projects) { project in
                    perProjectRow(for: project)
                }
            }

            Section {
                ForEach(rules.keywords) { rule in
                    keywordRow(rule)
                }
                .onDelete { idx in
                    rules.keywords.remove(atOffsets: idx)
                    markDirty()
                }

                HStack {
                    TextField("Add keyword…", text: $newKeyword)
                    Button("Add") { addKeyword(.alwaysPush) }
                        .disabled(newKeyword.isEmpty)
                    Button("Mute") { addKeyword(.suppress) }
                        .disabled(newKeyword.isEmpty)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Keyword overrides")
            } footer: {
                Text("Substrings checked against the push body. `Add` = always push (bypass quiet hours). `Mute` = never push even if other rules allow.")
                    .font(.caption)
            }

            Section {
                statusFooter
                Button("Save and send to Mac") { Task { await save() } }
                    .disabled(saveStatus == .clean || saveStatus == .saving)
            }
        }
        .navigationTitle("Notifications")
    }

    // MARK: - Sections

    private var quietHoursSection: some View {
        Section("Quiet hours") {
            Toggle("Enable quiet hours", isOn: Binding(
                get: { rules.quietHours != nil },
                set: { on in
                    if on {
                        rules.quietHours = .init(
                            startMinute: 23 * 60,   // 23:00
                            endMinute: 8 * 60,      // 08:00
                            timeZoneIdentifier: TimeZone.current.identifier
                        )
                    } else {
                        rules.quietHours = nil
                    }
                    markDirty()
                }
            ))

            if let q = rules.quietHours {
                DatePicker("Starts", selection: Binding(
                    get: { dateFor(minute: q.startMinute) },
                    set: { rules.quietHours?.startMinute = minutesFrom($0); markDirty() }
                ), displayedComponents: .hourAndMinute)

                DatePicker("Ends", selection: Binding(
                    get: { dateFor(minute: q.endMinute) },
                    set: { rules.quietHours?.endMinute = minutesFrom($0); markDirty() }
                ), displayedComponents: .hourAndMinute)

                LabeledContent("Time zone", value: q.timeZoneIdentifier)
                    .font(.caption)
            }
        }
    }

    private func perProjectRow(for project: Project) -> some View {
        let level = rules.perProject[project.id]?.level ?? .importantOnly
        return Picker(project.name, selection: Binding(
            get: { level },
            set: { newLevel in
                rules.perProject[project.id] = .init(level: newLevel)
                markDirty()
            }
        )) {
            ForEach(NotificationRules.ProjectRule.Level.allCases, id: \.self) { lvl in
                Text(lvl.localizedLabel).tag(lvl)
            }
        }
    }

    private func keywordRow(_ rule: NotificationRules.KeywordRule) -> some View {
        HStack {
            Image(systemName: rule.action == .alwaysPush ? "bell.badge.fill" : "bell.slash.fill")
                .foregroundStyle(rule.action == .alwaysPush ? .green : .red)
            Text(rule.pattern)
                .font(.body.monospaced())
            Spacer()
            Text(rule.action == .alwaysPush ? "always" : "mute")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusFooter: some View {
        Group {
            switch saveStatus {
            case .clean: Text("Saved.").foregroundStyle(.secondary)
            case .dirty: Text("Unsaved changes.").foregroundStyle(.orange)
            case .saving: HStack { ProgressView(); Text("Syncing to Mac…") }
            case .saved(let when):
                Text("Synced \(when.formatted(.relative(presentation: .numeric))).")
                    .foregroundStyle(.secondary)
            case .failed(let err):
                Text("Sync failed: \(err)").foregroundStyle(.red)
            }
        }
        .font(.caption)
    }

    // MARK: - Helpers

    private func binding<T: Equatable>(_ keyPath: WritableKeyPath<NotificationRules, T>) -> Binding<T> {
        Binding(
            get: { rules[keyPath: keyPath] },
            set: { rules[keyPath: keyPath] = $0; markDirty() }
        )
    }

    private func markDirty() {
        saveStatus = .dirty
        rules.saveLocal()
    }

    private func addKeyword(_ action: NotificationRules.KeywordRule.Action) {
        let trimmed = newKeyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        rules.keywords.append(.init(pattern: trimmed, action: action))
        newKeyword = ""
        markDirty()
    }

    private func save() async {
        saveStatus = .saving
        rules.saveLocal()
        do {
            if let pairing = store.pairing {
                try await MissionControlClient(server: pairing).updateRules(rules)
            }
            saveStatus = .saved(Date())
        } catch {
            saveStatus = .failed(error.localizedDescription)
        }
    }

    private func dateFor(minute: Int) -> Date {
        let cal = Calendar(identifier: .gregorian)
        return cal.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date()
    }

    private func minutesFrom(_ date: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

// MARK: - Local persistence

extension NotificationRules {
    private static let storageKey = "mc.pocket.notificationRules.v1"

    static func loadLocal() -> NotificationRules {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(NotificationRules.self, from: data)
        else { return .default }
        return decoded
    }

    func saveLocal() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationRulesView().environmentObject(AppStore())
    }
}
