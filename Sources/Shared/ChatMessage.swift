import Foundation

/// Single rendered chat message. The Mac server flattens Claude Code .jsonl
/// rows into this shape so the iOS client never has to parse the raw format.
struct ChatMessage: Identifiable, Codable, Hashable {
    let id: String
    let role: Role
    let text: String
    let timestamp: Date
    let isError: Bool

    enum Role: String, Codable {
        case user
        case assistant
        case tool
        case system
    }
}

extension ChatMessage {
    static let previewSet: [ChatMessage] = [
        .init(id: "1", role: .user, text: "fix the failing snapshot test", timestamp: Date().addingTimeInterval(-300), isError: false),
        .init(id: "2", role: .assistant, text: "Looking at the test fixture — the diff is whitespace-only. Updating the baseline.", timestamp: Date().addingTimeInterval(-280), isError: false),
        .init(id: "3", role: .tool, text: "Edit SnapshotTests.swift", timestamp: Date().addingTimeInterval(-270), isError: false),
        .init(id: "4", role: .assistant, text: "Done. Want me to run the test suite to confirm?", timestamp: Date().addingTimeInterval(-260), isError: false),
    ]
}
