#!/usr/bin/env bash
# Signs the extension via addons.mozilla.org so release Firefox will install
# it. The signed .xpi lands in dist/. Normally run by CI on a version tag
# (.github/workflows/release.yml); run manually only for local testing.
#
# Get API credentials at: https://addons.mozilla.org/developers/addon/api/key/
# then run:  AMO_JWT_ISSUER=user:xxx:yyy AMO_JWT_SECRET=zzz ./sign.sh
set -euo pipefail

: "${AMO_JWT_ISSUER:?Set AMO_JWT_ISSUER (from https://addons.mozilla.org/developers/addon/api/key/)}"
: "${AMO_JWT_SECRET:?Set AMO_JWT_SECRET}"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

npx --yes web-ext sign \
  --source-dir "$DIR/extension" \
  --artifacts-dir "$DIR/dist" \
  --channel unlisted \
  --api-key "$AMO_JWT_ISSUER" \
  --api-secret "$AMO_JWT_SECRET"

echo
echo "Signed .xpi written to dist/:"
ls -1 "$DIR"/dist/*.xpi
