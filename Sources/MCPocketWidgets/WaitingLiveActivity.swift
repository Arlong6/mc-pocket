import SwiftUI
import WidgetKit
import ActivityKit

/// Lock screen + Dynamic Island UI for a "waiting on you" Claude session.
/// Tapping the Live Activity deep-links into the app via `widgetURL`.
struct WaitingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WaitingActivityAttributes.self) { context in
            LockScreenView(context: context)
                .widgetURL(deepLink(for: context.attributes))
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [.indigo.opacity(0.85), .purple.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.waitingSince, style: .timer)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.projectName)
                            .font(.headline)
                            .lineLimit(1)
                        Text(label(for: context.state.status))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let p = context.state.preview, !p.isEmpty {
                        Text(p)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } compactLeading: {
                Image(systemName: "sparkles").foregroundStyle(.yellow)
            } compactTrailing: {
                Text(context.state.waitingSince, style: .timer)
                    .monospacedDigit()
                    .font(.caption2)
            } minimal: {
                Image(systemName: dotIcon(for: context.state.status))
                    .foregroundStyle(color(for: context.state.status))
            }
            .widgetURL(deepLink(for: context.attributes))
        }
    }

    private func deepLink(for attrs: WaitingActivityAttributes) -> URL? {
        URL(string: "mcpocket://project/\(attrs.projectId)")
    }

    private func label(for s: WaitingActivityAttributes.ContentStateValue.Kind) -> String {
        switch s {
        case .waitingForInput: "waiting for your input"
        case .running: "claude is working…"
        case .completed: "done"
        case .error: "errored"
        }
    }

    private func dotIcon(for s: WaitingActivityAttributes.ContentStateValue.Kind) -> String {
        switch s {
        case .waitingForInput: "hand.raised.fill"
        case .running: "circle.dotted"
        case .completed: "checkmark"
        case .error: "exclamationmark"
        }
    }

    private func color(for s: WaitingActivityAttributes.ContentStateValue.Kind) -> Color {
        switch s {
        case .waitingForInput: .yellow
        case .running: .green
        case .completed: .blue
        case .error: .red
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<WaitingActivityAttributes>

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(.white)
                .padding(8)
                .background(.white.opacity(0.15), in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.projectName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(headline(for: context.state.status))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                if let p = context.state.preview, !p.isEmpty {
                    Text(p)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.waitingSince, style: .timer)
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.white)
                Text("MC Pocket")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func headline(for s: WaitingActivityAttributes.ContentStateValue.Kind) -> String {
        switch s {
        case .waitingForInput: "Claude is waiting on you"
        case .running: "Claude is working…"
        case .completed: "Session finished"
        case .error: "Session errored"
        }
    }
}
