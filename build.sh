#!/usr/bin/env bash
# Builds an unsigned extension package into dist/. For a package that release
# Firefox will actually install, run sign.sh instead (one-time, maintainer only).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(python3 -c "import json; print(json.load(open('$DIR/extension/manifest.json'))['version'])")"
mkdir -p "$DIR/dist"

OUT="$DIR/dist/chrome_redirector-$VERSION.zip"
rm -f "$OUT"
(cd "$DIR/extension" && zip -q -r "$OUT" .)
echo "Built $OUT"
