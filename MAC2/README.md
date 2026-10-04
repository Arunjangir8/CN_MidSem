# MAC 2 — Edge: nginx reverse proxy + TLS + load balancer

You are **Mac 2**. All HTTPS traffic comes to you, and you forward it to Mac 3 / Mac 4.
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
cd ~/Downloads/MAC2
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

**Team start order:** Mac 3 + Mac 4 backend → Mac 1 DNS → **Mac 2 (you)** → certificate share.

```bash
# (a) Create certificates (only ONCE, only on Mac 2)
tls/make-certs.sh
ls tls/out                     # ca.crt  ca.key  server.crt  server.key ...

# (b) Check backends are reachable
curl http://<MAC3_IP>:3001/health      # ok
curl http://<MAC4_IP>:3002/health      # ok

# (c) Install + start nginx  (asks for password)
nginx/install-edge.sh phase1

# (d) Live log — shows upstream= for every request
tail -f /tmp/nginx-team-access.log
```

**(e) Share the certificate:** Finder → `tls/out/ca.crt` → AirDrop to Mac 1, Mac 3, Mac 4.
❌ Never send `ca.key` / `server.key` to anyone (exception: in Phase 2 Ext E, send `server.crt` + `server.key` to Mac 3).

If you get a port 443 error → set `HTTPS_PORT=8443`, `HTTP_PORT=8080` in `config.env` (on all four Macs) → `./render.sh` → `nginx/install-edge.sh phase1`.

If you also want to test from a browser on this Mac:
```bash
tls/trust-ca.sh
scripts/client-dns.sh primary
scripts/lb-test.sh 10
```

## 3. PHASE 2

```bash
# Ext D — HA failover config
nginx/install-edge.sh phase2
tail -f /tmp/nginx-team-access.log      # if Backend A is down, you'll see: upstream=A, B

# Ext C demo — only Mac 2 can reach the backends
curl http://<MAC3_IP>:3001/health        # ok (times out from Mac 1/4)

# Ext E — send cert files to Mac 3 (AirDrop):  tls/out/server.crt  tls/out/server.key
# after cutover (all traffic on Mac 3):
sudo nginx -s stop
# restore:
sudo nginx
```

## Stop / restart
```bash
sudo nginx -s stop        # stop
sudo nginx                # start
sudo nginx -t             # config check
tail /tmp/nginx-team-error.log    # look here if you get a 502
```
