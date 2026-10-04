# MAC 4 — Backend B (port 3002) + Test client + Wireshark capture

You are **Mac 4**. You run Backend B + you are the main demo client (all tests, captures, and diagnose run from here).
Whole-team overview: `SETUP_4_MACS.md` · full detail: `FULL_GUIDE.md`.

## 0. Fresh Mac setup (one time, on this Mac)

Open Terminal (Cmd+Space → "Terminal") and run these lines one by one:

```bash
# 1) Apple command line tools (python3, git, dig, curl) — click Install if a popup appears
xcode-select --install

# 2) Homebrew (asks for password — typing won't be shown, that's normal)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --version            # version shown = OK   (on Intel Macs the path is /usr/local — run whatever lines the installer prints)

# 3) Unzip the zip in Downloads (double-click), then:
cd ~/Downloads/MAC4
xattr -dr com.apple.quarantine .
chmod +x render.sh */*.sh
```

Wi-Fi: all 4 Macs on the **same hotspot/router**. System Settings → Wi-Fi → (i) Details → **Private Wi-Fi address = Fixed**.
If a firewall popup appears (python3 / nginx / dnsmasq "accept incoming connections?") → **Allow**.

## 1. Set IPs (only `config.env`)

```bash
ipconfig getifaddr en0      # this Mac's IP — share it with the team
```
Once you have all four IPs, open `config.env`:
```bash
open -e config.env
```
Change these lines and save (the file must be **exactly the same** on all four Macs):
```
TEAM=team1
MAC1_IP=<Mac 1 IP>
MAC2_IP=<Mac 2 IP>
MAC3_IP=<Mac 3 IP>
MAC4_IP=<Mac 4 IP>
```
Then:
```bash
./render.sh
scripts/netinfo.sh | tee evidence/phase1/A1-netinfo-$(hostname -s).txt
scripts/pingall.sh | tee evidence/phase1/A2-pingall-$(hostname -s).txt   # all should be OK
```
> Below, replace `team1` and `<MACx_IP>` with your own team / IP.
> If the IP changes later → update `config.env` → `./render.sh` → rerun your role's install command.


```bash
# Also install Wireshark (for Task G)
brew install --cask wireshark
```

## 2. PHASE 1 — run in order

**You start first** (together with Mac 3).

```bash
# (a) Backend B — keep this terminal OPEN
backend/run.sh B
```
New terminal tab (Cmd+T), `cd ~/Downloads/MAC4`, then:
```bash
curl -i http://localhost:3002/api/status     # X-Backend: B
curl -i http://<MAC3_IP>:3001/api/status     # X-Backend: A
```

**After Mac 1 DNS + Mac 2 nginx are running and `ca.crt` has arrived:**
```bash
mkdir -p tls/out && mv ~/Downloads/ca.crt tls/out/
tls/trust-ca.sh
scripts/client-dns.sh primary
scripts/client-dns.sh show
dig app.team1.test                 # SERVER = Mac 1
scripts/lb-test.sh 10              # A, B, A, B
open https://app.team1.test        # padlock
curl -v https://app.team1.test/api/status
curl -sI https://app.team1.test/ | head -1        # HTTP/2 200
```
If curl gives a certificate error → prefix every script after that with `USE_CACERT=1`: `USE_CACERT=1 scripts/lb-test.sh 10`

```bash
# Task F — caching (200 -> 304)
scripts/cache-demo.sh

# Task G — packet capture (.pcap goes to evidence/captures/)
scripts/capture.sh 1.2
scripts/capture.sh 1.3
open -a Wireshark evidence/captures/
#   filters: dns | tcp.flags.syn==1 | tls.handshake | tls.record.content_type==23
#   Statistics -> Flow Graph -> screenshot
```

### Phase 1 failure demos (all shown from here)
```bash
# 1 Wrong DNS server
scripts/client-dns.sh bogus
dig app.team1.test ; curl https://app.team1.test ; ping -c 2 <MAC2_IP>
scripts/client-dns.sh primary

# 2 Wrong record (after dns-set-record.sh app <MAC4_IP> on Mac 1)
scripts/client-dns.sh flush ; curl -v https://app.team1.test     # Connection refused
# 3 Backend A down (Mac 3 Ctrl+C)
scripts/lb-test.sh 6                                              # all B
# 4 Both down (also Ctrl+C on backend B here)
curl -v https://app.team1.test/                                   # 502
backend/run.sh B                                                  # restore (in backend tab)
# 5 Wrong port
curl -v https://app.team1.test:8444/                              # Connection refused
```

## 3. PHASE 2

```bash
# Ext A — Backup DNS
scripts/client-dns.sh both
#   (Mac 1 stops dnsmasq)
scripts/client-dns.sh flush ; dig app.team1.test      # SERVER = Mac 3
scripts/lb-test.sh 4

# Ext B — TTL (keep running in Terminal 2)
scripts/ttl-watch.sh app
#   Terminal 3:
curl -s https://app.team1.test/edge-health
#   (Mac 1 + Mac 3 change the record) -> OS column changes within 30s
scripts/client-dns.sh flush                           # changes immediately

# Ext C — Firewall (for backend B too)
firewall/isolate.sh apply
curl --connect-timeout 3 http://<MAC3_IP>:3001/health  # timeout
scripts/lb-test.sh 4                                    # works via edge
firewall/isolate.sh rollback                            # ⚠️ REQUIRED

# Ext D — HA
scripts/lb-test.sh 6    # A/B -> (Mac 3 Ctrl+C) -> all B -> (restart, 10s) -> A/B

# Ext E — Cutover
scripts/ttl-watch.sh app       # X-Edge column Mac 2 -> Mac 3 after 30s

# Ext F — Faculty fault
scripts/diagnose.sh            # first FAIL = broken layer; fix it and run again
```

## Stop / reset
```bash
# backend: Ctrl+C
firewall/isolate.sh rollback
scripts/client-dns.sh reset
```
