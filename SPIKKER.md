# Spikker

## URL-i osad

```
https://mari.193.40.160.3.sslip.io:443/api/notes?limit=5#top
└─┬─┘   └────────┬───────────┘└┬┘└───┬───┘└──┬──┘└┬┘
skeem          host          port   tee   päring  ankur
```

## HTTP

HTTP päring ja vastus on tekst:

```
GET /api/notes HTTP/1.1             ← meetod, tee, versioon
Host: mari.193.40.160.3.sslip.io        ← päised
Accept: application/json

HTTP/1.1 200 OK                     ← staatuskood
Content-Type: application/json

[{"id":1,"text":"Tere"}]            ← keha (body)
```

### Meetodid

| Meetod | Tähendus | Näide |
|---|---|---|
| `GET` | Loe | `GET /api/notes` |
| `POST` | Loo uus | `POST /api/notes` + JSON keha |
| `PUT` | Asenda tervikuna | `PUT /api/notes/3` |
| `PATCH` | Muuda osaliselt | `PATCH /api/notes/3` |
| `DELETE` | Kustuta | `DELETE /api/notes/3` |

### Staatuskoodid

| Kood | Tähendus | Millal näed |
|---|---|---|
| 200 OK | Õnnestus | Tavaline vastus |
| 201 Created | Loodi | Pärast `POST` |
| 204 No Content | Õnnestus, keha pole | Pärast `DELETE` |
| 301 / 308 | Püsiv ümbersuunamine | http → https |
| 400 Bad Request | Vigane päring | Vigane JSON |
| 401 / 403 | Pole sisse logitud / pole õigust | |
| 404 Not Found | Ei leitud | Vale tee või puuduv fail |
| 500 | Rakenduse viga | Vaata rakenduse logi |
| 502 Bad Gateway | Nginx ei saa rakenduseni | Rakendus ei jookse või port on vale |
| 504 Gateway Timeout | Rakendus ei vasta õigel ajal | |

Kokkuvõte: **4xx tähendab, et viga on kliendi poolel, 5xx tähendab, et viga on serveri poolel.**

### Olulised päised

`Host`, `Content-Type`, `Accept`, `Authorization`, `Cache-Control`, `Location` (ümbersuunamisel), `Set-Cookie`.

## REST API põhimõtted

- **Ressurss** on nimisõna mitmuses: `/api/notes`, `/api/notes/3`
- **Tegevuse** määrab meetod (vt tabel ülal), mitte URL. Vale: `/api/deleteNote?id=3`
- Andmed liiguvad tavaliselt **JSON**-is
- **Olekuta:** iga päring sisaldab kogu vajaliku info (nt token päises)
- Vastuse tulemust näitab **staatuskood**

## curl

```bash
curl -i https://mari.193.40.160.3.sslip.io/                 # -i näitab ka päiseid
curl -I https://mari.193.40.160.3.sslip.io/                 # ainult päised (HEAD)
curl https://mari.193.40.160.3.sslip.io/api/notes
curl -X POST -H "Content-Type: application/json" \
     -d '{"text":"uus märge"}' https://mari.193.40.160.3.sslip.io/api/notes
curl -X DELETE https://mari.193.40.160.3.sslip.io/api/notes/2
curl -v https://…                                        # kogu TLS ja HTTP vestlus
```

> Windows PowerShellis kasuta `curl.exe` (mitte `curl`, mis on `Invoke-WebRequest` alias).

## DNS

| Kirje | Tähendus |
|---|---|
| `A` | nimi → IPv4 |
| `AAAA` | nimi → IPv6 |
| `CNAME` | nimi → teine nimi |
| `MX` | e-posti server |
| `TXT` | vaba tekst (SPF, domeeni kinnitus) |

```bash
nslookup mari.193.40.160.3.sslip.io
dig +short mari.193.40.160.3.sslip.io     # Linux/macOS
```

## Pordid

| Port | Teenus |
|---|---|
| 22 | SSH |
| 80 | HTTP |
| 443 | HTTPS |
| 3000+ | Rakendusserverid (ainult `127.0.0.1`) |

## SSH ja rsync

```bash
ssh-keygen -t ed25519 -C "eesnimi@kursus"     # loo võtmepaar (~/.ssh/id_ed25519 + .pub)
cat ~/.ssh/id_ed25519.pub                     # AVALIK võti – seda võib jagada
ssh mari@193.40.160.3.sslip.io                    # sisselogimine
scp fail.txt mari@193.40.160.3.sslip.io:~/        # üks fail üles
rsync -avz --delete --chmod=D755,F644 ./public/ mari@193.40.160.3.sslip.io:/var/www/mari/
rsync -avzn --delete --chmod=D755,F644 ./public/ …              # -n = proovisõit, ei muuda midagi
```

**Privaatvõtit (`id_ed25519`, ilma `.pub`-ta) ei saadeta kunagi kellelegi.** GitHub Secretisse läheb eraldi, ainult deploy jaoks loodud võti.

## Linux

```bash
pwd; ls -la; cd /var/www          # kus olen, mis siin on, liigu
cat fail; less fail; tail -f logi # vaata faili / jälgi logi
mkdir kaust; cp a b; mv a b; rm a
chmod 644 fail; chown mari:www-data fail
whoami; id; df -h; free -h; ss -tlnp
```

## systemd ja logid

```bash
systemctl status nginx
sudo systemctl restart nginx
journalctl -u nginx -n 50

# kasutaja teenused (3. kohtumine)
systemctl --user status notes
systemctl --user restart notes
journalctl --user -u notes -f
```

## Nginx

```bash
sudo nginx -t                       # kontrolli konfiguratsiooni ENNE reload'i
sudo systemctl reload nginx
/etc/nginx/sites-available/         # konfid
/etc/nginx/sites-enabled/           # aktiveeritud (symlink)
/var/log/nginx/access.log, error.log
```

## Git

```bash
git clone <url>
git switch -c feature/pealkiri     # uus haru
git add . && git commit -m "Muuda pealkirja"
git push -u origin feature/pealkiri  # → GitHubis "Compare & pull request"
git switch main && git pull
```

## CI vs CD

- **CI (Continuous Integration):** igal PR-il käivituvad kontrollid. Kas kood on korras?
- **CD (Continuous Deployment):** pärast `main`-i merge'i paigaldatakse muudatus automaatselt serverisse.
