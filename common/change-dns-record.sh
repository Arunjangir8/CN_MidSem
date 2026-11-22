#!/bin/bash
# =====================================================================
#  change-dns-record.sh  — change where app.<team>.test and api.<team>.test point.
#  Run it on EACH DNS server Mac  (Mac 1, and in Phase 2 also Mac 3),
#  so both DNS servers give the same answer.
#
#    bash ~/Desktop/cn_phase2/common/change-dns-record.sh mac2     -> normal (nginx on Mac 2)
#    bash ~/Desktop/cn_phase2/common/change-dns-record.sh mac3     -> standby edge on Mac 3 (Ext. E)
#    bash ~/Desktop/cn_phase2/common/change-dns-record.sh 1.2.3.4  -> any IP you type
#    bash ~/Desktop/cn_phase2/common/change-dns-record.sh show     -> just show current records
# =====================================================================
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/team-settings.sh"
CONF="$(brew --prefix)/etc/dnsmasq.conf"

case "$1" in
  mac1) NEW="$MAC1_IP" ;;
  mac2) NEW="$MAC2_IP" ;;
  mac3) NEW="$MAC3_IP" ;;
  show) NEW="" ;;
  "")   echo "Usage: bash $0 mac2 | mac3 | <IP> | show"; exit 1 ;;
  *)    NEW="$1" ;;
esac

if ! grep -q "^address=/app\.$TEAM\.test/" "$CONF" 2>/dev/null; then
  echo "ERROR: no record for app.$TEAM.test in $CONF"
  echo "Is our dnsmasq.conf installed on this Mac? (see the Phase 1 / Phase 2 guide)"
  exit 1
fi

echo "Records now in $CONF:"
grep "^address=" "$CONF" | sed 's/^/  /'

[ -z "$NEW" ] && exit 0

if ! [[ "$NEW" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  echo "ERROR: '$NEW' is not an IP address"; exit 1
fi

sudo sed -i '' -E "s#^address=/(app|api)\.$TEAM\.test/.*#address=/\1.$TEAM.test/$NEW#" "$CONF"

echo
echo "Changed to:"
grep "^address=" "$CONF" | sed 's/^/  /'
echo
echo "Restarting dnsmasq so it uses the new records (asks your Mac password) ..."
sudo brew services restart dnsmasq >/dev/null
sleep 2
echo "This DNS server now answers:  $DOMAIN -> $(dig +short @127.0.0.1 "$DOMAIN")"
echo
echo "REMEMBER: do the same on the OTHER DNS server Mac too!"
