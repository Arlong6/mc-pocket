# Changelog

## v0.1.0 — 2026-05-14

First public release. Goes from "I want to glance at all my Claude Code sessions from my phone" to a working, signed, App-Store-ready app in one push.

### What's in the box

**iPhone app**
- Portfolio tab — every project on your Mac, status dot, last activity, git/todos badges
- Chat tab — open any project, see history, type a reply, send back to Claude
- Feed tab — cross-project triage: "what needs me right now"
- Settings tab — pair / unpair, edit notification rules
- QR-code pairing via AVFoundation camera scanner
- Manual paste-URL fallback when QR fails
- Polls Mac every 8 seconds when paired

**Apple Watch app**
- List of "waiting" + "errored" projects, sorted by urgency
- Per-project actions: Continue · Stop + summarise · Commit + push
- Pull-to-refresh

**Live Activity / Dynamic Island**
- "Project X is waiting on you — 3m 14s"
- Lock Screen card with project name, status, timer
- Dynamic Island compact + expanded + minimal renderings

**Notification rules**
- Global quiet hours with timezone awareness
- Per-project mute levels: All · Important only · Errors only · Silent
- Keyword overrides: always-push / suppress

**Privacy**
- HMAC-SHA256 signed transport, no Bearer-only fallback for new clients
- ±300s replay window
- Constant-time signature compare
- No third-party relay, no telemetry, no analytics SDK
- Open source on GitHub

### What's NOT in v0.1.0

- Apple Watch complications (in-app list works; complications come in v1.1)
- Quick Action templates beyond the three baked into the Watch app (v1.1)
- Siri Shortcuts / App Intents (v1.1)
- Local AI summarisation of long sessions (v2.0)
- Cross-tool feed beyond Claude Code (v2.0)
- Multi-Mac pairing (v2.0)
- Home Screen widgets — Live Activity is shipping; static widgets defer to v1.1

### Mac side requirements

You need Mission Control v0.2.0+ on the paired Mac:
<https://github.com/Arlong6/claude-mission-control>

It exposes the HTTP server on port 27890 (configurable), generates the pairing QR, and ships APNs notifications directly from your Mac to Apple's `api.push.apple.com`.
