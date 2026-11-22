#!/bin/bash
# =====================================================================
#  set-dns.sh   — choose which DNS server(s) THIS Mac uses.
#  Run it on the CLIENT Macs (Mac 1 and Mac 2).
#
#    bash ~/Desktop/cn_phase2/common/set-dns.sh phase1   -> use Mac 1 only
#    bash ~/Desktop/cn_phase2/common/set-dns.sh phase2   -> use Mac 1 first, Mac 3 as backup
#    bash ~/Desktop/cn_phase2/common/set-dns.sh wrong    -> use Mac 2 (has NO DNS) for the failure demo
#    bash ~/Desktop/cn_phase2/common/set-dns.sh reset    -> back to normal (router's DNS)
#    bash ~/Desktop/cn_phase2/common/set-dns.sh show     -> show current setting
#
#  Same thing by hand: System Settings -> Network -> Wi-Fi -> Details -> DNS
# =====================================================================
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/team-settings.sh"

case "$1" in
  phase1) SERVERS="$MAC1_IP" ;;
  phase2) SERVERS="$MAC1_IP $MAC3_IP" ;;
  wrong)  SERVERS="$MAC2_IP" ;;
  reset)  SERVERS="empty" ;;
  show)   SERVERS="" ;;
  *) echo "Usage: bash $0 phase1 | phase2 | wrong | reset | show"; exit 1 ;;
esac

if [ -n "$SERVERS" ]; then
  echo "Setting DNS servers on '$WIFI_SERVICE' to: $SERVERS   (asks your Mac password)"
  # shellcheck disable=SC2086
  sudo networksetup -setdnsservers "$WIFI_SERVICE" $SERVERS || {
    echo "Failed. Check the Wi-Fi service name with: networksetup -listallnetworkservices"
    echo "and set WIFI_SERVICE in team-settings.sh"; exit 1; }
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
  echo "DNS cache flushed."
fi

echo
echo "DNS servers set on '$WIFI_SERVICE':"
networksetup -getdnsservers "$WIFI_SERVICE"
echo
echo "DNS servers the Mac is really using now:"
scutil --dns | awk '/nameserver\[[0-9]+\]/{print "  " $3}' | sort -u
