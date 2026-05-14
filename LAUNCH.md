# Launch playbook

Step-by-step plan for getting MC Pocket + Mission Control in front of people, with copy-ready text for every channel. The whole launch is "one developer dropping a side project," not a corporate launch — keep the tone modest, technical, specific.

## 0. Pre-flight checklist (do these before going live)

- [ ] iOS app on App Store, approved (review ≈ 24h after submit)
- [ ] Mac `MissionControl-0.1.0.dmg` notarized + on GitHub release page
- [ ] `mc-pocket` GitHub repo public, README rewritten with hero pitch
- [ ] `claude-mission-control` GitHub release v0.1.0 cut, with `.dmg` attached and matching CHANGELOG
- [ ] Privacy policy live (GitHub Pages)
- [ ] 1 hero screenshot of Portfolio tab + 1 of Live Activity on Lock Screen
- [ ] 1 short demo GIF (≤ 15 sec, ≤ 5 MB) — see `tools/capture-demo.sh`
- [ ] Test pair flow end-to-end on your own iPhone (TestFlight build is fine)
- [ ] Twitter handle ready, Hacker News account ≥ a week old with ≥ 1 karma

Launch on a **Tuesday or Wednesday at 7–9am Pacific** (lowest competition on HN, peak EU + US morning).

---

## 1. Hacker News (the single biggest lever)

Submit a **"Show HN"** post to <https://news.ycombinator.com/submit>. Title formatting matters — use this exact pattern (proven on past Claude Code-adjacent launches):

```
Show HN: MC Pocket – iPhone companion for your Claude Code sessions
```

URL field: the **GitHub repo** for `mc-pocket` (not the App Store link — HN voters click into source). Add the App Store link in the comment.

First-comment template (post immediately after submitting, by you):

```
Author here. Quick context for why this exists:

I'm juggling 14 Claude Code projects on my Mac. The friction every day was
walking back to my desk to find out which session is waiting on a permission
prompt, which one errored two hours ago, which one is still chewing on a long
task. Anthropic shipped Remote Control in Claude Code 2.1.110 but it's
terminal-mirror style — one session at a time.

MC Pocket is the opposite axis: a glanceable portfolio of all sessions,
designed for "I'm in the supermarket queue, what does my Mac need from me."

How it works:
- Open source Mac menubar app (Mission Control) exposes an HTTPS-style HTTP
  server on your local network or Tailscale tailnet
- iPhone/Watch app pairs via QR, then HMAC-SHA256 signs every request
- Push notifications fire from your Mac directly to api.push.apple.com —
  no third-party relay, no analytics, no telemetry
- Live Activity / Dynamic Island for "waiting" state with elapsed timer

The Mac side is OSS too: <https://github.com/Arlong6/claude-mission-control>

iOS: <App Store link goes here>
Watch: yes, bundled in the iOS app

Happy to answer anything about the architecture, the Network.framework HTTP
server, APNs from a Mac (JWT-signed POSTs to Apple), or the Swift 6 strict
concurrency tax (oof).
```

Be online for **the next 6 hours** to respond. The first hour of comments decides whether the post climbs. Reply to every substantive comment within 15 minutes. Don't be defensive.

Backup title if "Show HN" is too crowded:
> Show HN: A native iPhone monitor for Claude Code on your Mac

---

## 2. Twitter / X (thread + announcement)

Tweet 1 (the hook):

```
shipped today: MC Pocket

an iPhone (+ watch) companion for Claude Code that lives on YOUR Mac.

14 projects running. you're at the supermarket. which one is waiting?

App Store: <link>
GitHub: <link>

(thread on the architecture, why I didn't use Anthropic's official remote)
```

Tweet 2:

```
Anthropic shipped Remote Control in Claude Code 2.1.110.

It's great if you want to mirror one terminal session to your phone.

It's not great if what you actually want is "tell me which of my 14 projects
needs me right now, without picking one first."

Different axis. So I built the other axis.
```

Tweet 3 (architecture):

```
Mac side is an OSS menubar app I shipped a few weeks ago.

It already watched ~/.claude/projects/*.jsonl for state changes.

So I added a tiny HTTP server (Network.framework, ~200 lines), HMAC-SHA256
auth, and an APNs pusher that goes Mac → api.push.apple.com directly.

No backend. No relay. No telemetry.
```

Tweet 4 (privacy):

```
your prompts never leave your Mac.

push payloads contain only {projectId, sessionId, "waiting for your input"}.

if you want to see the actual session content, the iPhone has to pull it back
over the HMAC channel — and that channel runs on YOUR Wi-Fi or YOUR Tailscale.

audit-friendly. open source. MIT.
```

