# Demo Commands (single Mac, in order)

Use the **Terminal** button in Docker Desktop's bottom bar. It is a normal Mac shell. **Do not** use a container's **Exec** tab, because that shell runs inside the container. Open new tabs with `+`.

**Rule:** run this line first in every new tab:
```bash
cd ~/Desktop/CN_MidSem && source team-settings.sh && IP=$MAC1_IP
```

| Tab | Role |
|---|---|
| 1 | Setup, DNS + nginx, client, tests |
| 2 | Backend A ("Mac 3") |
| 3 | Backend B ("Mac 3") |
| 4 | Live logs |

---

## 1. Setup (Tab 1): first time only, or after a Wi-Fi change
```bash
cd ~/Desktop/CN_MidSem && mkdir -p .solo
IP=$(ipconfig getifaddr en0); DNS=$(ipconfig getoption en0 domain_name_server)
printf 'MAC1_IP="%s"\nMAC2_IP="%s"\nMAC3_IP="%s"\nROUTER_IP="%s"\n' $IP $IP $IP $DNS > .solo/env
source team-settings.sh && bash generate-configs.sh
ls mac2-edge/certs/app.crt || bash mac2-edge/make-certs.sh
```

## 2. Backend A (Tab 2)
```bash
cd ~/Desktop/CN_MidSem && python3 mac3-backends/backend.py A 3001
```

## 3. Backend B (Tab 3)
```bash
cd ~/Desktop/CN_MidSem && python3 mac3-backends/backend.py B 3002
```
If macOS asks about incoming connections, click **Allow**. Keep both tabs open.

## 4. Check backends, then start DNS + nginx (Tab 1)
```bash
cd ~/Desktop/CN_MidSem && source team-settings.sh && IP=$MAC1_IP
curl http://$IP:3001/api/status; echo; curl http://$IP:3002/api/status; echo
docker compose up -d --build dns
dig @$IP app.team1.test +short
docker compose up -d edge
curl --cacert mac2-edge/certs/ca.crt --resolve app.team1.test:443:$IP https://app.team1.test/api/status; echo
```
Expected: `backend A`, `backend B`, this Mac's IP, then JSON over HTTPS.

## 5. Client setup (Tab 1): asks for your Mac password
```bash
security find-certificate -c "team1 Local CA" /Library/Keychains/System.keychain >/dev/null 2>&1 || bash common/install-ca.sh
bash common/set-dns.sh phase1
```
Quit the browser fully (Cmd+Q), reopen it, and go to **https://app.team1.test**. You should see a padlock.

## 6. Live logs (Tab 4)
```bash
cd ~/Desktop/CN_MidSem && docker compose logs -f
```

## 7. Testing (Tab 1)
```bash
bash common/diagnose.sh       # every layer PASS
bash common/lb-test.sh 6      # A, B, A, B
bash common/cache-test.sh     # 304 Not Modified
```

## 8. Failure demo (Tab 1)
```bash
# Backend down: press Ctrl+C in Tab 3 first, then:
bash common/lb-test.sh 6          # only A answers
# restart B in Tab 3 with the same command as step 3

# DNS down
docker compose stop dns && bash common/flush-dns.sh && dig app.team1.test +time=2 +tries=1   # timeout
docker compose start dns

# nginx down
docker compose stop edge && curl -m 5 https://app.team1.test   # connection refused
docker compose start edge
```
You can also start and stop `dns` and `edge` with the buttons in Docker Desktop's **Containers** section.

## 9. Shutdown (always do this)
```bash
bash common/set-dns.sh reset      # first, or the internet stops working
docker compose down
rm .solo/env                      # back to the 3-Mac settings
```
Then press **Ctrl+C** in Tab 2 and Tab 3.

---

## Problems
| Problem | Fix |
|---|---|
| `dig: couldn't get address for ''` / `No host part in the URL` | `$IP` is empty: run the rule line at the top in this tab |
| `Port busy` | `sudo brew services stop dnsmasq; sudo nginx -s stop` |
| Browser warning | Quit the browser fully (Cmd+Q) and reopen it |
| No internet after the demo | `bash common/set-dns.sh reset` |
