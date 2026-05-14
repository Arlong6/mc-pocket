import Foundation

/// Mirrors the JSON shape returned by `GET /projects` on the Mac side.
/// Keep field names in sync with API.md.
struct Project: Identifiable, Codable, Hashable {
    let id: String          // claude project slug, e.g. "-Users-arlong-Projects-AIvideo"
    let name: String        // last path component, e.g. "AIvideo"
    let cwd: String         // resolved working directory on Mac
    let status: Status
    let lastActivity: Date
    let unreadCount: Int
    let dirtyGitFiles: Int
    let openTodos: Int
    let hasError: Bool

    enum Status: String, Codable {
        case idle
        case running          // claude is actively producing output
        case waitingForInput  // permission prompt or assistant turn waiting
        case error
    }
}

extension Project {
    static let previewSet: [Project] = [
        .init(id: "-Users-arlong-Projects-AIvideo",
              name: "AIvideo",
              cwd: "/Users/arlong/Projects/AIvideo",
              status: .running,
              lastActivity: Date().addingTimeInterval(-30),
              unreadCount: 0, dirtyGitFiles: 3, openTodos: 2, hasError: false),
        .init(id: "-Users-arlong-Projects-claude-mission-control",
              name: "claude-mission-control",
              cwd: "/Users/arlong/Projects/claude-mission-control",
              status: .waitingForInput,
              lastActivity: Date().addingTimeInterval(-180),
              unreadCount: 1, dirtyGitFiles: 0, openTodos: 5, hasError: false),
        .init(id: "-Users-arlong-Projects-CarFinder",
              name: "CarFinder",
              cwd: "/Users/arlong/Projects/CarFinder",
              status: .error,
              lastActivity: Date().addingTimeInterval(-3600),
              unreadCount: 0, dirtyGitFiles: 1, openTodos: 0, hasError: true),
        .init(id: "-Users-arlong-Projects-upwork-watcher",
              name: "upwork-watcher",
              cwd: "/Users/arlong/Projects/upwork-watcher",
              status: .idle,
              lastActivity: Date().addingTimeInterval(-7200),
              unreadCount: 0, dirtyGitFiles: 0, openTodos: 1, hasError: false),
    ]
}
