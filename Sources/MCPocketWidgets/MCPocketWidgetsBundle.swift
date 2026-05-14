import SwiftUI
import WidgetKit

/// The widget extension's entry point. Currently exposes only the Live
/// Activity for "Claude is waiting." Home-screen widgets are TBD in v1.1.
@main
struct MCPocketWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WaitingLiveActivity()
    }
}
