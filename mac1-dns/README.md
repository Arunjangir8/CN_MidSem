# Mac 1: DNS server + test client (Person 1)

## What this Mac does
- Runs **dnsmasq**, our private DNS server: `app.<team>.test` → Mac 2's IP.
- Is a **test client**: browser, curl and Wireshark run here.

## Files in this folder
| File | What it is |
|---|---|
| `dnsmasq.conf.template` | DNS config with placeholders (`__MAC2_IP__` …). **Don't edit.** |
| `generated/dnsmasq.conf` | The ready config with your IPs (made by `generate-configs.sh`). This one gets installed. |

## Your checklist (commands are in the guides)
> 🔁 Every new Terminal window: `source ~/Desktop/cn_phase2/team-settings.sh`

### Phase 1 — `docs/02-phase1-step-by-step.docx`
- [ ] Step 0: Homebrew, `brew install dnsmasq`, Wireshark, folder on Desktop, team-settings.sh, generate-configs.sh
- [ ] Task A: `bash $CN_DIR/common/show-my-info.sh` + screenshot
- [ ] Task B: B1–B7 (install config, start dnsmasq, dig, set DNS on Mac 1 + Mac 2, watch the log)
- [ ] Task E2–E3: get `ca.crt` from Mac 2 into `common/`, run `install-ca.sh`
- [ ] Test the full path (D5/E4) + `lb-test.sh` + browser padlock
- [ ] Task F: `cache-test.sh` + browser Network tab
- [ ] Task G: Wireshark capture → `evidence/phase1/G-full-flow.pcapng`
- [ ] Failure demos 1–5

### Phase 2 — `docs/03-phase2-step-by-step.docx`
- [ ] Ext A: `set-dns.sh phase2` on Mac 1 + Mac 2; stop/start dnsmasq here for the demo
- [ ] Ext B: TTL demo (`change-dns-record.sh` here AND on Mac 3)
- [ ] Ext C: be the "blocked client" in the test
- [ ] Ext E: change the DNS record for the cutover (here AND on Mac 3)

## Most-used commands on this Mac
| What | Command |
|---|---|
| Start / stop / restart DNS | `sudo brew services start dnsmasq` / `stop` / `restart` |
| Is it running? | `sudo brew services list` |
| Ask our DNS | `dig @$MAC1_IP $DOMAIN` |
| Watch queries live | `tail -f /tmp/dnsmasq-$TEAM.log` |
| Show / change records | `bash $CN_DIR/common/change-dns-record.sh show` / `mac2` / `mac3` |
| Check everything | `bash $CN_DIR/common/diagnose.sh` |
