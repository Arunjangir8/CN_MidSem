# Single-Mac Guide: Setup, Testing, Demo

Everything runs on **this one Mac**. There is nothing to edit by hand.

| Role | Runs as | Port |
|---|---|---|
| Mac 1: DNS (dnsmasq) | Docker container `dns` | 53 |
| Mac 2: nginx (HTTPS + load balancer) | Docker container `edge` | 443 |
| Mac 3: Backend A, B | Python on this Mac | 3001, 3002 |
| Client | This Mac (browser, `dig`, `curl`) | — |

---

## 1. One-time
```bash
sudo brew services stop dnsmasq; sudo nginx -s stop   # frees ports 53/443 (ignore errors)
```
Install Docker Desktop if it is missing.

## 2. Start
1. Open **Docker Desktop** and wait until it is ready.
2. Run:
   ```bash
   cd ~/Desktop/CN_MidSem && bash solo.sh up
   ```
   Type your Mac password when it asks.
3. Quit the browser fully (Cmd+Q), reopen it, and go to **https://app.team1.test**. You should see a padlock.

## 3. Test
| Test | Command | Expected |
|---|---|---|
| All layers | `bash common/diagnose.sh` | Every line PASS |
| DNS | `dig app.team1.test +short` | This Mac's IP |
| HTTPS | `curl -v https://app.team1.test/api/status` | `SSL certificate verify ok` |
| Load balancing | `bash common/lb-test.sh 6` | A, B, A, B |
| Caching | `bash common/cache-test.sh` | `304 Not Modified` |
| Live logs | `bash solo.sh logs` | DNS queries + nginx requests |

## 4. Failure demo
| Break | Command | Result |
|---|---|---|
| Backend B down | `kill $(cat .solo/backend-B.pid)` → `bash common/lb-test.sh` | Only A answers, service stays up |
| DNS down | `docker compose stop dns` → `bash common/flush-dns.sh` → `dig app.team1.test` | Timeout |
| nginx down | `docker compose stop edge` → `curl https://app.team1.test` | Connection refused |
| Restore | `bash solo.sh up` | Everything back |

## 5. Stop (always do this)
```bash
bash solo.sh down
```
⚠️ If you skip this, the Mac keeps using a DNS server that is now off, and the internet stops working.

---

## Problems
| Problem | Fix |
|---|---|
| `Docker is not running` | Open Docker Desktop, wait, run again |
| `Port busy` | Run step 1, then `up` again |
| Browser warning | Quit the browser fully (Cmd+Q) and reopen it |
| Wi-Fi changed / no internet | `bash solo.sh down && bash solo.sh up` |
| Anything stuck | `bash solo.sh down && bash solo.sh up` |
| Still a browser warning | `curl --cacert mac2-edge/certs/ca.crt https://app.team1.test/api/status` (works without trusting the CA) |

## Viva notes
- **Why one Mac?** The containers act as separate hosts and use the same ports and protocols as the 3-Mac setup. The Phase 2 extensions (backup DNS, firewall, cutover) need real separate machines.
- **Why 1 nginx worker?** Each worker keeps its own round-robin counter. With several workers, the answers would not alternate A, B.
