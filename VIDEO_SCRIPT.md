# 5 Minute Video Script (Hinglish) — CN Project, Team team1

**Team:** ARUN (2401010098) · MAYANK YADAV (2401010271)

Kaise use karein: left column = screen pe kya dikhana hai, right column = kya bolna hai.
Report = `CN_Project_Report.pdf`. Terminal commands Mac 4 (client) ya Mac 2 se chalao.
Bolne ki speed normal rakho — har section ka time upar likha hai, total ~5 min.

---

## 0:00 – 0:25 · Intro

**Screen:** Report ka cover page.

> "Hello, hum hain Arun aur Mayank Yadav. Humara project hai **Private Network Service Platform**.
> Idea simple hai — application chhota sa hai, asli project network hai.
> Humne 4 Macs pe apna khud ka private DNS, HTTPS edge server aur load balancer banaya hai,
> aur har step ko Wireshark aur curl se prove kiya hai."

---

## 0:25 – 1:05 · Topology aur roles

**Screen:** Report Section 1 — IP table + topology diagram.

> "Chaaron Macs ek hi Wi-Fi pe hain, subnet 10.7.0.0/19, gateway 10.7.0.1.
> **Mac 1** — 10.7.21.254 — humara private DNS server hai, dnsmasq chal raha hai port 53 pe. Cloud mein isko Route 53 samjho.
> **Mac 2** — 10.7.19.102 — nginx edge hai. Yahi HTTPS handle karta hai aur load balance karta hai — jaise AWS ALB.
> **Mac 3** pe Backend A port 3001 pe, aur **Mac 4** pe Backend B port 3002 pe.
> Client ko sirf ek naam pata hai — `app.team1.test`. Backends ke IP client ko kabhi pata nahi chalte."

---

## 1:05 – 1:40 · Ek request ka safar (flow diagram)

**Screen:** Report Section 1 — request flow diagram.

> "Jab client `https://app.team1.test` kholta hai, to chaar cheezein hoti hain:
> **Ek** — DNS query UDP port 53 pe Mac 1 ko jaati hai, jawab aata hai 10.7.19.102.
> **Do** — TCP three-way handshake hota hai port 443 pe — SYN, SYN-ACK, ACK.
> **Teen** — TLS 1.3 handshake, jisme certificate verify hota hai.
> **Chaar** — encrypted HTTP request nginx tak jaati hai, aur nginx round-robin se Backend A ya B ko bhejta hai.
> Yaani ek request mein Application, Transport, Network aur Link — saari layers kaam karti hain."

---

## 1:40 – 2:10 · DNS proof

**Screen:** Terminal (ya report Section 3).
```
dig app.team1.test
dig @8.8.8.8 app.team1.test
```

> "Dekho — answer hai 10.7.19.102, yaani Mac 2, aur SERVER line mein 10.7.21.254 hai — humara apna DNS, Google nahi.
> Aur jab yahi naam 8.8.8.8 se poochha, to **NXDOMAIN** aaya.
> Matlab ye naam sirf humare private network ke andar exist karta hai."

---

## 2:10 – 2:50 · HTTPS + certificate

**Screen:** Terminal.
```
curl -v https://app.team1.test/api/status
```
Highlight karo: `TLSv1.3`, `subjectAltName ... matched`, `SSL certificate verify ok`, `HTTP/2 200`.

> "Humne OpenSSL se apna khud ka CA banaya — *team1 Local Root CA* — aur usse `app.team1.test` ka certificate sign kiya.
> Client Macs pe sirf public `ca.crt` trust kiya, private key Mac 2 se bahar kabhi nahi gayi.
> Yahan dekho — TLS 1.3, certificate ka naam match hua, aur **SSL certificate verify ok**.
> Koi `-k` flag nahi, koi IP nahi — seedha domain name, aur jawab 200."

---

## 2:50 – 3:15 · Load balancing

**Screen:** Terminal.
```
for i in {1..6}; do curl -s -D - -o /dev/null https://app.team1.test/api/status | grep -i x-backend; done
```

> "Same naam pe 6 request bheji — jawab aaya B, A, B, A, B, A.
> Ye nginx ka round-robin hai. Har response mein `X-Backend` header batata hai kis backend ne serve kiya."

---

## 3:15 – 4:00 · Wireshark evidence

**Screen:** Report Section 8 — DNS, TCP, TLS screenshots (ek-ek karke).

> "Ye capture Mac 4 pe liya.
> **DNS:** frame 324 mein query 10.7.16.171 se 10.7.21.254 port 53 UDP pe, aur frame 325 mein answer 10.7.19.102.
> **TCP:** frame 56632 SYN — client port 53342 se server port 443, phir SYN-ACK, phir ACK — Seq 0, Ack 1.
> Handshake ke baad hi TLS shuru hota hai.
> **TLS:** Client Hello mein SNI `app.team1.test` dikh raha hai, phir Server Hello.
> Uske baad sab kuch sirf **Application Data** hai — HTTP headers aur JSON encrypted hain, Wireshark padh hi nahi sakta."

---

## 4:00 – 4:25 · Caching

**Screen:** Terminal (ya report Section 7).
```
curl -sI https://app.team1.test/api/catalog
curl -sI -H 'If-None-Match: "55df56e6b3ea9005"' https://app.team1.test/api/catalog
```

> "`/api/catalog` pe `Cache-Control: max-age=60` aur ETag hai — browser 60 second tak bina poochhe cached copy use karega.
> Uske baad ETag bhej ke poochhta hai — kuch nahi badla to server **304 Not Modified** deta hai, bina body ke.
> `/api/status` live data hai, isliye wahan `no-store` rakha."

---

## 4:25 – 4:50 · Failure demo

**Screen:** Terminal.
```
curl -v https://app.team1.test:9999/api/status
ping -c 3 app.team1.test
```

> "Ab jaan-boojh ke todte hain. Port 9999 pe request — **Connection refused**, sirf 3 millisecond mein.
> Lekin ping chal raha hai, DNS bhi sahi hai. Matlab host zinda hai, bas us port pe koi service nahi — ye **Layer 4** problem hai.
> Aise hi jab client ka DNS galat tha, naam resolve nahi hua lekin IP pe ping chal raha tha — DNS aur IP alag layers hain."

---

## 4:50 – 5:00 · Closing

**Screen:** Topology diagram wapas.

> "To ek request mein — DNS ne edge dhoondha, TCP ne reliable connection banaya, TLS ne usse encrypt kiya,
> nginx ne load balance kiya, aur caching ne decide kiya ki request ki zarurat hai bhi ya nahi.
> Thank you!"

---

### Recording tips
- Recording se pehle check karo: `dig app.team1.test` → 10.7.19.102, aur dono backends chal rahe hain.
- Wi-Fi unstable ho to phone hotspot use karo — warna load balancing mein sirf A dikh sakta hai.
- Screen record: `Cmd + Shift + 5`. Terminal ka font bada kar lo (`Cmd +`).
- Dono log bolo — jaise Arun 0:00–2:50, Mayank 2:50–5:00.
