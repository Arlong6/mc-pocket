import Foundation

/// Per-project + global rules describing when the Mac should push, and when
/// it should stay silent. Shared between iOS (edits + sends) and Mac (receives
/// + applies before sending APNs). Codable JSON so it travels over /rules.
public struct NotificationRules: Codable, Sendable, Equatable {
    public var globalEnabled: Bool
    public var quietHours: QuietHours?
    /// Project-id keyed. Missing entries fall back to `.importantOnly`.
    public var perProject: [String: ProjectRule]
    public var keywords: [KeywordRule]

    public init(
        globalEnabled: Bool = true,
        quietHours: QuietHours? = nil,
        perProject: [String: ProjectRule] = [:],
        keywords: [KeywordRule] = []
    ) {
        self.globalEnabled = globalEnabled
        self.quietHours = quietHours
        self.perProject = perProject
        self.keywords = keywords
    }

    public static let `default` = NotificationRules()

    // MARK: - QuietHours

    public struct QuietHours: Codable, Sendable, Equatable {
        public var startMinute: Int       // 0..1439, minutes since midnight local
        public var endMinute: Int         // 0..1439; wraps midnight if end < start
        public var timeZoneIdentifier: String  // "Asia/Taipei"

        public init(startMinute: Int, endMinute: Int, timeZoneIdentifier: String) {
            self.startMinute = startMinute
            self.endMinute = endMinute
            self.timeZoneIdentifier = timeZoneIdentifier
        }

        public func isActive(at date: Date = Date()) -> Bool {
            var cal = Calendar(identifier: .gregorian)
            if let tz = TimeZone(identifier: timeZoneIdentifier) { cal.timeZone = tz }
            let comps = cal.dateComponents([.hour, .minute], from: date)
            let m = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            if startMinute <= endMinute {
                return m >= startMinute && m < endMinute
            } else {
                // Wraps midnight, e.g. 23:00 → 08:00
                return m >= startMinute || m < endMinute
            }
        }
    }

    // MARK: - ProjectRule

    public struct ProjectRule: Codable, Sendable, Equatable {
        public var level: Level
        public init(level: Level) { self.level = level }

        public enum Level: String, Codable, Sendable, CaseIterable {
            case all              // push every state change
            case importantOnly    // push waiting + error (skip "completed")
            case errorsOnly       // push only errors
            case none             // silent (mute this project)
        }
    }

    // MARK: - KeywordRule

    public struct KeywordRule: Codable, Sendable, Equatable, Identifiable {
        public var id: UUID
        public var pattern: String       // simple substring match for v1
        public var action: Action

        public init(id: UUID = UUID(), pattern: String, action: Action) {
            self.id = id
            self.pattern = pattern
            self.action = action
        }

        public enum Action: String, Codable, Sendable, CaseIterable {
            case alwaysPush  // bypass quiet hours / project mute
            case suppress    // never push if this pattern matches
        }
    }

    // MARK: - Decision

    /// Returns true if a push should be sent for the given event.
    /// - Parameters:
    ///   - projectId: claude project slug
    ///   - kind: "waitingForInput" | "running" | "completed" | "error"
    ///   - bodyPreview: first ~100 chars of the alert body (used for keyword match)
    public func shouldPush(
        projectId: String,
        kind: String,
        bodyPreview: String = "",
        now: Date = Date()
    ) -> Bool {
        // Keyword wins over everything.
        for rule in keywords {
            let p = rule.pattern.lowercased()
            guard !p.isEmpty else { continue }
            let haystack = bodyPreview.lowercased()
            if haystack.contains(p) {
                switch rule.action {
                case .alwaysPush: return true
                case .suppress: return false
                }
            }
        }

        guard globalEnabled else { return false }
        if let q = quietHours, q.isActive(at: now) { return false }

        let level = perProject[projectId]?.level ?? .importantOnly
        switch level {
        case .none: return false
        case .errorsOnly: return kind == "error"
        case .importantOnly: return kind == "waitingForInput" || kind == "error"
        case .all: return true
        }
    }
}

public extension NotificationRules.ProjectRule.Level {
    var localizedLabel: String {
        switch self {
        case .all: "All updates"
        case .importantOnly: "Waiting + errors only"
        case .errorsOnly: "Errors only"
        case .none: "Silent"
        }
    }
}
