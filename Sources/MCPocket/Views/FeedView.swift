import SwiftUI

/// Cross-project feed: every recent push notification + waiting prompt across
/// all paired projects. The "what needs me right now" view.
struct FeedView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                let waiting = store.projects.filter { $0.status == .waitingForInput }
                if !waiting.isEmpty {
                    Section("Waiting on you") {
                        ForEach(waiting) { project in
                            NavigationLink {
                                ChatView(project: project)
                            } label: {
                                FeedRow(project: project, kind: .waiting)
                            }
                        }
                    }
                }

                let errored = store.projects.filter { $0.hasError }
                if !errored.isEmpty {
                    Section("Errors") {
                        ForEach(errored) { project in
                            NavigationLink {
                                ChatView(project: project)
                            } label: {
                                FeedRow(project: project, kind: .error)
                            }
                        }
                    }
                }

                if waiting.isEmpty && errored.isEmpty {
                    ContentUnavailableView(
                        "All clear",
                        systemImage: "checkmark.seal",
                        description: Text("Nothing needs your attention right now.")
                    )
                }
            }
            .navigationTitle("Feed")
        }
    }
}

private struct FeedRow: View {
    let project: Project
    let kind: Kind

    enum Kind { case waiting, error }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind == .waiting ? "hand.raised.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(kind == .waiting ? .yellow : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name).font(.headline)
                Text(project.lastActivity, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    FeedView().environmentObject(AppStore())
}
