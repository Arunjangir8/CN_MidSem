# Mac 3: backends (+ backup DNS + standby nginx + firewall in Phase 2) (Person 3)

## What this Mac does
- **Phase 1:** runs **Backend A** (port 3001) and **Backend B** (port 3002).
- **Phase 2:**
  - **Backup DNS** (dnsmasq, same records as Mac 1): Ext A
  - **Firewall** (pf): only Mac 2 may reach ports 3001/3002: Ext C
  - **Standby nginx** (same config + certificate as Mac 2): Ext E

## Files in this folder
| File | What it is |
|---|---|
| `backend.py` | The backend app. Start as `python3 backend.py A 3001` and `python3 backend.py B 3002` |
| `pf-firewall.conf.template` | Firewall rules with placeholders. **Don't edit.** |
| `generated/cn-firewall.conf` | Ready firewall rules with your IPs |
| `generated/dnsmasq-backup.conf` | Backup DNS config (same records as Mac 1) |
| `generated/team-standby.conf` | Standby nginx config (says `X-Edge: standby-mac3`) |

## The backend endpoints
| Request | Answer |
|---|---|
| `GET /` | Small HTML page, `Cache-Control: public, max-age=60` + `ETag` (caching demo) |
| `GET /api/status` | `{"backend": "A", "status": "ok"}`, `Cache-Control: no-store` |
| every response | header `X-Backend: A` (or `B`) |
| request with matching `If-None-Match` | `304 Not Modified` |

## Your checklist
> 🔁 Every new Terminal window: `source ~/Desktop/cn_phase2/team-settings.sh`

### Phase 1 — `docs/02-phase1-step-by-step.docx`
- [ ] Step 0: `python3 --version`, `brew install dnsmasq nginx`, folder on Desktop, team-settings.sh, generate-configs.sh
- [ ] Task A: `show-my-info.sh` + screenshot (you lead Task A)
- [ ] Task C: two Terminal windows, Backend A and Backend B, **keep them open**
- [ ] Task E2: put `ca.crt` into `common/` (needed for the scripts)
- [ ] Task G6 (optional): `sudo tcpdump` to show plain HTTP between nginx and the backends
- [ ] Failure demos 3 + 4: stop/start the backends

### Phase 2 — `docs/03-phase2-step-by-step.docx`
- [ ] Ext A: install + start the backup dnsmasq
- [ ] Ext B + E: run `change-dns-record.sh` here too (both DNS servers must match)
- [ ] Ext C: firewall on → demo → **roll back**
- [ ] Ext D: stop/start Backend A for the failover demo
- [ ] Ext E: install + start the standby nginx
- [ ] Ext F: lead the troubleshooting practice (docs/04)
- [ ] Collect evidence (evidence/README.md) + finish the report (docs/10-phase2-report.docx)

## Most-used commands on this Mac
| What | Command |
|---|---|
| Start backends | `cd $CN_DIR/mac3-backends` then `python3 backend.py A 3001` (window 1), `python3 backend.py B 3002` (window 2) |
| Stop a backend | Ctrl + C in its window (restart: ↑ then Enter) |
| What is listening? | `sudo lsof -iTCP -sTCP:LISTEN -P` |
| Backup DNS | `sudo brew services start dnsmasq` / `stop` / `list` |
| Firewall ON | `sudo pfctl -ef $CN_DIR/mac3-backends/generated/cn-firewall.conf` |
| Firewall rules | `sudo pfctl -sr` |
| Firewall OFF (rollback) | `sudo pfctl -f /etc/pf.conf` then `sudo pfctl -d` |
| Standby nginx | `sudo nginx -t`, `sudo nginx`, `sudo nginx -s stop` |
