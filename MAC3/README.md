# MAC 3 — Backend A (port 3001)  ·  Phase 2: Backup DNS + Standby edge

You are **Mac 3**. Phase 1: Backend A. Phase 2: also backup DNS + standby nginx.
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
cd ~/Downloads/MAC3
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


## 2. PHASE 1 — run in order

**You start first** (together with Mac 4).

```bash
# (a) Run Backend A — keep this terminal OPEN
backend/run.sh A
#     stop = Ctrl+C,  start again = backend/run.sh A
```
New terminal tab (Cmd+T), same folder (`cd ~/Downloads/MAC3`):
```bash
curl -i http://localhost:3001/api/status     # X-Backend: A
```

**After `ca.crt` arrives from Mac 2:**
```bash
mkdir -p tls/out && mv ~/Downloads/ca.crt tls/out/
tls/trust-ca.sh
```

### Failure demos (you run these)
- #3: Press **Ctrl+C** in the Backend A terminal → everything goes to B on Mac 4 → `backend/run.sh A`
- #4: Ctrl+C (Mac 4 also stops its backend) → 502 on Mac 4 → restart both

## 3. PHASE 2

```bash
# Ext A — Backup DNS (same records as Mac 1)
dns/install-dns.sh

# Ext B / E — DNS record change (SAME command as Mac 1)
scripts/dns-set-record.sh app <MAC3_IP>
scripts/dns-set-record.sh api <MAC3_IP>     # only in Ext E
scripts/dns-set-record.sh app reset
scripts/dns-set-record.sh api reset

# Ext C — Firewall: only Mac 2 may reach port 3001
firewall/isolate.sh apply
firewall/isolate.sh status
firewall/isolate.sh rollback       # ⚠️ REQUIRED after the demo (before Ext E)

# Ext D — when Mac 2 says so, Ctrl+C the backend, then backend/run.sh A

# Ext E — Standby edge. server.crt + server.key will arrive from Mac 2 via AirDrop:
mv ~/Downloads/server.crt ~/Downloads/server.key tls/out/
nginx/install-edge.sh phase2
curl --resolve app.team1.test:443:<MAC3_IP> https://app.team1.test/edge-health   # test (from any client)
```
Note: Backend A (terminal 1) must keep running; run the other commands in another tab.

## Stop
```bash
# backend: Ctrl+C
sudo brew services stop dnsmasq
sudo nginx -s stop
firewall/isolate.sh rollback
```
