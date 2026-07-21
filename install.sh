#!/usr/bin/env bash
# One-step install: registers the native messaging host with Firefox and,
# if a signed .xpi is present in dist/, opens it in Firefox to install the
# extension.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_SCRIPT="$DIR/native/open_in_chrome.py"
MANIFEST_DIR="$HOME/.mozilla/native-messaging-hosts"
MANIFEST="$MANIFEST_DIR/com.meltzg.chrome_redirector.json"

if ! command -v python3 >/dev/null; then
  echo "error: python3 is required" >&2
  exit 1
fi
if ! command -v google-chrome >/dev/null && ! command -v google-chrome-stable >/dev/null \
   && ! command -v chromium >/dev/null && ! command -v chromium-browser >/dev/null; then
  echo "warning: no Chrome/Chromium found in PATH — install Google Chrome first" >&2
fi

# 1. Native messaging host
chmod +x "$HOST_SCRIPT"
mkdir -p "$MANIFEST_DIR"
cat > "$MANIFEST" <<EOF
{
  "name": "com.meltzg.chrome_redirector",
  "description": "Opens URLs in Google Chrome for the chrome-redirector extension",
  "path": "$HOST_SCRIPT",
  "type": "stdio",
  "allowed_extensions": ["chrome-redirector@meltzg"]
}
EOF
echo "✓ Native host registered: $MANIFEST"
echo "  (points at $HOST_SCRIPT — don't move or delete this clone)"

# 2. Extension
XPI="$(ls -1 "$DIR"/dist/*.xpi 2>/dev/null | sort -V | tail -n1 || true)"
if [ -n "$XPI" ]; then
  echo "✓ Opening signed extension in Firefox: $XPI"
  echo "  Click 'Add' in the Firefox prompt to finish."
  firefox "$XPI" >/dev/null 2>&1 &
else
  echo
  echo "No signed .xpi found in dist/. To load the extension for testing:"
  echo "  Firefox → about:debugging#/runtime/this-firefox → Load Temporary Add-on…"
  echo "  → select $DIR/extension/manifest.json"
fi
