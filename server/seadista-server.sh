#!/usr/bin/env bash
# =============================================================================
# K-TVA4-26MS kursuseserveri seadistus (Ubuntu Server 24.04 / 26.04 LTS)
#
# Eeldus: Ubuntu baasinstall tehtud, OpenSSH server paigaldatud ja sinu
#         (admin-kasutaja) SSH-võti töötab. Skript keelab paroolisisselogimise!
#
# Kasutus:
#   sudo ./seadista-server.sh <kooli-avalik-IP> [domeen]
#
#   kooli-avalik-IP  IP, mille tagant klass internetti läheb. fail2ban ja
#                    OpenSSH ei blokeeri seda (38 õpilast ühe NAT-i taga).
#                    Kui IP-d pole, anna "-".
#   domeen           vaikimisi <serveri-avalik-IP>.sslip.io
#
# Skripti võib käivitada korduvalt.
# =============================================================================
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Käivita sudo-ga."; exit 1; }
KOOLI_IP="${1:?Kasutus: sudo $0 <kooli-avalik-IP|-> [domeen]}"
[[ "$KOOLI_IP" == "-" ]] && KOOLI_IP=""

LOG=/root/kursus-seadistus.log
exec > >(tee -a "$LOG") 2>&1
echo "=== $(date -Is) seadistus algab ==="

ADMIN_USER="${SUDO_USER:-}"
if [[ -z "$ADMIN_USER" || "$ADMIN_USER" == "root" ]]; then
  ADMIN_USER=$(getent passwd 1000 | cut -d: -f1 || true)
fi
ADMIN_UID=$(id -u "$ADMIN_USER" 2>/dev/null || echo 1000)

# Ohutuskontroll: admin peab saama võtmega sisse, enne kui paroolid keelame
if [[ -n "$ADMIN_USER" && ! -s "/home/$ADMIN_USER/.ssh/authorized_keys" && ! -s /root/.ssh/authorized_keys ]]; then
  echo "VIGA: admin-kasutajal ($ADMIN_USER) ega root'il pole SSH-võtit."
  echo "Lisa enne võti (ssh-copy-id), muidu jääd pärast skripti serverist välja."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo ">> 1/9 Paketid"
apt-get update
apt-get -y full-upgrade
apt-get -y install nginx rsync ufw fail2ban python3-systemd unattended-upgrades \
                   curl nodejs git htop
if [[ "$(systemd-detect-virt || true)" == "microsoft" ]]; then
  apt-get -y install linux-tools-virtual linux-cloud-tools-virtual || \
    echo "  (Hyper-V tööriistad jäid paigaldamata – pole kriitiline)"
fi

PUBLIC_IP=$(curl -4 -fsS --max-time 5 https://ifconfig.me || hostname -I | awk '{print $1}')
DOMEEN="${2:-$PUBLIC_IP.sslip.io}"

echo ">> 2/9 Ajavöönd ja hostinimi"
timedatectl set-timezone Europe/Tallinn
hostnamectl set-hostname kursus-tva4

echo ">> 3/9 Automaatsed turvauuendused"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
cat > /etc/apt/apt.conf.d/52kursus-unattended <<'EOF'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
EOF

echo ">> 4/9 SSH: ainult võtmed, klassi jaoks rohkem samaaegseid ühendusi"
cat > /etc/ssh/sshd_config.d/10-kursus.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
MaxAuthTries 4
X11Forwarding no
AllowAgentForwarding no
# Klass (~40 õpilast) ühendub korraga ühe NAT-IP tagant
MaxStartups 80:30:200
EOF
# OpenSSH 9.8+ karistab IP-d vigaste sisselogimiste eest – vabasta kooli IP
if [[ -n "$KOOLI_IP" ]] && sshd -T 2>/dev/null | grep -qi '^persourcepenalties'; then
  echo "PerSourcePenaltyExemptList $KOOLI_IP" >> /etc/ssh/sshd_config.d/10-kursus.conf
fi
sshd -t
systemctl restart ssh

echo ">> 5/9 Tulemüür (ufw)"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH            # NB: mitte 'limit' – klass on ühe NAT-IP taga
ufw allow 'Nginx Full'
ufw --force enable

echo ">> 6/9 fail2ban"
cat > /etc/fail2ban/jail.d/kursus.local <<EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 6
ignoreip = 127.0.0.1/8 ::1 ${KOOLI_IP}

[sshd]
enabled = true
backend = systemd
EOF
systemctl enable fail2ban
systemctl restart fail2ban

echo ">> 7/9 Piirangud: iga õpilane max 400 MB RAM, 1 CPU tuum, 200 protsessi"
mkdir -p /etc/systemd/system/user-.slice.d "/etc/systemd/system/user-${ADMIN_UID}.slice.d"
cat > /etc/systemd/system/user-.slice.d/50-kursus.conf <<'EOF'
[Slice]
MemoryMax=400M
CPUQuota=100%
TasksMax=200
EOF
cat > "/etc/systemd/system/user-${ADMIN_UID}.slice.d/50-admin.conf" <<'EOF'
# Admin-kasutajale piiranguid ei rakendata
[Slice]
MemoryMax=infinity
CPUQuota=
TasksMax=infinity
EOF
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/50-kursus.conf <<'EOF'
[Journal]
SystemMaxUse=1G
EOF
systemctl daemon-reload
systemctl restart systemd-journald

echo ">> 8/9 Nginx"
echo "$DOMEEN" > /etc/kursus-domeen
touch /etc/nginx/kursus-pordid.map
echo "server_tokens off;" > /etc/nginx/conf.d/kursus-turve.conf
REGEX=$(printf '%s' "$DOMEEN" | sed 's/\./\\\\./g')
cat > /etc/nginx/sites-available/kursus <<'EOF'
# Õpilase API port: /etc/nginx/kursus-pordid.map (genereerib lisa-opilased.sh)
map $opilane $api_port {
    default 0;
    include /etc/nginx/kursus-pordid.map;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    default_type text/plain;
    return 200 "K-TVA4-26MS kursuseserver\n";
}

server {
    listen 80;
    listen [::]:80;
    server_name ~^(?<opilane>[a-z0-9-]+)\.__REGEX__$;

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
EOF
sed -i "s|__REGEX__|$REGEX|" /etc/nginx/sites-available/kursus
ln -sf /etc/nginx/sites-available/kursus /etc/nginx/sites-enabled/kursus
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo ">> 9/9 Kontroll"
sleep 1
curl -fsS http://127.0.0.1/ || echo "HOIATUS: nginx ei vasta"
ufw status | head -n 8
fail2ban-client status sshd | tail -n 3
echo "Node.js: $(node --version)"

cat <<EOF

=====================================================================
 Valmis.
   Avalik IP:   $PUBLIC_IP
   Domeen:      $DOMEEN  (õpilased: http://<kasutaja>.$DOMEEN)
   Kooli IP:    ${KOOLI_IP:-(määramata – fail2ban võib klassi blokeerida!)}
   Logi:        $LOG

 Enne sulgemist: ava UUS terminal ja kontrolli, et saad võtmega sisse:
   ssh $ADMIN_USER@$PUBLIC_IP

 Järgmine samm:
   sudo ./lisa-opilased.sh opilased.csv
=====================================================================
EOF
