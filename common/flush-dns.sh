#!/bin/bash
# =====================================================================
#  flush-dns.sh  — makes THIS Mac forget all remembered (cached) DNS answers.
#  Next lookup will ask the DNS server again.
#
#  Run:   bash ~/Desktop/cn_phase2/common/flush-dns.sh
# =====================================================================
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
echo "DNS cache flushed on this Mac."
