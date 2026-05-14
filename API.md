# Mission Control HTTP API

Contract between the Mac side (`claude-mission-control`) and the iOS client (`mc-pocket`).

**Auth:** every request carries an HMAC-SHA256 signature:

```
Authorization: MC1-HMAC-SHA256 ts=<unix-seconds>;sig=<hex>
```

where `sig = HMAC-SHA256(shared_secret, "{METHOD}\n{PATH}\n{ts}\n{sha256(body)}")`.

Bearer `Authorization: Bearer <secret>` is also accepted for backwards compatibility during the v0.1 bootstrap window — new clients sign.

Dates are ISO-8601.

## `GET /projects`

```json
[
  {
    "id": "-Users-arlong-Projects-AIvideo",
    "name": "AIvideo",
    "cwd": "/Users/arlong/Projects/AIvideo",
    "status": "running",            // idle | running | waitingForInput | error
    "lastActivity": "2026-05-14T08:21:03Z",
    "unreadCount": 0,
    "dirtyGitFiles": 3,
    "openTodos": 2,
    "hasError": false
  }
]
```

## `GET /sessions/{id}/messages?after=<msgId>`

Returns messages since `after` (omit for the most recent 100).

```json
[
  {
    "id": "01HF...",
    "role": "assistant",            // user | assistant | tool | system
    "text": "Looking at the test…",
    "timestamp": "2026-05-14T08:21:03Z",
    "isError": false
  }
]
```

## `POST /sessions/{id}/send`

```json
{ "text": "keep going" }
```

Returns 202 on accept. The Mac side dispatches via `claude --resume <sid>`.

## `POST /register-device`

```json
{ "token": "<apns-hex>", "platform": "ios", "nickname": "Arlong's iPhone" }
```

Stored on the Mac. APNs pushes flow Mac → api.push.apple.com → device.

## `GET /rules` / `POST /rules`

Push-notification rules edited on the iPhone (quiet hours, per-project mute, keyword overrides). The Mac applies these *before* deciding to fan out a push.

```json
{
  "globalEnabled": true,
  "quietHours": {
    "startMinute": 1380,
    "endMinute": 480,
    "timeZoneIdentifier": "Asia/Taipei"
  },
  "perProject": {
    "-Users-arlong-Projects-AIvideo": { "level": "errorsOnly" }
  },
  "keywords": [
    { "id": "uuid", "pattern": "BLOCKER", "action": "alwaysPush" }
  ]
}
```

## Pairing payload (QR contents)

```
mcpocket://pair?host=<host>&port=<port>&secret=<base64>&nick=<urlencoded>
```

Scanned by the iOS app, decoded into a `PairedServer` and saved to the keychain.

## APNs payload (Mac → device)

```json
{
  "aps": {
    "alert": { "title": "claude-mission-control", "body": "waiting for your input" },
    "sound": "default",
    "mutable-content": 1,
    "interruption-level": "time-sensitive"
  },
  "projectId": "-Users-arlong-Projects-claude-mission-control",
  "sessionId": "01HF...",
  "kind": "waitingForInput"        // waitingForInput | completed | error
}
```
