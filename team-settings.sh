# =====================================================================
#  team-settings.sh   —   THE ONLY FILE YOU NEED TO EDIT
# =====================================================================
#
#  1. Change the values below to YOUR team's real values.
#     Only change the text INSIDE the quotes "...". Do not delete the quotes.
#  2. Save the file (Cmd + S).
#  3. Use the SAME values on all 3 Macs.
#  4. In EVERY new Terminal window, load the settings first:
#
#         source ~/Desktop/cn_phase2/team-settings.sh
#
#     After that, the commands in the guides can use names like
#     $MAC1_IP, $MAC2_IP, $DOMAIN, $URL instead of typing IPs.
#
#  How to find the values (run these in Terminal):
#    - The IP of a Mac (run it ON that Mac):  ipconfig getifaddr en0
#    - Your router IP ("gateway"):             route -n get default | grep gateway
#    - Wi-Fi service name:                     networksetup -listallnetworkservices
#
# =====================================================================

# Your team name. Your website will be   app.<TEAM>.test
# Use only small letters and numbers (no spaces, no dots).
TEAM="team1"

# IP address of each Mac  (CHANGE THESE to your real IPs!)
MAC1_IP="192.168.1.11"     # Mac 1 = DNS server + test client
MAC2_IP="192.168.1.12"     # Mac 2 = nginx edge (HTTPS + load balancer) + test client
MAC3_IP="192.168.1.13"     # Mac 3 = Backend A + Backend B  (+ backup DNS + standby nginx in Phase 2)

# Your Wi-Fi router's IP (the "gateway").
# Our DNS server forwards normal internet names (google.com ...) to it.
ROUTER_IP="192.168.1.1"

# HTTPS port used by nginx. Keep 443.
# Only if nginx refuses to start on 443, change this to "8443".
HTTPS_PORT="443"

# Name of the Wi-Fi network service (almost always "Wi-Fi")
WIFI_SERVICE="Wi-Fi"


# ---------------------------------------------------------------------
#  Normally you do NOT need to change anything below this line.
# ---------------------------------------------------------------------

# Where the two backends run (both on Mac 3 in our 3-Mac layout)
BACKEND_A_IP="$MAC3_IP"
BACKEND_A_PORT="3001"
BACKEND_B_IP="$MAC3_IP"
BACKEND_B_PORT="3002"

# Where this folder is on every Mac
CN_DIR="$HOME/Desktop/cn_phase2"

# Names and URL of our service
DOMAIN="app.$TEAM.test"
API_DOMAIN="api.$TEAM.test"
if [ "$HTTPS_PORT" = "443" ]; then
  URL="https://$DOMAIN"
else
  URL="https://$DOMAIN:$HTTPS_PORT"
fi

# Our team's own Certificate Authority certificate (created on Mac 2 in Phase 1, Task E)
CA_FILE="$CN_DIR/common/ca.crt"

export TEAM MAC1_IP MAC2_IP MAC3_IP ROUTER_IP HTTPS_PORT WIFI_SERVICE
export BACKEND_A_IP BACKEND_A_PORT BACKEND_B_IP BACKEND_B_PORT
export CN_DIR DOMAIN API_DOMAIN URL CA_FILE

# When you load this file by hand in Terminal, print a short summary.
case "$-" in
  *i*)
    echo "Settings loaded for team: $TEAM"
    echo "  Mac 1 (DNS)            = $MAC1_IP"
    echo "  Mac 2 (nginx edge)     = $MAC2_IP"
    echo "  Mac 3 (backends)       = $MAC3_IP"
    echo "  Website                = $URL"
    ;;
esac