Tweet 5 (close):

```
free on the App Store. Mac app is a notarized .dmg on the GitHub releases page.

if you use Claude Code daily on a Mac and you've ever wished you could "kinda
just glance at all of it from your wrist" — this is for you.

ko-fi if it helps you out, but mostly: try it and tell me what's missing.

<link>
```

Tag people who care (in replies, not the main thread, to avoid alienating
the algorithm): @AnthropicAI, @claudeai (if exists), Claude Code power users
you've replied to before.

---

## 3. Reddit (different audience per sub, different framing)

Don't just cross-post the same text — Reddit punishes that. Tailor each:

### r/macapps
**Title**: `Built a free macOS menubar app + iPhone companion for monitoring AI coding sessions`

```
Made this for my own use after getting tired of switching terminal windows to
check on 14 different Claude Code sessions. Now lives in the menubar and the
iPhone companion (free on App Store) shows the status of every project at a
glance.

Mac app: notarized .dmg, open source: <link>
iPhone: <App Store link>

Architecture: Mac app reads ~/.claude/projects/ directly, exposes an HMAC-signed
HTTP server on your LAN, iPhone pairs via QR. No third-party relay.

Both repos are MIT. Tested on Sonoma 14.x and Sequoia 15.x.

Open to feedback on what other devs would want surfaced.
```

### r/ClaudeAI
**Title**: `Open-source iOS + Mac companion for managing many Claude Code projects at once`

```
For people running Claude Code in multiple projects: this is the "Slack but for
your AI coding sessions" view I wanted.

What it does:
- Lists every claude-code project on your Mac, sorted by what needs you now
- Push notification + Live Activity when a session is waiting for input
- Reply from your phone, Mac dispatches to `claude --resume`
- Per-project notification rules (mute / errors-only / everything)
- Apple Watch app with quick-reply templates

It's a companion to Anthropic's own Remote Control in 2.1.110+ rather than
a replacement — the official one is great for one session at a time; mine is
for "I have 14 things going, glance and triage."

Both halves are OSS:
- iOS: <link>
- Mac: <link>

Free on App Store, free on GitHub.
```

### r/swift
**Title**: `Lessons from shipping a Swift 6 strict-concurrency iOS+watchOS+widget app to App Store`

```
Just shipped MC Pocket (iPhone companion for Claude Code). Three Swift things
that were way more annoying than I expected:

1. ActivityKit + Swift 6 strict concurrency.
   Activity<T>.update / Activity<T>.end aren't marked Sendable. Solution:
   `@preconcurrency import ActivityKit` until Apple ships proper annotations.

2. UNUserNotificationCenterDelegate clashes with UIApplicationDelegate's
   implicit @MainActor.
   Fix: mark the UN delegate methods nonisolated and hop back manually.

3. NSGraphicsContext init from a bitmap returns nil from `swift` CLI
   (no NSApplication context).
   Workaround: use plain CoreGraphics + CGImageDestination for image
   generation in scripts.

Full source: <github link>

Stack: SwiftUI, ActivityKit, AVFoundation, CryptoKit, WidgetKit, watchOS
single-target app. Xcode 26, Swift 6.0, iOS 17 minimum.

Built in ~2 days using Claude Code on the Mac side. Yes, that's recursive.
```

### r/programming
**Title**: `Built an iPhone+watch companion for my AI coding sessions — open source, HMAC signed, no backend`

(Same structure as r/macapps but slightly more technical framing about the
auth and the lack of backend.)

---

## 4. Indie Hackers + Product Hunt

**Indie Hackers** (lower stakes, friendlier audience):
- Cross-post the Show HN text to <https://www.indiehackers.com/post>
- Tag "side project" and "open source"

**Product Hunt** (optional — only if you want signups; less relevant for OSS):
- Submit on a Tuesday at 0:01 AM Pacific
- Need a "maker" account + 1 hunter to feature you
- More polish required (gallery, GIF, tagline)
- Skip if you don't want the social media work

---

## 5. Awesome lists / curated directories

Submit PRs to add MC Pocket + Mission Control to:

