#!/bin/bash
# =====================================================================
#  make-certs.sh   (run on Mac 2, Phase 1 Task E)
#
#  Creates:
#   1. ca.crt / ca.key   = your team's own "Certificate Authority" (CA).
#                          Clients will TRUST this CA.
#   2. app.crt / app.key = the HTTPS certificate for app.<team>.test and
#                          api.<team>.test, SIGNED by your CA.
#
#  Run:   bash ~/Desktop/cn_phase2/mac2-edge/make-certs.sh
#
#  Output folder:  mac2-edge/certs/
#  Also copies ca.crt to common/ca.crt (clients need it).
#
#  NEVER share ca.key or app.key with anyone outside the team.
#  (app.crt + app.key are copied to Mac 3 only for the standby nginx.)
# =====================================================================
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/team-settings.sh"

OUT="$ROOT/mac2-edge/certs"
mkdir -p "$OUT"
cd "$OUT"

# ---- 1. The CA (made only once; re-running keeps the same CA) ----
if [ -f ca.key ] && [ -f ca.crt ]; then
  echo "CA already exists in $OUT — keeping it (clients already trust it)."
else
  echo "Creating your team CA ..."
  openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
    -keyout ca.key -out ca.crt \
    -subj "/CN=$TEAM Local CA" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"
fi

# ---- 2. The server certificate for our names ----
echo "Creating the HTTPS certificate for $DOMAIN and $API_DOMAIN ..."
openssl req -newkey rsa:2048 -nodes -sha256 \
  -keyout app.key -out app.csr \
  -subj "/CN=$DOMAIN"

cat > app.ext <<EOF
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:$DOMAIN,DNS:$API_DOMAIN
EOF

openssl x509 -req -sha256 -days 365 \
  -in app.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out app.crt -extfile app.ext

echo
echo "Checking that app.crt is correctly signed by the CA:"
openssl verify -CAfile ca.crt app.crt

cp ca.crt "$ROOT/common/ca.crt"

echo
echo "Certificate details:"
openssl x509 -in app.crt -noout -subject -issuer -enddate
openssl x509 -in app.crt -noout -ext subjectAltName 2>/dev/null || true
echo
echo "Done. Files are in: $OUT"
echo "  ca.crt  -> give to every CLIENT Mac (also copied to common/ca.crt)"
echo "  app.crt + app.key -> used by nginx"
