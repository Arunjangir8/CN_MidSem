# Startup Guide: bring all 3 Macs up (every session)

Use this at the start of **every** lab session, demo or practice, once the one-time setup
(Step 0 in `docs/02-phase1-step-by-step.docx`) is done on all 3 Macs.

> ⚠️ The scripts expect this folder at **`~/Desktop/cn_phase2`**. If yours is called something else
> (e.g. `CN_MidSem`), rename it or run: `ln -s ~/Desktop/CN_MidSem ~/Desktop/cn_phase2`

> 🐳 **Only one Mac? (Phase 1 practice)** Open Docker Desktop, then run `bash solo.sh up`.
> DNS (Mac 1) and nginx (Mac 2) run as containers, and the backends run on this Mac.
> Stop with `bash solo.sh down`, which also resets DNS. Phase 2 extensions need the real 3 Macs.

**Start order matters:** Mac 3 (backends) → Mac 1 (DNS) → Mac 2 (nginx) → test from Mac 1.
nginx needs the backends, and clients need DNS.

---

## Step 0: all 3 Macs (2 min)

1. Join the **same Wi-Fi**.
2. Open Terminal and check this Mac's IP:
   ```bash
   ipconfig getifaddr en0
   ```
3. Compare with `team-settings.sh`. **If any IP changed** (on any Mac):
   - edit `MAC1_IP` / `MAC2_IP` / `MAC3_IP` in `team-settings.sh` on **all 3 Macs** (same values everywhere)
   - run `bash ~/Desktop/cn_phase2/generate-configs.sh` on **all 3 Macs**
   - re-install the configs: the `cp` lines marked 🔁 below
4. Load settings (do this in **every** new Terminal window):
   ```bash
   source ~/Desktop/cn_phase2/team-settings.sh
   ```

---

## Mac 3: backends (Person 3) — start FIRST

Open **two** Terminal windows and keep both open.

Window 1:
```bash
source ~/Desktop/cn_phase2/team-settings.sh
cd $CN_DIR/mac3-backends && python3 backend.py A 3001
```
Window 2:
```bash
source ~/Desktop/cn_phase2/team-settings.sh
cd $CN_DIR/mac3-backends && python3 backend.py B 3002
```
Click **Allow** if macOS asks about incoming connections.

**Phase 2 only** (third window):
```bash
source ~/Desktop/cn_phase2/team-settings.sh
# 🔁 backup DNS
cp $CN_DIR/mac3-backends/generated/dnsmasq-backup.conf "$(brew --prefix)/etc/dnsmasq.conf"
sudo brew services restart dnsmasq
# 🔁 standby nginx (only needed for Ext E)
cp $CN_DIR/mac3-backends/generated/team-standby.conf "$(brew --prefix)/etc/nginx/servers/team.conf"
sudo nginx -t && (sudo nginx -s reload 2>/dev/null || sudo nginx)
```
Leave the firewall **off** until the Ext C demo.

✔ Check: `curl http://$MAC3_IP:3001/api/status` and `:3002` both answer JSON.

---

## Mac 1: DNS server + client (Person 1)

```bash
source ~/Desktop/cn_phase2/team-settings.sh
# 🔁 only if IPs changed
cp $CN_DIR/mac1-dns/generated/dnsmasq.conf "$(brew --prefix)/etc/dnsmasq.conf"
sudo brew services restart dnsmasq
sudo brew services list            # dnsmasq should say "started"
bash $CN_DIR/common/set-dns.sh phase1   # use phase2 in Phase 2 (adds Mac 3 as backup)
```

✔ Check: `dig @$MAC1_IP $DOMAIN +short` prints Mac 2's IP.

---

## Mac 2: nginx edge + client (Person 2)

```bash
source ~/Desktop/cn_phase2/team-settings.sh
# 🔁 only if IPs changed (use team-phase2.conf in Phase 2)
cp $CN_DIR/mac2-edge/generated/team-phase1.conf "$(brew --prefix)/etc/nginx/servers/team.conf"
sudo nginx -t
sudo nginx -s reload 2>/dev/null || sudo nginx
bash $CN_DIR/common/set-dns.sh phase1   # use phase2 in Phase 2
```
Certificates are already installed from Phase 1; no need to redo them.

✔ Check: `curl http://$BACKEND_A_IP:3001/api/status` works from here.

---

## Final check: from Mac 1 (or Mac 2)

```bash
source ~/Desktop/cn_phase2/team-settings.sh
bash $CN_DIR/common/diagnose.sh     # every layer should say PASS
bash $CN_DIR/common/lb-test.sh      # backend A and B take turns
```
Open **https://app.team1.test** (your `$URL`) in the browser → padlock, no warning.

All green? You are ready. Anything red → `docs/04-troubleshooting.docx`.

---

## Shutdown (end of session)

| Mac | Command |
|---|---|
| Mac 3 | Ctrl + C in both backend windows. Phase 2: `sudo brew services stop dnsmasq`, `sudo nginx -s stop`, firewall off: `sudo pfctl -f /etc/pf.conf && sudo pfctl -d` |
| Mac 2 | `sudo nginx -s stop` then `bash $CN_DIR/common/set-dns.sh reset` |
| Mac 1 | `sudo brew services stop dnsmasq` then `bash $CN_DIR/common/set-dns.sh reset` |

⚠️ Run `set-dns.sh reset` on Mac 1 and Mac 2 **before** you leave. If you skip it, those Macs keep using a DNS server that is now off, and normal internet stops working.
