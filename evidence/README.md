# Evidence folder

The evaluator must find any proof **within 30 seconds**, so use these exact file names.

Screenshot on a Mac: **Cmd + Shift + 4**, then drag over the area. It saves to the Desktop; rename it and move it here.

## phase1/
**Already here (your real Phase 1 evidence from GitHub):**
- `screenshots/01-…10-*.png`: Wireshark and terminal screenshots (Figures 3–12 of `docs/09-phase1-report.docx`)
- `captures/flow-tls1.2-*.pcap`, `flow-tls1.3-*.pcap`: packet captures, open them in Wireshark
- `A1-netinfo-…txt`, `A2-pingall-…txt`, `D1-caching.txt`: text outputs

⚠️ `A2-pingall-…txt` shows every ping as FAIL because the IPs were typed as `10.141.x.x` instead of `10.142.x.x`. Re-run the ping test on the right IPs and save a new screenshot (`A-mac1-info.png`, etc.).

**If you redo Phase 1 on the 3-Mac setup, use these names:**

| File | What it shows | Guide step |
|---|---|---|
| A-mac1-info.png, A-mac2-info.png, A-mac3-info.png | IP, mask, gateway, MAC, pings | Phase 1 Task A |
| B-dig-mac1.png, B-dig-mac2.png | dig answer from our DNS | Task B |
| C-backends-direct.png | curl to 3001 and 3002 from Mac 2 | Task C |
| D-lb-test.png | A/B alternating | Task D |
| D-http2.png | HTTP/2 200 vs HTTP/1.1 200 | Task D7 |
| E-curl-v.png, E-browser-padlock.png | TLS verify OK, no warning | Task E |
| F-cache-test.png, F-browser-network.png | Cache-Control, ETag, 304 | Task F |
| G-full-flow.pcapng | Wireshark capture: DNS + TCP + TLS | Task G |
| G-dns.png, G-tcp-handshake.png, G-tls-handshake.png, G-certificate.png, G-app-data.png | Screenshots of the capture | Task G |
| fail-1-wrong-dns.png … fail-5-wrong-port.png | The 5 failure demos | Phase 1 failures |

## phase2/
**Already here (real Phase 2 evidence, 23 Nov 2026; used as Figures in `docs/10-phase2-report.docx`).**
Name pattern: `<Extension>-<step>-<what it shows>.png`.

| File | What it shows | Ext |
|---|---|---|
| A-1-mac1-primary-dns-stopped.png | Mac 1: dnsmasq stopped | A |
| A-2-dig-backup-dns-and-lb-test.png | Mac 2: Mac 1 refused, Mac 3 answers; lb-test 4 × 200 | A |
| B-1-change-dns-record.png | Mac 1: record changed to Mac 3 | B |
| B-2-ttl-cached-vs-expired.png | Mac 2: TTL 30, dig new vs cache old, expired after 30 s | B |
| C-1-firewall-rules-on.png | Mac 3: pf enabled, pfctl -sr | C |
| C-2-mac1-blocked-nginx-still-ok.png | Mac 1: :3001 refused, via nginx 200 | C |
| C-3-mac2-allowed.png | Mac 2: direct to :3001 allowed | C |
| D-1-backend-a-stopped.png | Mac 3: Backend A stopped | D |
| D-2-failover-and-recovery.png | Mac 1: retry on B, all B, then A/B again | D |
| D-3-nginx-error-log.png | Mac 2: connect() refused to :3001 | D |
| E-1-standby-edge-test.png | Mac 1: standby nginx via --resolve, x-edge standby-mac3 | E |
| E-2-dns-cutover-old-then-new-edge.png | Mac 2: primary-mac2 during TTL, standby-mac3 after 30 s | E |
| F-1-diagnose-dns-fault.png | Mac 1: diagnose.sh, first FAIL at DNS layer | F |

Not captured yet (optional extras): `A-backup-dns.pcapng`, `C-rules-before.txt`, `B-ttl-4-flush.png`, a fresh-client screenshot for Ext E, `F-practice-notes.md`.

## Config bundle (already in this project folder)
- `mac1-dns/generated/dnsmasq.conf`
- `mac2-edge/generated/team-phase1.conf`, `mac2-edge/generated/team-phase2.conf`
- `mac3-backends/generated/team-standby.conf`, `mac3-backends/generated/dnsmasq-backup.conf`, `mac3-backends/generated/cn-firewall.conf`
- `mac3-backends/backend.py`, `mac2-edge/make-certs.sh` (TLS setup notes are in docs/02 Task E)

⚠️ Do **not** hand in `ca.key` or `app.key`.
