#!/bin/bash
# =====================================================================
#  solo.sh  —  run the whole project on ONE Mac.
#    Mac 1 (dnsmasq) + Mac 2 (nginx)  -> Docker containers
#    Mac 3 (backends A, B)            -> python3 on this Mac
#
#    bash solo.sh up       start everything (asks Mac password for DNS + CA)
#    bash solo.sh down     stop everything and reset this Mac's DNS
#    bash solo.sh status   show what is running
#    bash solo.sh logs     live DNS + nginx logs
#
#  Works for Phase 1 only. Phase 2 extensions (backup DNS, firewall,
#  standby cutover) need separate machines.
# =====================================================================
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
STATE="$ROOT/.solo"
cd "$ROOT"

stop_backends() {
  for f in "$STATE"/backend-*.pid; do
    [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null || true
    rm -f "$f"
  done
}

case "$1" in
up)
  IP="$(ipconfig getifaddr en0 || ipconfig getifaddr en1 || true)"
  # Upstream for normal names: DHCP's DNS server (not always the gateway; unaffected by set-dns.sh)
  ROUTER="$(ipconfig getoption en0 domain_name_server 2>/dev/null || route -n get default | awk '/gateway/{print $2}')"
  [ -n "$IP" ] || { echo "ERROR: no Wi-Fi/Ethernet IP. Connect to a network first."; exit 1; }
  docker info >/dev/null 2>&1 || { echo "ERROR: Docker is not running. Open Docker Desktop and retry."; exit 1; }

  # All 3 "Macs" = this Mac. team-settings.sh picks this file up automatically.
  mkdir -p "$STATE"
  cat > "$STATE/env" <<EOF
MAC1_IP="$IP"
MAC2_IP="$IP"
MAC3_IP="$IP"
ROUTER_IP="$ROUTER"
EOF
  echo "This Mac = $IP   router = $ROUTER"

  bash "$ROOT/generate-configs.sh" >/dev/null
  [ -f "$ROOT/mac2-edge/certs/app.crt" ] || bash "$ROOT/mac2-edge/make-certs.sh"
  source "$ROOT/team-settings.sh"

  echo "Starting backends A and B ..."
  stop_backends
  for b in "A $BACKEND_A_PORT" "B $BACKEND_B_PORT"; do
    set -- $b
    nohup python3 "$ROOT/mac3-backends/backend.py" "$1" "$2" > "$STATE/backend-$1.log" 2>&1 &
    echo $! > "$STATE/backend-$1.pid"
  done

  echo "Starting DNS + nginx containers ..."
  HTTPS_PORT="$HTTPS_PORT" docker compose up -d --build || {
    echo "Port busy? Stop the Homebrew versions first:"
    echo "  sudo brew services stop dnsmasq; sudo nginx -s stop"
    exit 1; }

  # Trust the team CA once, then point this Mac's DNS at the dnsmasq container.
  security find-certificate -c "$TEAM Local CA" /Library/Keychains/System.keychain >/dev/null 2>&1 \
    || bash "$ROOT/common/install-ca.sh"
  bash "$ROOT/common/set-dns.sh" phase1 >/dev/null
  echo
  echo "Ready:  $URL     (check: bash common/diagnose.sh, bash common/lb-test.sh)"
  echo "Stop:   bash solo.sh down"
  ;;
down)
  [ -f "$STATE/env" ] && bash "$ROOT/common/set-dns.sh" reset >/dev/null || true
  docker compose down 2>/dev/null || true
  stop_backends
  rm -f "$STATE/env"   # back to the normal 3-Mac settings
  echo "Stopped. DNS reset to normal."
  ;;
status)
  docker compose ps
  for f in "$STATE"/backend-*.pid; do
    [ -f "$f" ] && kill -0 "$(cat "$f")" 2>/dev/null && echo "$(basename "$f" .pid) running (pid $(cat "$f"))"
  done
  ;;
logs)
  docker compose logs -f
  ;;
*)
  echo "Usage: bash solo.sh up | down | status | logs"; exit 1 ;;
esac
