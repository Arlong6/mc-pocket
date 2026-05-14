import Foundation
@preconcurrency import ActivityKit

/// Thin wrapper around ActivityKit so the rest of the app deals with "start /
/// update / end" rather than ActivityKit's verbose API. One active activity
/// per project — re-requesting an already-running one updates instead.
@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var active: [String: Activity<WaitingActivityAttributes>] = [:]

    func start(project: Project, preview: String? = nil) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if let existing = active[project.id] {
            await update(activityId: existing.id, status: .waitingForInput, preview: preview)
            return
        }

        let attrs = WaitingActivityAttributes(
            projectId: project.id,
            projectName: project.name,
            sessionId: nil
        )
        let state = WaitingActivityAttributes.ContentStateValue(
            status: .waitingForInput,
            waitingSince: Date(),
            preview: preview
        )
        do {
            let content = ActivityContent(state: state, staleDate: nil, relevanceScore: 100)
            let activity = try Activity.request(
                attributes: attrs,
                content: content,
                pushType: nil
            )
            active[project.id] = activity
        } catch {
            print("[LiveActivity] start failed: \(error)")
        }
    }

    func update(projectId: String,
                status: WaitingActivityAttributes.ContentStateValue.Kind,
                preview: String? = nil) async {
        guard let activity = active[projectId] else { return }
        await update(activityId: activity.id, status: status, preview: preview)
    }

    private func update(activityId: String,
                        status: WaitingActivityAttributes.ContentStateValue.Kind,
                        preview: String?) async {
        guard let activity = Activity<WaitingActivityAttributes>.activities.first(where: { $0.id == activityId })
        else { return }
        let state = WaitingActivityAttributes.ContentStateValue(
            status: status,
            waitingSince: activity.content.state.waitingSince,
            preview: preview ?? activity.content.state.preview
        )
        let content = ActivityContent(state: state, staleDate: nil, relevanceScore: 100)
        await activity.update(content)
    }

    func end(projectId: String) async {
        guard let activity = active.removeValue(forKey: projectId) else { return }
        let state = activity.content.state
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
    }

    func endAll() async {
        for (_, activity) in active {
            let state = activity.content.state
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.end(content, dismissalPolicy: .immediate)
        }
        active.removeAll()
    }
}
