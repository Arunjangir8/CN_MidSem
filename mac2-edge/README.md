# Mac 2: nginx edge (reverse proxy + load balancer + HTTPS) (Person 2)

## What this Mac does
- Runs **nginx** on port 443: the **only** entry point for clients.
- **Terminates TLS** (HTTPS) with our certificate.
- **Load balances** requests over Backend A and Backend B on Mac 3.
- Is also a second **test client** (for the DNS tests).

## Files in this folder
| File | What it is |
|---|---|
| `make-certs.sh` | Creates our team CA + the HTTPS certificate (Phase 1, Task E) |
| `nginx-phase1.conf.template` | nginx config, Phase 1 (round robin). **Don't edit.** |
| `nginx-phase2.conf.template` | nginx config, Phase 2 (round robin + failover). **Don't edit.** |
| `generated/team-phase1.conf` | Ready Phase 1 config with your IPs |
| `generated/team-phase2.conf` | Ready Phase 2 config with your IPs |
| `certs/` | Made by `make-certs.sh`: `ca.crt`, `ca.key`, `app.crt`, `app.key`. ⚠️ Never share the `.key` files outside the team. |

## Your checklist
> 🔁 Every new Terminal window: `source ~/Desktop/cn_phase2/team-settings.sh`

### Phase 1 — `docs/02-phase1-step-by-step.docx`
- [ ] Step 0: Homebrew, `brew install nginx`, folder on Desktop, team-settings.sh, generate-configs.sh
- [ ] Task A: `show-my-info.sh` + screenshot
- [ ] Task B5: `bash $CN_DIR/common/set-dns.sh phase1` (this Mac is a client too)
- [ ] Task C4: test both backends directly from here
- [ ] Tasks D + E: E1 make certs → D1–D4 install certs + config, `sudo nginx -t`, `sudo nginx` → E2 AirDrop `ca.crt` → E3 `install-ca.sh`
- [ ] D6/D7: lb-test, HTTP/2

### Phase 2 — `docs/03-phase2-step-by-step.docx`
- [ ] Ext A: `set-dns.sh phase2`; be the client for the backup-DNS demo (Wireshark here)
- [ ] Ext B: be the client for the TTL demo
- [ ] Ext D: install `team-phase2.conf`, reload, failover demo
- [ ] Ext E: AirDrop `certs/app.crt` + `certs/app.key` to Mac 3; help set up the standby; be the "cached client"

## Most-used commands on this Mac
| What | Command |
|---|---|
| Check config | `sudo nginx -t` |
| Start nginx | `sudo nginx` |
| Reload after a change | `sudo nginx -s reload` |
| Stop nginx | `sudo nginx -s stop` |
| Installed config file | `$(brew --prefix)/etc/nginx/servers/team.conf` |
| Errors / requests | `tail -n 20 "$(brew --prefix)/var/log/nginx/error.log"` / `access.log` |
| Backend reachable from the edge? | `curl http://$BACKEND_A_IP:3001/api/status` |
