#!/bin/bash
# =====================================================================
#  show-my-info.sh   (Phase 1, Task A — run on EVERY Mac)
#  Prints this Mac's network details and pings the other team Macs.
#  Take a screenshot of the output for the evidence folder.
#
#  Run:   bash ~/Desktop/cn_phase2/common/show-my-info.sh
# =====================================================================
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/team-settings.sh"

IF=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
[ -z "$IF" ] && IF="en0"
IP=$(ipconfig getifaddr "$IF")
MASK=$(ipconfig getoption "$IF" subnet_mask 2>/dev/null)
GW=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')
MACADDR=$(ifconfig "$IF" 2>/dev/null | awk '/ether /{print $2}')
DNS=$(scutil --dns | awk '/nameserver\[[0-9]+\]/{print $3}' | sort -u | tr '\n' ' ')

echo "================ THIS MAC ================"
echo "  Computer name    : $(scutil --get ComputerName 2>/dev/null)"
echo "  Interface        : $IF"
echo "  IPv4 address     : $IP"
echo "  Subnet mask      : $MASK   (255.255.255.0 = /24)"
echo "  Default gateway  : $GW"
echo "  MAC address      : $MACADDR"
echo "  DNS servers used : $DNS"

ROLE="(not one of the team IPs in team-settings.sh!)"
[ "$IP" = "$MAC1_IP" ] && ROLE="Mac 1 = DNS server + client"
[ "$IP" = "$MAC2_IP" ] && ROLE="Mac 2 = nginx edge"
[ "$IP" = "$MAC3_IP" ] && ROLE="Mac 3 = backends"
echo "  Role             : $ROLE"
echo

echo "================ PING TEST ================"
for entry in "Mac1=$MAC1_IP" "Mac2=$MAC2_IP" "Mac3=$MAC3_IP"; do
  name="${entry%%=*}"; ip="${entry#*=}"
  if [ "$ip" = "$IP" ]; then
    echo "  $name ($ip): this is me, skipping"
    continue
  fi
  if ping -c 2 -t 3 "$ip" >/dev/null 2>&1; then
    t=$(ping -c 2 -t 3 "$ip" | awk -F'/' '/round-trip/{print $5}')
    echo "  $name ($ip): ✅ reachable   (average time ${t} ms)"
  else
    echo "  $name ($ip): ❌ NOT reachable  -> same Wi-Fi? IP changed? firewall 'stealth mode' on?"
  fi
done
