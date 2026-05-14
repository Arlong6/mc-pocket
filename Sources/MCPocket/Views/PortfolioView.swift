import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                if let err = store.lastError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    ForEach(store.projects) { project in
                        NavigationLink {
                            ChatView(project: project)
                        } label: {
                            ProjectRow(project: project)
                        }
                    }
                } header: {
                    Text("\(store.projects.count) projects")
                }
            }
            .navigationTitle("Portfolio")
            .refreshable { await store.refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            StatusDot(status: project.status)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(project.name).font(.headline)
                    if project.unreadCount > 0 {
                        Text("\(project.unreadCount)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.red, in: .capsule)
                            .foregroundStyle(.white)
                    }
                }
                HStack(spacing: 8) {
                    Text(project.status.label)
                        .font(.caption)
                        .foregroundStyle(project.status.color)
                    Text("·")
                    Text(project.lastActivity, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if project.dirtyGitFiles > 0 || project.openTodos > 0 {
                    HStack(spacing: 10) {
                        if project.dirtyGitFiles > 0 {
                            Label("\(project.dirtyGitFiles)", systemImage: "circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        if project.openTodos > 0 {
                            Label("\(project.openTodos)", systemImage: "checklist")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StatusDot: View {
    let status: Project.Status
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
    }
}

private extension Project.Status {
    var label: String {
        switch self {
        case .idle: "idle"
        case .running: "running"
        case .waitingForInput: "waiting"
        case .error: "error"
        }
    }
    var color: Color {
        switch self {
        case .idle: .secondary
        case .running: .green
        case .waitingForInput: .yellow
        case .error: .red
        }
    }
}

#Preview {
    PortfolioView().environmentObject(AppStore())
}
