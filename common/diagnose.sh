#!/bin/bash
# =====================================================================
#  diagnose.sh — checks the whole request path LAYER BY LAYER:
#     Network (ping) -> DNS -> TCP -> TLS -> HTTP/Application
#  This is the same method you must use in Phase 2, Extension F.
#
#  Run on a CLIENT Mac (Mac 1 or Mac 2):
#      bash ~/Desktop/cn_phase2/common/diagnose.sh
#
#  RULE: fix the FIRST layer that fails. Every layer above it will
#  also fail because of it.
# =====================================================================
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/team-settings.sh"
CA_FILE="$ROOT/common/ca.crt"

pass()  { printf "  ✅ PASS  %s\n" "$1"; }
fail()  { printf "  ❌ FAIL  %s\n" "$1"; [ -n "$2" ] && printf "           hint: %s\n" "$2"; }
info()  { printf "  ℹ️   %s\n" "$1"; }
title() { printf "\n━━━━ %s ━━━━\n" "$1"; }

# ---------------------------------------------------------------- 1
title "1. NETWORK / IP   — can this Mac reach each team Mac? (ping)"
for entry in "Mac1=$MAC1_IP" "Mac2=$MAC2_IP" "Mac3=$MAC3_IP"; do
  name="${entry%%=*}"; ip="${entry#*=}"
  if ping -c 1 -t 2 "$ip" >/dev/null 2>&1; then
    pass "$name ($ip) answers ping"
  else
    fail "$name ($ip) does not answer ping" \
         "same Wi-Fi? did its IP change? (on that Mac: ipconfig getifaddr en0)"
  fi
done

# ---------------------------------------------------------------- 2
title "2. DNS   — what IP does $DOMAIN turn into?"
info "This Mac asks these DNS servers: $(scutil --dns | awk '/nameserver\[[0-9]+\]/{print $3}' | sort -u | tr '\n' ' ')"

A1=$(dig +short +time=2 +tries=1 @"$MAC1_IP" "$DOMAIN" A 2>/dev/null | grep -E '^[0-9.]+$' | head -1)
if [ -n "$A1" ]; then pass "Mac 1 DNS ($MAC1_IP) answers: $DOMAIN -> $A1"
else fail "Mac 1 DNS ($MAC1_IP) gives no answer" "on Mac 1: sudo brew services list   (is dnsmasq 'started'?)"; fi

A3=$(dig +short +time=2 +tries=1 @"$MAC3_IP" "$DOMAIN" A 2>/dev/null | grep -E '^[0-9.]+$' | head -1)
if [ -n "$A3" ]; then pass "Mac 3 backup DNS ($MAC3_IP) answers: $DOMAIN -> $A3"
else info "Mac 3 backup DNS ($MAC3_IP) gives no answer (normal in Phase 1; needed in Phase 2)"; fi

SYS_IP=$(dscacheutil -q host -a name "$DOMAIN" 2>/dev/null | awk '/^ip_address:/{print $2; exit}')
TARGET="$SYS_IP"
if [ -z "$SYS_IP" ]; then
  fail "THIS Mac cannot resolve $DOMAIN (this is what browser and curl use)" \
       "check this Mac's DNS setting: bash $ROOT/common/set-dns.sh show"
  TARGET="$MAC2_IP"
  info "continuing the next tests with Mac 2's IP ($MAC2_IP) directly"
elif [ "$SYS_IP" = "$MAC2_IP" ]; then
  pass "THIS Mac resolves $DOMAIN -> $SYS_IP (Mac 2 = edge)  ✔ correct"
elif [ "$SYS_IP" = "$MAC3_IP" ]; then
  info "THIS Mac resolves $DOMAIN -> $SYS_IP (Mac 3 = standby edge; OK only during Extension E)"
else
  fail "THIS Mac resolves $DOMAIN -> $SYS_IP, which is NOT an edge Mac" \
       "wrong DNS record? check: bash $ROOT/common/change-dns-record.sh show (on the DNS Macs)"
fi

