#!/bin/bash
# =====================================================================
#  lb-test.sh — sends several HTTPS requests to https://app.<team>.test/api/status
#  and shows, for each one: status code, which BACKEND answered, which
#  EDGE (nginx) answered and the IP we connected to.
#
#  Used for: Phase 1 load balancing, Ext. D (failover), Ext. E (edge cutover).
#  Run on a CLIENT Mac:
#      bash ~/Desktop/cn_phase2/common/lb-test.sh          (6 requests)
#      bash ~/Desktop/cn_phase2/common/lb-test.sh 10       (10 requests)
# =====================================================================
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/team-settings.sh"
CA_FILE="$ROOT/common/ca.crt"
N="${1:-6}"

CA_ARGS=()
if [ -f "$CA_FILE" ]; then
  CA_ARGS=(--cacert "$CA_FILE")     # trust our team CA (this is NOT the same as -k)
else
  echo "Note: $CA_FILE not found, using the Mac's normal trust store."
fi

HDR=$(mktemp)
echo "Sending $N requests to $URL/api/status"
echo
i=1
while [ "$i" -le "$N" ]; do
  OUT=$(curl -s -o /dev/null -D "$HDR" -m 5 "${CA_ARGS[@]}" \
          -w '%{http_code} %{remote_ip}' "$URL/api/status")
  RC=$?
  CODE="${OUT%% *}"; IP="${OUT#* }"
  BACKEND=$(awk -F': ' 'tolower($1)=="x-backend"{print $2}' "$HDR" | tr -d '\r')
  EDGE=$(awk -F': ' 'tolower($1)=="x-edge"{print $2}' "$HDR" | tr -d '\r')
  UP=$(awk -F': ' 'tolower($1)=="x-upstream-addr"{print $2}' "$HDR" | tr -d '\r')
  if [ "$RC" -ne 0 ]; then
    case "$RC" in
      6)  WHY="could not resolve the name (DNS problem)";;
      7)  WHY="could not connect (TCP: nginx down / wrong port / wrong IP)";;
      28) WHY="timed out";;
      35|60|51|58|77) WHY="TLS / certificate problem";;
      *)  WHY="curl error $RC";;
    esac
    printf "Request %2d:  FAILED — %s\n" "$i" "$WHY"
  else
    printf "Request %2d:  HTTP %s   backend=%-2s  edge=%-13s  connected-to=%-15s  nginx-used=%s\n" \
      "$i" "$CODE" "${BACKEND:--}" "${EDGE:--}" "$IP" "${UP:--}"
  fi
  i=$((i + 1))
  sleep 0.5
done
rm -f "$HDR"
