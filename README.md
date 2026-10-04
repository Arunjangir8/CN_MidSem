# 4 Mac Setup Guide — CN Project (Private Network Service Platform)

## Team

| Name | Roll No. |
|---|---|
| ARUN | 2401010098 |
| MAYANK YADAV | 2401010271 |

Report: [`CN_Project_Report.pdf`](CN_Project_Report.pdf) · Video script: [`VIDEO_SCRIPT.md`](VIDEO_SCRIPT.md) · Form answers: [`FORM_ANSWERS.txt`](FORM_ANSWERS.txt)

Each Mac has its own zip (`MAC1.zip` … `MAC4.zip`). Every zip contains the **full project**
(the scripts depend on each other, and roles change in Phase 2); only the
`YOU_ARE_MAC_N.txt` file at the top tells you which Mac it is. Full detailed guide: `FULL_GUIDE.md`.

| Mac | Role | What runs |
|---|---|---|
| **Mac 1** | Primary DNS + client | dnsmasq, dig, curl, browser |
| **Mac 2** | Edge (nginx, TLS, load balancer) | nginx, certificates |
| **Mac 3** | Backend A (port 3001) · Phase 2: backup DNS + standby edge | python backend, dnsmasq, nginx |
| **Mac 4** | Backend B (port 3002) + client + Wireshark capture | python backend, curl, Wireshark |

---

## STEP 0 — On all 4 Macs (one time)