# ---------------------------------------------------------------- 3
title "3. TCP   — can we open a connection to $TARGET port $HTTPS_PORT?"
if nc -z -G 3 "$TARGET" "$HTTPS_PORT" >/dev/null 2>&1; then
  pass "TCP connection to $TARGET:$HTTPS_PORT works (3-way handshake OK)"
else
  fail "TCP connection to $TARGET:$HTTPS_PORT refused or timed out" \
       "is nginx running on that Mac? (sudo nginx)  is the port right? firewall?"
fi

# ---------------------------------------------------------------- 4
title "4. TLS   — is the certificate valid and trusted?"
if [ ! -f "$CA_FILE" ]; then
  fail "CA file missing: $CA_FILE" "copy ca.crt from Mac 2 (mac2-edge/certs/ca.crt) into cn_phase2/common/"
else
  OUT=$(echo | openssl s_client -connect "$TARGET:$HTTPS_PORT" -servername "$DOMAIN" -CAfile "$CA_FILE" 2>/dev/null)
  CODE=$(echo "$OUT" | awk -F': ' '/Verify return code/{print $2; exit}')
  SUBJ=$(echo "$OUT" | openssl x509 -noout -subject 2>/dev/null)
  case "$CODE" in
    "0 (ok)"*) pass "certificate OK and signed by our CA  ($SUBJ)";;
    "")        fail "no TLS handshake happened" "is nginx listening with 'ssl' on port $HTTPS_PORT?";;
    *)         fail "certificate problem: $CODE" "expired? wrong cert in nginx? CA not the same as on Mac 2?";;
  esac
fi

# ---------------------------------------------------------------- 5
title "5. HTTP / APPLICATION   — does nginx get an answer from a backend?"
CA_ARGS=(); [ -f "$CA_FILE" ] && CA_ARGS=(--cacert "$CA_FILE")
HDR=$(mktemp)
RES=$(curl -s -o /dev/null -D "$HDR" -m 6 "${CA_ARGS[@]}" -w '%{http_code}' "$URL/api/status"); RC=$?
BE=$(awk -F': ' 'tolower($1)=="x-backend"{print $2}' "$HDR" | tr -d '\r')
EDGE=$(awk -F': ' 'tolower($1)=="x-edge"{print $2}' "$HDR" | tr -d '\r')
rm -f "$HDR"
if [ "$RC" -ne 0 ]; then
  case "$RC" in
    6)  fail "curl: could not resolve host" "DNS layer — see step 2";;
    7)  fail "curl: could not connect" "TCP layer — see step 3";;
    28) fail "curl: timed out" "something is dropping packets (firewall?) or very slow";;
    35|60|51|58|77) fail "curl: TLS/certificate error ($RC)" "TLS layer — see step 4";;
    *)  fail "curl error $RC";;
  esac
elif [ "$RES" = "200" ]; then
  pass "HTTP 200 — answered by backend $BE through edge $EDGE"
elif [ "$RES" = "502" ] || [ "$RES" = "504" ]; then
  fail "HTTP $RES — nginx is fine, but it cannot reach any backend" \
       "are both backend.py windows running on Mac 3? right IP/port in nginx config? firewall on Mac 3?"
else
  fail "HTTP $RES" "look at the nginx error log on the edge: tail \"\$(brew --prefix)/var/log/nginx/error.log\""
fi

# ---------------------------------------------------------------- extra
title "EXTRA   — backends directly (skipping nginx)"
for entry in "A=$BACKEND_A_IP:$BACKEND_A_PORT" "B=$BACKEND_B_IP:$BACKEND_B_PORT"; do
  name="${entry%%=*}"; addr="${entry#*=}"
  c=$(curl -s -m 3 -o /dev/null -w '%{http_code}' "http://$addr/api/status")
  if [ "$c" = "200" ]; then info "Backend $name ($addr) is reachable directly from this Mac"
  else info "Backend $name ($addr) is NOT reachable directly from this Mac — expected if the Ext. C firewall is ON; otherwise check backend $name is running"; fi
done

echo
echo "Remember: fix the FIRST layer that failed — the layers after it fail because of it."
