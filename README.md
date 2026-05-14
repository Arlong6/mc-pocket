# MC Pocket

**iPhone + Apple Watch companion for [Claude Mission Control](https://github.com/Arlong6/claude-mission-control).** Glance at every Claude Code session on your Mac, get a Live Activity when one waits on you, reply from the lock screen.

> Self-hosted. HMAC-signed. No third-party relay. No telemetry. MIT.

```
                      iPhone (this repo)                         Mac (Mission Control)
                      ─────────────────                          ─────────────────────
  ┌─────────────┐     Portfolio · Chat · Feed                    HTTP server (port 27890)
  │  Portfolio  │     │                                          │
  │  ● AIvideo  │ ◄── HMAC-signed HTTP over Wi-Fi/Tailscale ──── │ reads ~/.claude/projects/
  │  🟡 cmcl    │                                                 │ ProjectScanner + git/todos
  │  🔴 CarFndr │                                                 │
  └─────────────┘                                                 │
        ▲                                                         │
        │                                                         ▼
        │             APNs (api.push.apple.com)                  ┌────────────────┐
        └──── Live Activity on Lock Screen ◄─────────────────────│ APNsPusher.p8 │
                                                                  └────────────────┘
```

## Why this exists

You have 14 Claude Code projects on your Mac. Walking back to your desk to find out which session is waiting for a prompt, which one errored two hours ago, which one is still chewing on a long task — that's 90% of the daily friction.

Anthropic shipped Remote Control in Claude Code 2.1.110+, and it's great — it's a terminal mirror, one session at a time. MC Pocket is the other axis: **all sessions, glanceable**.

## What's in v0.1.0

| Surface | What it does |
|---|---|
| **Portfolio tab** | All projects on your Mac, status dot, last activity, git/todos badges, 8-sec auto-refresh |
| **Feed tab** | Cross-project triage — "what needs me right now" sorted by severity |
| **Chat tab** | Open any project, see its conversation, type a reply, send back to Claude |
| **Lock Screen + Dynamic Island** | "Claude is waiting on you — 3m 14s" Live Activity, tap to deep-link |
| **Apple Watch** | Quick triage list + one-tap "Continue / Stop + summarise / Commit + push" |
| **Notification rules** | Quiet hours, per-project mute levels, keyword overrides |
| **Privacy** | HMAC-SHA256 transport, no third-party relay, no telemetry, no analytics SDK |

## Install

**iPhone:** TestFlight beta / App Store (link goes here once approved)

**Mac side (required):** download `MissionControl-0.1.0.dmg` from <https://github.com/Arlong6/claude-mission-control/releases>, drag to Applications, open. ⌘, → iOS Remote → toggle on → scan the QR code with MC Pocket.

For remote access (outside your home Wi-Fi), use [Tailscale](https://tailscale.com) — it's free, works in 5 minutes, and means MC Pocket talks to your Mac end-to-end-encrypted over WireGuard with zero port forwarding.

## Develop

```bash
brew install xcodegen
git clone https://github.com/Arlong6/mc-pocket && cd mc-pocket
xcodegen generate
open MCPocket.xcodeproj
```

Or from CLI (Xcode 26 / Swift 6.0 / iOS 17+):

```bash
xcodebuild -project MCPocket.xcodeproj \
  -target MCPocket \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build CODE_SIGNING_ALLOWED=NO
```

## Project layout

```
Sources/
├── MCPocket/                       # iOS app
│   ├── MCPocketApp.swift           # @main + AppStore
│   ├── AppDelegate.swift           # UIApplicationDelegate + APNs + UN delegate
│   ├── LiveActivityController.swift
│   ├── RootView.swift              # TabView shell
│   └── Views/                      # Portfolio · Chat · Feed · Settings · QRScanner · NotificationRules
├── MCPocketWidgets/                # WidgetKit extension
│   └── WaitingLiveActivity.swift   # Lock Screen + Dynamic Island
├── MCPocketWatch/                  # watchOS app
│   ├── MCPocketWatchApp.swift
│   └── WatchRootView.swift         # triage list + quick actions
└── Shared/                         # cross-platform
    ├── Project.swift               # GET /projects DTO
    ├── ChatMessage.swift           # GET /sessions/{id}/messages DTO
    ├── PairedServer.swift          # keychain-backed pairing record
    ├── MissionControlClient.swift  # HMAC-signing URLSession client
    ├── NotificationRules.swift     # quiet hours / per-project / keywords
    └── WaitingActivityAttributes.swift  # ActivityKit shared schema
```

## Docs

- **[API.md](API.md)** — HTTP contract between iPhone and Mac
- **[SECURITY.md](SECURITY.md)** — threat model, HMAC scheme, wire format
- **[PRIVACY-POLICY.md](PRIVACY-POLICY.md)** — what stays on your devices
- **[CHANGELOG.md](CHANGELOG.md)** — what shipped in each version
- **[LAUNCH.md](LAUNCH.md)** — promotion plan with copy-ready text for HN / Twitter / Reddit
- **[app-store/TESTFLIGHT.md](app-store/TESTFLIGHT.md)** — Apple-side setup walkthrough

## Not in v0.1.0 (coming later)

- Apple Watch complications on the watch face — v1.1
- Siri Shortcuts / Action Button — v1.1
- Local AI summarisation of long sessions — v2.0
- Cross-tool feed (Codex / Cursor / etc) — v2.0
- Multi-Mac pairing — v2.0

## License

MIT, both halves.

Built for one developer's workflow first. Open-sourced because friends asked. If it helps you, a GitHub star is the only currency I care about.
