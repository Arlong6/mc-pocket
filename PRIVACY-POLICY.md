# MC Pocket — Privacy Policy

_Last updated: 2026-05-14_

MC Pocket is a self-hosted companion app for [Claude Mission Control](https://github.com/Arlong6/claude-mission-control). It connects your iPhone (and Apple Watch) to an HTTP server you run on your own Mac.

## 1. What data we collect

**None.** MC Pocket does not have a developer-operated backend. It does not contact our servers because we don't operate any.

Specifically, MC Pocket does **not** collect:

- Personally identifiable information (name, email, account ID, etc.)
- Usage analytics or product telemetry
- Crash reports or error logs (no Crashlytics, Sentry, etc.)
- Device identifiers (IDFA / IDFV)
- Location data
- Contacts, calendar, photos, microphone, or any other system data store

## 2. What the app does send

MC Pocket sends data **only** to two destinations:

1. **Your own Mac**, over your local Wi-Fi network or your Tailscale tailnet, using HMAC-signed HTTP requests. This is how it fetches project status and sends messages back to Claude on your Mac. Nothing about this traffic is observable to us.

2. **Apple Push Notification service (APNs)**, when you opt into push notifications. The APNs registration is between Apple and your Mac — we are not in the loop. Your Mac sends a push payload directly to `api.push.apple.com` containing only:
   - The project ID (your `.claude/projects/<slug>` directory name)
   - The session ID (the `.jsonl` filename)
   - A short status string like `"waiting for your input"`

   No prompt content, no Claude responses, no source code, no file contents leave your Mac in push payloads. APNs is governed by [Apple's privacy policy](https://www.apple.com/legal/privacy/).

## 3. Data stored on your iPhone

The app keeps the following on-device only:

- The pairing record for your Mac (hostname, port, shared secret) — stored in the iOS keychain.
- Your push-notification rules (quiet hours, per-project mute, keyword overrides) — stored in iOS UserDefaults.
- A SwiftUI-managed cache of the latest project snapshot it fetched from your Mac.

All of this stays on your device. It is removed when you uninstall the app or tap **Unpair** in Settings.

## 4. Data stored on your Mac

Your Mac stores its own copy of:

- The shared secret, in your macOS keychain.
- Registered device tokens (APNs).
- Your push-notification rules.
- The APNs auth key (`.p8`) file that you provide.

Nothing leaves your Mac except the HTTP responses to your phone (over your private network) and APNs requests to Apple.

## 5. Children's privacy

MC Pocket is a developer tool for adults running developer tooling on their own machines. We do not knowingly direct the app to anyone under 13, and the app collects no data of any kind, so children's data is never at risk through us.

## 6. Open source

The full source code for both the iOS app and the Mac server is available under MIT license. You can verify everything in this policy by reading the code:

- iPhone / Watch client: <https://github.com/Arlong6/mc-pocket>
- Mac server: <https://github.com/Arlong6/claude-mission-control>

## 7. Contact

Questions, concerns, or audits welcome at the email listed on the App Store page for MC Pocket, or via a GitHub issue on either repository above.

## 8. Changes to this policy

If we ever begin collecting data, this policy will be updated and the change announced in the app's release notes on the App Store. The "Last updated" date at the top will change accordingly.
