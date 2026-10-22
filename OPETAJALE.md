# Õpetajale: ühise kursuseserveri seadistus

Üks VPS kogu rühmale. Igal õpilasel on oma Linuxi kasutaja, kaust `/var/www/<kasutaja>`, alamdomeen `<kasutaja>.193.40.160.3.sslip.io` ja oma port API jaoks.

> Asenda `193.40.160.3.sslip.io` päris domeeniga kõigis failides.

## Kiire tee (umbes 15 min)

```bash
# 1. Põhiseadistus: nginx, rsync, nodejs, ufw, fail2ban, SSH ainult võtmetega
#    domeen (2. argument) jäta ära, siis kasutatakse <IP>.sslip.io
sudo ./server/seadista-server.sh <kooli-avalik-IP>

# 2. Õpilased CSV-st (eesnimi;perenimi;github_kasutaja), võtmed tulevad GitHubist
sudo ./server/lisa-opilased.sh opilased.csv
```

`lisa-opilased.sh` võib käivitada korduvalt: kui õpilane lisab võtme GitHubi hiljem, käivita uuesti. Tabel kasutajanimede, portide ja aadressidega asub failis `/root/opilased-tabel.txt`.

**Kooli IP ja fail2ban:** klassis on kõik õpilased ühe avaliku IP taga. Kui IP-d `ignoreip` alla ei pane, võivad mõned valed võtmed blokeerida tunniks terve klassi. Lahti blokeerimine käib käsuga `sudo fail2ban-client set sshd unbanip <IP>`.

**Hyper-V:** VM peab olema eraldi avalikus segmendis või VLAN-is, ilma marsruudita kooli sisevõrku ja hosti haldusliidesesse. Gen2 VM, Secure Boot mall *Microsoft UEFI Certificate Authority*.

Allolevad sammud kirjeldavad, mida skriptid teevad (4. kohtumise materjal).

## 1. Server ja DNS

- VM/VPS: Ubuntu 26.04 LTS, 4 vCPU, 8 GB RAM, 60 GB ketas (~40 õpilast)
- DNS: `193.40.160.3.sslip.io` A → IP ja `*.193.40.160.3.sslip.io` A → IP (wildcard)

## 2. Põhiseadistus

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y nginx rsync nodejs ufw
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

Keela SSH paroolisisselogimine (`/etc/ssh/sshd_config.d/10-kursus.conf`):

```
PasswordAuthentication no
PermitRootLogin prohibit-password
```

```bash
sudo systemctl reload ssh
```

## 3. Õpilase lisamine

`lisa-opilane.sh`:

```bash
#!/usr/bin/env bash
# Kasutus: sudo ./lisa-opilane.sh <kasutaja> "<ssh-ed25519 AAAA... kommentaar>"
set -euo pipefail
U="$1"; KEY="$2"

adduser --disabled-password --gecos "" "$U"
install -d -m 700 -o "$U" -g "$U" "/home/$U/.ssh"
echo "$KEY" > "/home/$U/.ssh/authorized_keys"
chown "$U:$U" "/home/$U/.ssh/authorized_keys"
chmod 600 "/home/$U/.ssh/authorized_keys"

install -d -m 755 -o "$U" -g "$U" "/var/www/$U"
echo "<h1>$U – ootab deploy'd</h1>" > "/var/www/$U/index.html"
chown "$U:$U" "/var/www/$U/index.html"

loginctl enable-linger "$U"        # kasutajateenused jooksevad ka väljalogituna
echo "Valmis: http://$U.193.40.160.3.sslip.io"
```

## 4. Nginx – kõik õpilased ühe konfiga

`/etc/nginx/sites-available/kursus`:

```nginx
# Õpilase API port (3. kohtumine). Lisa iga õpilase rida.
map $opilane $api_port {
    default  0;
    mari     3001;
    jaan     3002;
}

server {
    listen 80;
    server_name ~^(?<opilane>[a-z0-9-]+)\.193\.40\.160\.3\.sslip\.io$;

    root /var/www/$opilane;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        if ($api_port = 0) { return 503; }
        proxy_pass http://127.0.0.1:$api_port;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/kursus /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

Õpilased saavad logisid lugeda, kui lisad nad `adm` gruppi (`sudo usermod -aG adm <kasutaja>`). See on valikuline.

## 5. HTTPS (valikuline)

Wildcard-sertifikaat vajab DNS-väljakutset (`certbot certonly --manual --preferred-challenges dns -d '*.193.40.160.3.sslip.io'`) või DNS-pakkuja pluginat. Lihtsam on teha esimesed kohtumised HTTP-ga ja näidata HTTPS-i 4. kohtumisel oma domeeniga.

## Enne iga kohtumist

- [ ] Kõik õpilased on lisatud ja `http://<kasutaja>.193.40.160.3.sslip.io` vastab
- [ ] (3. kohtumine) pordid on `map`-is ja `nodejs` on paigaldatud: `node --version`
- [ ] `sudo apt update && sudo apt upgrade`
