# MAC 1 — Primary DNS server + Test client

You are **Mac 1**. Job: run dnsmasq (DNS server) + test as a client.
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
cd ~/Downloads/MAC1
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

**Team start order:** Mac 3 + Mac 4 backend → **Mac 1 DNS (you)** → Mac 2 nginx → certificate share.

```bash
# (a) Install + start DNS server  (installs dnsmasq, asks for password)
dns/install-dns.sh
#     Mac 2's IP should be printed at the end = OK

# (b) Point this Mac's DNS to Mac 1 too
scripts/client-dns.sh primary

# (c) Check
dig app.team1.test          # ANSWER = Mac 2 IP, SERVER = Mac 1 IP#53
nslookup app.team1.test
tail -f /tmp/dnsmasq.log    # live queries (stop with Ctrl+C)
```

**After you receive `ca.crt` from Mac 2** (it comes via AirDrop), put it in the `tls/out/` folder:
```bash
mkdir -p tls/out && mv ~/Downloads/ca.crt tls/out/
tls/trust-ca.sh             # browser/curl will now trust the certificate
scripts/lb-test.sh 10       # A, B, A, B ...
open https://app.team1.test # padlock, no warning
```
Screenshots: `dig`, `nslookup`, browser padlock → `evidence/phase1/`.

### Failure demo #2 (you run this)
```bash
scripts/dns-set-record.sh app <MAC4_IP>     # wrong record
#   Mac 4: scripts/client-dns.sh flush; curl -v https://app.team1.test  -> Connection refused
scripts/dns-set-record.sh app reset         # back to normal
```

## 3. PHASE 2

```bash
# Ext A — Backup DNS demo (after backup DNS is installed on Mac 3)
scripts/client-dns.sh both               # DNS = Mac 1 + Mac 3
sudo brew services stop dnsmasq          # stop primary  -> Mac 4 still resolves
sudo brew services start dnsmasq         # start again

# Ext B — TTL demo (run the SAME command on Mac 3 at the same time)
scripts/dns-set-record.sh app <MAC3_IP>
scripts/dns-set-record.sh app reset

# Ext E — Edge cutover (same on Mac 3 too)
scripts/client-dns.sh flush
scripts/dns-set-record.sh app <MAC3_IP>
scripts/dns-set-record.sh api <MAC3_IP>
curl -sI https://app.team1.test/ | grep -i x-edge     # -> Mac 3
scripts/dns-set-record.sh app reset
scripts/dns-set-record.sh api reset

# Ext C demo — direct backend access should be blocked
curl --connect-timeout 3 http://<MAC3_IP>:3001/health   # timeout = firewall is working
```
⚠️ Phase 2 rule: change DNS records on **both Mac 1 and Mac 3**.

## Stop / reset
```bash
sudo brew services stop dnsmasq
scripts/client-dns.sh reset      # restore this Mac's DNS to normal
```
