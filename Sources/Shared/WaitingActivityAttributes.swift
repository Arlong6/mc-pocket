import Foundation
import ActivityKit

/// Live Activity payload for a "Claude is waiting on you" prompt. Shared
/// verbatim between the main app (start/update/end) and the widget extension
/// (render). Keep keys aligned with API.md push payloads so the Mac side can
/// drive these via remote push too.
public struct WaitingActivityAttributes: ActivityAttributes, Sendable {
    public typealias ContentState = ContentStateValue

    public let projectId: String
    public let projectName: String
    public let sessionId: String?

    public init(projectId: String, projectName: String, sessionId: String?) {
        self.projectId = projectId
        self.projectName = projectName
        self.sessionId = sessionId
    }

    public struct ContentStateValue: Codable, Hashable, Sendable {
        public let status: Kind
        public let waitingSince: Date
        public let preview: String?      // first line of the prompt, optional

        public init(status: Kind, waitingSince: Date, preview: String?) {
            self.status = status
            self.waitingSince = waitingSince
            self.preview = preview
        }

        public enum Kind: String, Codable, Hashable, Sendable {
            case waitingForInput
            case running
            case completed
            case error
        }
    }
}
