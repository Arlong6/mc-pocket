# MC Pocket — Security & Privacy

MC Pocket is a self-hosted companion. **No third-party server, no telemetry, no analytics SDK, no crash reporter.** Your prompts and Claude responses live on your Mac and stay there.

## Data flow

```
iPhone ─────────────── HMAC-signed HTTP ─────────────► Mac
                       (Tailscale or local Wi-Fi only)

Mac    ───── HTTPS POST to api.push.apple.com ──────► Apple Push (APNs)
                                                          │
                                                          ▼
                                                       iPhone
```

The only external service involved is **Apple Push Notification service** (APNs). Push payloads carry only:
- `projectId` (your `.claude/projects/` folder slug — not the project's contents)
- `sessionId` (the `.jsonl` file basename)
- a short alert body like `"waiting for your input"`

No prompt text, no Claude response, no file contents leave your Mac via push.

## Wire protocol

Every request from the iPhone to the Mac carries an HMAC-SHA256 signature in the `Authorization` header:

```
Authorization: MC1-HMAC-SHA256 ts=1715724000;sig=ab12…
```

Where `sig = HMAC-SHA256(shared_secret, "{METHOD}\n{PATH}\n{ts}\n{sha256(body)}")`.

The Mac:

1. Parses `ts` and rejects anything older or newer than ±300 seconds (replay window).
2. Recomputes the canonical string + HMAC.
3. Constant-time compares to the provided signature.

The shared secret is a 256-bit random value generated on first launch of the Mac side. It's stored:

- **Mac:** macOS keychain (`com.arlong.missioncontrol.remote` service).
- **iOS:** iOS keychain (`com.arlong.mcpocket` service), accessibleWhenUnlocked.

The secret travels exactly once, from the Mac's QR code to the iPhone scanner, over the phone's camera — never over the network.

## Transport

- The Mac listens on plain TCP (no TLS).
- This is fine because we *require* the traffic to traverse one of:
  - Your **local Wi-Fi** (server bound to your Mac, not exposed to the internet).
  - Your **Tailscale tailnet** — encrypted point-to-point via WireGuard.

If you expose the port to the open internet, the HMAC layer still protects the secret from leaking, but you'd lose the network-level encryption. **Don't do that.** Recommended: use Tailscale.

## What the Mac does NOT send

- No `~/.claude/projects/*.jsonl` body content over push notifications.
- No git diffs, no source code.
- No system telemetry.

The iOS app pulls those payloads on demand over the HMAC channel — they don't leave your Mac unprovoked.

## Recommendations

- **Use Tailscale.** Install once on Mac + iPhone. Both devices appear on your tailnet with `<host>.tailnet.ts.net` hostnames. The Mac's "Pairing" QR will encode this hostname so the iPhone never needs your home IP.
- **Rotate the secret** any time a phone is lost or sold. `Mission Control → ⌘, → Pairing → Rotate shared secret` invalidates every paired device; re-scan the QR on each device you still own.
- **Use the `MISSION_CONTROL_BYPASS_PERMISSIONS=0`** environment variable (or just leave it unset — `acceptEdits` is the default) so the Mac still gates Bash and other risky tool calls when iOS sends `/sessions/:id/send`. Default behaviour gates Bash; flipping to bypass is a deliberate choice.

## Reporting

Found something? Open an issue at <https://github.com/Arlong6/mc-pocket/issues> or email the address in the App Store listing. PGP key in repo root if you prefer.