1. All Macs on **the same Wi-Fi / phone hotspot**. (On college Wi-Fi, Macs often can't ping each other.)
2. System Settings → Wi-Fi → Details → **Private Wi-Fi address: Fixed** (so the IP doesn't change).
3. Install Homebrew (if not installed): <https://brew.sh>
4. Unzip the zip and go into the folder in Terminal:
   ```bash
   cd ~/Downloads/MAC1          # your folder
   xattr -dr com.apple.quarantine .   # remove macOS "downloaded file" block
   chmod +x render.sh */*.sh
   ```
5. If a firewall popup appears (python3 / nginx / dnsmasq) → **Allow**.

---

## STEP 1 — WHERE TO CHANGE THE IPs  ⚠️ most important

**Only one file: `config.env`.** Don't write IPs anywhere else — all scripts read from here.

1. Get your IP on each Mac:
   ```bash
   ipconfig getifaddr en0                     # e.g. 192.168.43.25
   route -n get default | grep interface      # usually en0
   networksetup -listallnetworkservices       # usually "Wi-Fi"
   ```
2. Collect all four IPs in one place, then edit these lines in `config.env`:
   ```bash
   TEAM=team1                 # your team number -> app.team1.test
   MAC1_IP=192.168.1.11       # <- Mac 1 IP
   MAC2_IP=192.168.1.12       # <- Mac 2 IP
   MAC3_IP=192.168.1.13       # <- Mac 3 IP
   MAC4_IP=192.168.1.14       # <- Mac 4 IP
   NET_SERVICE="Wi-Fi"        # if different
   IFACE=en0                  # if different
   ```
   If port 443/80 won't bind: `HTTPS_PORT=8443`, `HTTP_PORT=8080`.
3. **Copy the same `config.env` to all four Macs** (AirDrop / WhatsApp / git). It must be exactly identical on all four.
4. On each Mac:
   ```bash
   ./render.sh                # builds real configs in build/ from config.env
   ```
5. Also fill in your real IPs in the IP table in `docs/architecture.md` (for the report).

> If an IP ever changes (Wi-Fi reconnect) → update `config.env` → `./render.sh` on all four → rerun `dns/install-dns.sh` on Mac 1 (and Mac 3), and `nginx/install-edge.sh phase1` on Mac 2.

---

## STEP 2 — Start ORDER

```
① Mac 3 + Mac 4: backends    ② Mac 1: DNS    ③ Mac 2: certs + nginx
④ ca.crt from Mac 2 to all Macs → trust    ⑤ Mac 1 + Mac 4: set client DNS    ⑥ test
```

### Mac 3 — Backend A
```bash
backend/run.sh A           # keep this terminal open (0.0.0.0:3001)
```

### Mac 4 — Backend B
```bash
backend/run.sh B           # keep this terminal open (0.0.0.0:3002)
```
Check from any Mac: `curl -i http://<MAC3_IP>:3001/api/status` → `X-Backend: A`

### Mac 1 — Primary DNS
```bash
dns/install-dns.sh         # installs dnsmasq + loads records + self-test (should print Mac 2's IP)
tail -f /tmp/dnsmasq.log   # (optional) watch live queries
```

### Mac 2 — Certificates + Edge nginx
```bash
tls/make-certs.sh          # creates tls/out/ca.crt, server.crt, server.key
nginx/install-edge.sh phase1
tail -f /tmp/nginx-team-access.log   # (optional) upstream= for every request
```
Now copy **only `tls/out/ca.crt`** (never the `.key`!) into the `tls/out/` folder on Mac 1, Mac 3, Mac 4 (AirDrop).

### On each client Mac (Mac 1, Mac 4 — and any Mac using a browser)
```bash
tls/trust-ca.sh            # trust the CA in the System keychain (asks for password)
scripts/client-dns.sh primary   # DNS = Mac 1, cache flush
```

### Test (from Mac 4 or Mac 1)
```bash
dig app.team1.test                  # ANSWER = Mac 2 IP, SERVER = Mac 1
scripts/lb-test.sh 10               # A, B, A, B ...
```
Browser: `https://app.team1.test` → padlock, no warning.
If curl gives a cert error: `USE_CACERT=1 scripts/lb-test.sh 10` (this still verifies — no `-k`).

✅ If this works = Phase 1 gate passed.

---

## STEP 3 — Phase 1 work per Mac (evidence)

| Mac | Commands |
|---|---|
| **All** | `scripts/netinfo.sh \| tee evidence/phase1/A1-netinfo-$(hostname -s).txt` <br> `scripts/pingall.sh \| tee evidence/phase1/A2-pingall-$(hostname -s).txt` |
| **Mac 1** | `dig app.team1.test`, `nslookup app.team1.test` (screenshot) |
| **Mac 4** | `scripts/cache-demo.sh` (200 → 304) <br> `brew install --cask wireshark` <br> `scripts/capture.sh 1.2` and `scripts/capture.sh 1.3` → open `evidence/captures/*.pcap` in Wireshark, screenshot (filters: `dns`, `tcp.flags.syn==1`, `tls.handshake`) <br> `curl -v https://app.team1.test/api/status` |

**Phase 1 failure demos (from Mac 4, restore after each one):**

| # | Break | Restore |
|---|---|---|
| 1 | Mac 4: `scripts/client-dns.sh bogus` → dig fails, ping to Mac 2 still works | `scripts/client-dns.sh primary` |
| 2 | Mac 1: `scripts/dns-set-record.sh app <MAC4_IP>`; Mac 4: `scripts/client-dns.sh flush` → Connection refused | Mac 1: `scripts/dns-set-record.sh app reset` |
| 3 | Mac 3: Ctrl+C → Mac 4: `scripts/lb-test.sh` all B | Mac 3: `backend/run.sh A` |
| 4 | Stop both backends on Mac 3 + Mac 4 → `curl -v https://app.team1.test` → 502 | restart both |
| 5 | Mac 4: `curl -v https://app.team1.test:8444/` → Connection refused | — |

---

## STEP 4 — Phase 2 (per Mac)

| Ext | Mac | Commands |
|---|---|---|
| **A** Backup DNS | Mac 3 | `dns/install-dns.sh` |
| | Mac 1 + Mac 4 | `scripts/client-dns.sh both` |
| | Demo | Mac 1: `sudo brew services stop dnsmasq` → Mac 4: `scripts/client-dns.sh flush; dig app.team1.test` (SERVER = Mac 3) → Mac 1: `sudo brew services start dnsmasq` |
| **B** TTL | Mac 4 | Terminal 1: `scripts/ttl-watch.sh app` · Terminal 2: `curl -s https://app.team1.test/edge-health` |
| | Mac 1 **and** Mac 3 | `scripts/dns-set-record.sh app <MAC3_IP>` → OS column changes within 30s · then on both: `scripts/dns-set-record.sh app reset` |
| **C** Firewall | Mac 3 + Mac 4 | `firewall/isolate.sh apply` → from Mac 1, `curl --connect-timeout 3 http://<MAC3_IP>:3001/health` times out; `scripts/lb-test.sh 4` still works → **`firewall/isolate.sh rollback`** (required before Ext E) |
| **D** HA failover | Mac 2 | `nginx/install-edge.sh phase2` → Mac 4: `scripts/lb-test.sh 6` → Mac 3 Ctrl+C → `lb-test` all B → restart A, wait 10s → A/B back |
| **E** Edge cutover | Mac 3 | Copy `tls/out/server.crt` + `server.key` from Mac 2 → `nginx/install-edge.sh phase2` |
| | Mac 4 | `scripts/ttl-watch.sh app` |
| | Mac 1 **and** Mac 3 | `scripts/dns-set-record.sh app <MAC3_IP>` and `scripts/dns-set-record.sh api <MAC3_IP>` → X-Edge becomes Mac 3 (on Mac 4 after ≤30s) → restore: `... reset` on both |
| **F** Fault diagnose | Mac 4 | `scripts/diagnose.sh` — the first FAIL is the broken layer (DNS → ping → TCP → TLS → HTTP) |

Phase 2 rule: **always change DNS records on BOTH Mac 1 AND Mac 3.**

---

## Demo day — checklist 30 min before

- [ ] All Macs on the same Wi-Fi, `scripts/netinfo.sh` → IPs unchanged? If changed, redo STEP 1.
- [ ] Mac 3: `backend/run.sh A` · Mac 4: `backend/run.sh B`
- [ ] Mac 1: dnsmasq running (`dig @<MAC1_IP> app.team1.test`)
- [ ] Mac 2: `nginx/install-edge.sh phase2`
- [ ] Mac 3/4: `firewall/isolate.sh rollback` · DNS records `reset`
- [ ] Mac 4: `scripts/diagnose.sh` → all PASS
- [ ] Viva: all members read `docs/viva-prep.md`

## Deliverables
- `docs/architecture.md` (fill IP table → PDF) · fill `docs/phase2-report-template.md`
- Screenshots + `.pcap` in `evidence/` (index: `evidence/README.md`)
- **Do not include `.key` files** when submitting code.
