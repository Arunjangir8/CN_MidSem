# CN Project: Private Network Service Platform

### 👉 START HERE

This folder has **everything** for Phase 1 and Phase 2: the config files, the code, the helper scripts and the step-by-step guides.

---

## 1. What we are building (in one picture)

```
                         Same Wi-Fi network (LAN)
 ┌──────────────────────────────────────────────────────────────────────────┐
 │                                                                          │
 │   ┌───────────────────┐   1. "Where is app.team1.test?"                  │
 │   │ CLIENT            │ ────────────────────────────►  ┌───────────────┐ │
 │   │ (Mac 1 or Mac 2)  │ ◄────────────────────────────  │ Mac 1         │ │
 │   │ browser / curl    │   2. "It is at Mac 2's IP"     │ DNS (dnsmasq) │ │
 │   └─────────┬─────────┘                                └───────────────┘ │
 │             │ 3. HTTPS request (TCP + TLS) to Mac 2, port 443            │
 │             ▼                                                            │
 │   ┌───────────────────┐   4. plain HTTP   ┌──────────────────────────┐   │
 │   │ Mac 2             │ ────────────────► │ Mac 3                    │   │
 │   │ nginx             │                   │  Backend A  (port 3001)  │   │
 │   │ HTTPS + load      │ ◄──────────────── │  Backend B  (port 3002)  │   │
 │   │ balancer ("edge") │   5. JSON answer  └──────────────────────────┘   │
 │   └───────────────────┘                                                  │
 └──────────────────────────────────────────────────────────────────────────┘
```

**Phase 2** adds a **backup DNS** and a **standby nginx** on Mac 3, a **firewall** on Mac 3, and **automatic failover** in nginx.

---

## 2. Who does what (3 people, 3 Macs)

| Person | Sits at | Main job | Phase 2 extensions |
|---|---|---|---|
| **Person 1** | **Mac 1** | DNS server (dnsmasq) + test client | A (backup DNS), B (TTL) |
| **Person 2** | **Mac 2** | nginx edge: HTTPS, certificates, load balancer | D (failover), E (edge migration) |
| **Person 3** | **Mac 3** | The two backends | C (firewall), F (troubleshooting), evidence + report |


---

## 3. What is in this folder

```
cn_phase2/
├── README.md                  ← you are here
├── team-settings.sh           ← ✏️ THE ONLY FILE YOU EDIT (your IPs and team name)
├── generate-configs.sh        ← puts your IPs into all config files
│
├── mac1-dns/                  ← files for MAC 1
│   ├── README.md                 Mac 1 checklist
│   ├── dnsmasq.conf.template     DNS config (with placeholders)
│   └── generated/                ready configs appear here after generate-configs.sh
│
├── mac2-edge/                 ← files for MAC 2
│   ├── README.md                 Mac 2 checklist
│   ├── make-certs.sh             creates the HTTPS certificates
│   ├── nginx-phase1.conf.template
│   ├── nginx-phase2.conf.template
│   ├── certs/                    certificates appear here after make-certs.sh
│   └── generated/
│
├── mac3-backends/             ← files for MAC 3
│   ├── README.md                 Mac 3 checklist
│   ├── backend.py                the backend app (Backend A and B)
│   ├── pf-firewall.conf.template firewall rules (Phase 2)
│   └── generated/
│
├── common/                    ← helper scripts used on several Macs
│   ├── show-my-info.sh           prints IP, mask, gateway, MAC and pings the team (Task A)
│   ├── set-dns.sh                sets which DNS server a client uses
│   ├── install-ca.sh             makes a client trust our certificate
│   ├── flush-dns.sh              clears a Mac's DNS cache
│   ├── change-dns-record.sh      changes the DNS record (Phase 2)
│   ├── lb-test.sh                sends several requests: shows backend / edge
│   ├── cache-test.sh             shows caching headers + 304 Not Modified
│   └── diagnose.sh               checks every layer: ping → DNS → TCP → TLS → HTTP
│
├── docs/                      ← the guides (read in this order)
│   ├── 01-concepts-in-simple-words.docx
│   ├── 02-phase1-step-by-step.docx
│   ├── 03-phase2-step-by-step.docx
│   ├── 04-troubleshooting.docx
│   ├── 05-final-demo-script.docx
│   ├── 06-viva-questions.docx
│   ├── 07-architecture-document.docx      (deliverable: fill in)
│   ├── 09-phase1-report.docx              (deliverable: Phase 1 report, 3-Mac version, with real screenshots)
│   ├── 10-phase2-report.docx              (deliverable: Phase 2 report, filled with the real Phase 2 screenshots)
│   ├── 11-phase2-example-outputs.docx     (teaching guide: labelled EXAMPLE outputs, so students know what to expect)
│   ├── diagrams/                          (all diagram images used in the reports and slides)
│   └── example-outputs/                   (the 6 labelled example terminal images, NOT evidence)
│
├── presentation/
│   └── CN-Phase2-Presentation.pptx        (final presentation, 22 slides incl. 6 real-output slides, speaker notes included)
│
└── evidence/                  ← save screenshots and Wireshark files here
    ├── README.md                 list of what to save, with file names
    ├── phase1/                   real Phase 1 evidence: screenshots/, captures/ (.pcap), A1/A2/D1 text files
    └── phase2/                   real Phase 2 screenshots (A-1 … F-1)
```

---

## 4. Order of work

1. ☐ Everyone reads **docs/01-concepts-in-simple-words.docx** (20 min).
2. ☐ **Phase 1:** follow **docs/02-phase1-step-by-step.docx** from Step 0 to the end. Do it together, in one room.
3. ☐ **Phase 2:** follow **docs/03-phase2-step-by-step.docx**.
4. ☐ Practise faults with **docs/04-troubleshooting.docx**.
5. ☐ Fill in **docs/07-architecture-document.docx**, and the one remaining yellow ▶ box (faculty-injected fault) in **docs/10-phase2-report.docx** after the live challenge.
6. ☐ Rehearse the demo with **docs/05-final-demo-script.docx** at least twice.
7. ☐ Each person studies **docs/06-viva-questions.docx**.

---

## 5. Golden rules (read these!)

1. **Every new Terminal window:** first run
   ```bash
   source ~/Desktop/cn_phase2/team-settings.sh
   ```
   Then names like `$MAC1_IP`, `$DOMAIN`, `$URL` and `$CN_DIR` work in commands.
2. Copy commands **exactly**, one code box at a time.
3. `sudo` asks for **your Mac login password**. Nothing shows while you type it. That is normal; just type it and press Enter.
4. **Ctrl + C** stops a running program (for example a backend or `tail -f`).
5. Wi-Fi IPs can **change** from one day to the next. At the start of **every** session, check them with `ipconfig getifaddr en0`. If one changed: edit `team-settings.sh` on all Macs → run `generate-configs.sh` on all Macs → re-install the configs (see docs/04-troubleshooting.docx, "IP changed").
6. **Always use the name** (`https://app.team1.test`), never the IP, in the browser or curl for the demo.
7. Never use `curl -k` in the demo. It turns certificate checking OFF. We use `--cacert common/ca.crt` instead, which still checks the certificate but trusts our own team CA.
