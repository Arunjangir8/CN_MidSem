#!/bin/bash
# =====================================================================
#  cache-test.sh  (Phase 1, Task F) — shows HTTP caching headers and a
#  conditional request that returns "304 Not Modified".
#
#  Run on a CLIENT Mac:   bash ~/Desktop/cn_phase2/common/cache-test.sh
# =====================================================================
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/team-settings.sh"
CA_FILE="$ROOT/common/ca.crt"
CA_ARGS=()
[ -f "$CA_FILE" ] && CA_ARGS=(--cacert "$CA_FILE")

echo "=== Request 1: normal request for $URL/  (curl -I = headers only) ==="
R1=$(curl -sI "${CA_ARGS[@]}" "$URL/")
echo "$R1" | grep -iE '^(HTTP/|cache-control|etag|x-backend|x-edge)' | tr -d '\r'
ETAG=$(echo "$R1" | awk -F': ' 'tolower($1)=="etag"{print $2}' | tr -d '\r')

if [ -z "$ETAG" ]; then
  echo "No ETag received — is the service running? Try: bash $ROOT/common/diagnose.sh"
  exit 1
fi

echo
echo "=== Request 2: CONDITIONAL request — 'I already have version $ETAG, has it changed?' ==="
echo "    curl -I -H 'If-None-Match: $ETAG' $URL/"
curl -sI "${CA_ARGS[@]}" -H "If-None-Match: $ETAG" "$URL/" \
  | grep -iE '^(HTTP/|cache-control|etag|x-backend|x-edge)' | tr -d '\r'

echo
echo "What this means:"
echo "  - Cache-Control: max-age=60 -> for 60 s the browser may reuse its copy WITHOUT asking (fresh cache hit)."
echo "  - After that it asks with If-None-Match (conditional request)."
echo "  - 304 Not Modified -> 'your copy is still good', sent with NO body (saves data)."
echo "  - A full new request gets 200 + the whole body."
