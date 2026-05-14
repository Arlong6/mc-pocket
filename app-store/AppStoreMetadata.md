# App Store Metadata

Drop-in copy for App Store Connect when you go to submit MC Pocket.

---

## App name (30 char max)
```
MC Pocket
```

## Subtitle (30 char max)
```
Your Claude Code, glanceable
```

## Primary category
Developer Tools

## Secondary category
Productivity

---

## Description (4000 char max)

```
MC Pocket is the iPhone (and Apple Watch) companion for Claude Mission Control — the open-source Mac menubar app that lets you wrangle every Claude Code project from one place.

When you've got Claude working in 14 different projects on your Mac, you don't want to babysit each one. You want a glance at your wrist that says "2 waiting, 1 errored, 11 idle" — and a way to reply or unstick a session without going back to your desk.

That's MC Pocket.

— PORTFOLIO AT A GLANCE
See the live status of every project Claude is touching on your Mac. Color-coded status dots, last activity, git dirty files, open todos. Pull to refresh.

— WAITING-FOR-INPUT LIVE ACTIVITY
When a session needs you, MC Pocket pops a Live Activity onto your Lock Screen and Dynamic Island. Tap it to see what Claude's asking. Long press to continue or stop.

— REPLY FROM YOUR POCKET
Type a reply, hit send. The Mac forwards it to the right Claude session and resumes execution. Quick templates included: "continue", "commit and push", "summarize and stop".

— NOTIFICATION RULES THAT RESPECT YOU
Quiet hours per timezone. Per-project rules: get everything, only errors, only "waiting", or mute. Keyword overrides — push me always when a session contains "BLOCKER", mute me whenever it contains "minor".

— PRIVACY FIRST, OPEN SOURCE
MC Pocket has no backend. Your iPhone talks directly to your own Mac over your home Wi-Fi or your Tailscale tailnet. Requests are signed with HMAC-SHA256. No telemetry, no analytics, no account. Source code on GitHub.

— APPLE WATCH
The Watch face shows what needs you right now. Tap to send "continue" or "stop and summarize" without taking out your phone.

Requirements
• Claude Mission Control running on your Mac (free, open source — see github.com/Arlong6/claude-mission-control)
• Pair via QR code on first launch
• Tailscale recommended (free) for remote access; same Wi-Fi also works

MC Pocket is built for one user: you, your Mac, your projects. No data ever leaves your control.
```

---

## Keywords (100 char max, comma separated)
```
claude code,llm,coding,ai,terminal,remote,session,monitor,push,dev,developer,xcode,wrench,glance
```

---

## Support URL
```
https://github.com/Arlong6/mc-pocket/issues
```

## Marketing URL (optional)
```
https://github.com/Arlong6/mc-pocket
```

## Privacy Policy URL
Publish `PRIVACY-POLICY.md` to GitHub Pages or any static host. Then set this to e.g.:
```
https://arlong6.github.io/mc-pocket/privacy
```

---

## What's New in v0.1.0
```
First public release.

• Glanceable Portfolio dashboard for every Claude Code project on your Mac
• Lock Screen + Dynamic Island Live Activity when a session waits on you
• HMAC-signed transport, no third-party relay
• Per-project notification rules, quiet hours, keyword overrides
• Apple Watch app with one-tap "continue" / "stop and summarize" actions
```

---

## Screenshots checklist

Required (per current App Store guidelines, May 2026):
- 6.9" iPhone (Pro Max): at least 3 screenshots, max 10. **1320×2868** portrait.
- 6.5" iPhone: same images, downscaled — App Store Connect auto-derives from 6.9" if you opt in.

Recommended shot list:
1. Portfolio tab with 4+ projects showing variety (waiting / running / error / idle)
2. ChatView with messages + reply field
3. NotificationRulesView showing quiet hours + per-project rules
4. Lock Screen Live Activity ("Claude is waiting on you")
5. Settings → "Paired Mac" view

Render via SwiftUI Previews + `xcrun simctl io <udid> screenshot screen.png` from each Preview in Simulator.

Apple Watch screenshots (optional but recommended):
- Series 10 (49mm): 410×502
- Series 7-8 (45mm): 396×484

---

## Age rating questions
- Unrestricted Web Access: No (the app only contacts your own Mac)
- All other categories: None

Result: 4+

---

## Required encryption export compliance

Use of standard encryption (HMAC + HTTPS to Apple) qualifies for the **exempt** category under US export law (ECCN 5D002.c.1, supplement note 4).

In `Info.plist` (or App Store Connect):
- `ITSAppUsesNonExemptEncryption: NO`

Already configured in `project.yml`? Check before submission.
