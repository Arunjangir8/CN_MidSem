#!/bin/bash
# =====================================================================
#  install-ca.sh   (Phase 1, Task E — run on every CLIENT Mac: Mac 1 and Mac 2)
#  Makes this Mac TRUST your team's Certificate Authority, so the browser
#  shows no warning for https://app.<team>.test
#
#  Needs the file common/ca.crt  (created on Mac 2 by make-certs.sh;
#  AirDrop it to the other Macs and put it in cn_phase2/common/).
#
#  Run:   bash ~/Desktop/cn_phase2/common/install-ca.sh
#  Undo:  open "Keychain Access" -> System -> find "<team> Local CA" -> delete
# =====================================================================
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/team-settings.sh"
CA_FILE="$ROOT/common/ca.crt"

if [ ! -f "$CA_FILE" ]; then
  echo "ERROR: $CA_FILE not found."
  echo "Get ca.crt from Mac 2 (cn_phase2/mac2-edge/certs/ca.crt) and put it in cn_phase2/common/"
  exit 1
fi

echo "Adding this CA to the System keychain as TRUSTED (asks your Mac password):"
openssl x509 -in "$CA_FILE" -noout -subject -enddate
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CA_FILE" \
  && echo "Done. Close and reopen your browser, then open $URL"
