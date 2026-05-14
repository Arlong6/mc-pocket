#!/bin/bash
#
# Capture a short demo .mov + convert to a small .gif suitable for README
# embedding / Twitter / GitHub release page.
#
# Usage:
#   ./tools/capture-demo.sh                       # 15-second capture
#   ./tools/capture-demo.sh --duration 30         # longer capture
#
# Prereqs:
#   - iPhone Simulator booted with the MCPocket app open
#   - `ffmpeg` installed: brew install ffmpeg

set -euo pipefail

DURATION="${DURATION:-15}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --duration) DURATION="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

mkdir -p demo
TS="$(date +%Y%m%d-%H%M%S)"
MOV="demo/demo-$TS.mov"
GIF="demo/demo-$TS.gif"
WEBM="demo/demo-$TS.webm"

UDID="$(xcrun simctl list devices booted -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data["devices"].items():
    for d in devices:
        if d["state"] == "Booted":
            print(d["udid"])
            sys.exit(0)
sys.exit("No booted simulator")
')"

echo "→ recording $DURATION sec from simulator $UDID to $MOV"
xcrun simctl io "$UDID" recordVideo "$MOV" &
PID=$!

sleep "$DURATION"
kill -INT "$PID" || true
wait "$PID" 2>/dev/null || true

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not installed — keeping $MOV only."
  echo "  brew install ffmpeg  → then re-run to get $GIF"
  exit 0
fi

# Crop, scale, and palette-quantize to keep under 5 MB.
echo "→ ffmpeg → GIF + WebM"
ffmpeg -y -i "$MOV" \
  -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=sierra2_4a" \
  -loop 0 \
  "$GIF" 2>&1 | tail -3

ffmpeg -y -i "$MOV" \
  -c:v libvpx-vp9 -b:v 0 -crf 35 -an \
  -vf "fps=20,scale=640:-1" \
  "$WEBM" 2>&1 | tail -3

echo ""
echo "✓ $MOV    $(du -h "$MOV" | cut -f1)"
echo "✓ $GIF    $(du -h "$GIF" | cut -f1)  (good for Twitter / GitHub README)"
echo "✓ $WEBM   $(du -h "$WEBM" | cut -f1)  (smaller, modern browsers)"