- [ ] [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — Claude Code tools list
- [ ] [hesreallyhim/awesome-claude-code-agents](https://github.com/hesreallyhim/awesome-claude-code-agents) — if there's an agent angle
- [ ] [iCHAIT/awesome-macOS](https://github.com/iCHAIT/awesome-macOS) — section "Open Source Apps"
- [ ] [Strvm/awesome-anthropic](https://github.com/Strvm/awesome-anthropic) — community tools
- [ ] [JuanCrg90/Clean-Code-Notes](https://github.com/) — ignore, just an example
- [ ] [vinta/awesome-python](https://github.com/) — not relevant, just listing the pattern

Look for `awesome-iphone-apps`, `awesome-watchos`, `awesome-swiftui` and submit when relevant.

PR template:

```markdown
- [MC Pocket](https://github.com/Arlong6/mc-pocket) — iPhone + Apple Watch
  companion for [Claude Mission Control](https://github.com/Arlong6/claude-mission-control).
  Glance at every Claude Code session on your Mac, get a Live Activity when
  one waits on you, reply from the lock screen. Free on App Store. Self-hosted,
  HMAC-signed, no third-party relay.
```

---

## 6. Newsletters / aggregators (send a tip email)

- [ ] TLDR Newsletter — <https://tldr.tech/submit> (submit a tip)
- [ ] Pointer.io — dev tools focus
- [ ] Hacker Newsletter — Friday recap, autofills from HN front page
- [ ] iOS Goodies — <https://iosgoodies.com>
- [ ] Swift Weekly Brief — <https://swiftweeklybrief.com>
- [ ] iOS Dev Weekly — <https://iosdevweekly.com>

Email template:

```
Subject: Show project — MC Pocket: iPhone companion for Claude Code

Hey [name],

Just shipped a small side project that might fit [newsletter name]: MC Pocket
(<link>), an open-source iPhone+watch companion for Anthropic's Claude Code
CLI. It pairs with a free Mac menubar app I shipped earlier (Mission Control,
also open source) so you can see the status of every Claude Code project on
your Mac at a glance, get a Live Activity when one waits on you, and reply
from your phone or watch.

The whole thing is self-hosted — no third-party relay, HMAC-SHA256 signed,
free on App Store. Source code public.

Happy to provide a high-res screenshot or short Loom if useful.

Thanks for considering!
— Arlong
```

---

## 7. Personal blog / write-up (the long tail)

Write a 1,500-word post for your blog (or dev.to, hashnode, Medium) covering:

1. Why you built it (15-line answer)
2. Architecture diagram + walk-through
3. The interesting Swift 6 concurrency war-stories from /r/swift above
4. The "Mac is the source of truth" argument vs cloud-relayed alternatives
5. What's next (v1.1 features)

This is the artifact that keeps paying dividends 6 months later when someone
googles "claude code iphone monitor."

Title ideas (in descending click-through quality):
- "I shipped an iPhone app + Mac companion in 2 days using Claude Code"
- "Self-hosted iPhone companion for Claude Code: why and how"
- "Building MC Pocket: HMAC, APNs, Live Activities, no backend"

---

## 8. Follow-up plan (post-launch week 1)

Day 1 (launch day):
- HN, Twitter at 7am Pacific
- Reddit at 9am Pacific (give HN 2 hours head-start so people clicking from
  Reddit also boost HN)
- Be online + reply 8am–8pm

Day 2:
- Cross-post to Indie Hackers
- Send newsletter tips
- Tweet a "thanks to everyone who tried it — here's what people are asking
  for" reply thread

Day 3–7:
- Write the blog post (link back to HN comments + screenshots)
- Cut a v0.1.1 with whatever 2 bugs the community surfaces (always be
  shipping = signals life)
- Submit to awesome-lists

Day 14:
- Recap thread: "1 week of MC Pocket — N downloads, M GitHub stars, here's
  what's in v0.1.2"

The point of the recap is to give people who missed the launch a fresh hook.

---

## What success looks like

Realistic targets for a first launch by a single dev with no prior audience:

| Metric | "OK" | "Good" | "Great" |
|---|---|---|---|
| HN front page | reaches /newest only | hits #20–#50 of front page | top 5 |
| GitHub stars (iOS) | 50 | 300 | 1500 |
| App Store downloads in week 1 | 100 | 500 | 3000 |
| Issues opened | 2 | 10 | 30 |
| Twitter impressions | 5k | 50k | 500k |

If you hit "OK" across the board, that's already a successful launch — most
side projects get 0 downloads. The point isn't to "go viral," it's to seed
the search graph so people who Google "claude code monitor iphone" 6 months
from now find it.

---

## Tone reminders (this is what kills launches)

- Don't oversell. "I built this because I needed it" beats "this is the
  future of AI coding workflows."
- Don't bash the official Anthropic version. Position as "different axis."
- Be honest about limitations (Mac required, narrow audience).
- Don't ask for stars. Don't beg. Don't say "please share."
- Reply to critics without defensiveness — they're giving you free feedback.
- Don't post on Friday or weekends.
