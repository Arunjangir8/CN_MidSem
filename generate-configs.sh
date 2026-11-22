#!/bin/bash
# =====================================================================
#  generate-configs.sh
#  Puts your IPs (from team-settings.sh) into all the config templates.
#
#  Run it on EVERY Mac after you edit team-settings.sh:
#      bash ~/Desktop/cn_phase2/generate-configs.sh
#
#  Run it again any time an IP changes, then re-install the configs
#  (the guides tell you how).
# =====================================================================
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT/team-settings.sh"

echo "Checking team-settings.sh ..."
for v in MAC1_IP MAC2_IP MAC3_IP ROUTER_IP BACKEND_A_IP BACKEND_B_IP; do
  val="${!v}"
  if ! [[ "$val" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "ERROR: $v = '$val' is not a valid IP address. Fix it in team-settings.sh"
    exit 1
  fi
done
if ! [[ "$TEAM" =~ ^[a-z0-9]+$ ]]; then
  echo "ERROR: TEAM = '$TEAM'. Use only small letters and numbers, e.g. team1"
  exit 1
fi

# fill <template> <output> <edge-name>
fill() {
  sed -e "s|__TEAM__|$TEAM|g" \
      -e "s|__MAC1_IP__|$MAC1_IP|g" \
      -e "s|__MAC2_IP__|$MAC2_IP|g" \
      -e "s|__MAC3_IP__|$MAC3_IP|g" \
      -e "s|__EDGE_IP__|$MAC2_IP|g" \
      -e "s|__ROUTER_IP__|$ROUTER_IP|g" \
      -e "s|__HTTPS_PORT__|$HTTPS_PORT|g" \
      -e "s|__BACKEND_A_IP__|$BACKEND_A_IP|g" \
      -e "s|__BACKEND_A_PORT__|$BACKEND_A_PORT|g" \
      -e "s|__BACKEND_B_IP__|$BACKEND_B_IP|g" \
      -e "s|__BACKEND_B_PORT__|$BACKEND_B_PORT|g" \
      -e "s|__EDGE_NAME__|$3|g" \
      "$1" > "$2"
  echo "  created  ${2#$ROOT/}"
}

mkdir -p "$ROOT/mac1-dns/generated" "$ROOT/mac2-edge/generated" "$ROOT/mac3-backends/generated"

echo "Generating config files ..."
# Mac 1: main DNS
fill "$ROOT/mac1-dns/dnsmasq.conf.template"          "$ROOT/mac1-dns/generated/dnsmasq.conf"           ""
# Mac 2: nginx edge (Phase 1 and Phase 2 versions)
fill "$ROOT/mac2-edge/nginx-phase1.conf.template"    "$ROOT/mac2-edge/generated/team-phase1.conf"      "primary-mac2"
fill "$ROOT/mac2-edge/nginx-phase2.conf.template"    "$ROOT/mac2-edge/generated/team-phase2.conf"      "primary-mac2"
# Mac 3: backup DNS (same records as Mac 1), standby nginx, firewall
fill "$ROOT/mac1-dns/dnsmasq.conf.template"          "$ROOT/mac3-backends/generated/dnsmasq-backup.conf" ""
fill "$ROOT/mac2-edge/nginx-phase2.conf.template"    "$ROOT/mac3-backends/generated/team-standby.conf" "standby-mac3"
fill "$ROOT/mac3-backends/pf-firewall.conf.template" "$ROOT/mac3-backends/generated/cn-firewall.conf"  ""

echo
echo "Done. These values were used — make sure they are YOUR real ones:"
echo "  Team / website     : $TEAM  ->  $URL"
echo "  Mac 1 (DNS)        : $MAC1_IP"
echo "  Mac 2 (nginx edge) : $MAC2_IP"
echo "  Mac 3 (backends)   : $MAC3_IP   (Backend A port $BACKEND_A_PORT, Backend B port $BACKEND_B_PORT)"
echo "  Router             : $ROUTER_IP"
