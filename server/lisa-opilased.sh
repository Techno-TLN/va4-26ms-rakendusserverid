#!/usr/bin/env bash
# Lisab õpilased CSV-st. Võib käivitada korduvalt (olemasolevaid ei muuda, lisab puuduvad võtmed).
# Kasutus: sudo ./lisa-opilased.sh opilased.csv
# CSV (semikoolon, Exceli vaikimisi): eesnimi;perenimi;github_kasutaja
#   - päiserida on lubatud; github võib olla tühi (siis lisa võti hiljem käsitsi)
#   - SSH võtmed võetakse aadressilt https://github.com/<github_kasutaja>.keys
set -euo pipefail
export LC_ALL=C.UTF-8

CSV="${1:?Kasutus: sudo $0 opilased.csv}"
DOMEEN=$(cat /etc/kursus-domeen)
MAP=/etc/nginx/kursus-pordid.map
TABEL=/root/opilased-tabel.txt

trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<<"$1"; }
slug() { sed 'y/õäöüšžÕÄÖÜŠŽ/oaouszOAOUSZ/' <<<"$1" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9-'; }

declare -A kasutusel
while IFS=';' read -r ees pere gh _ || [[ -n "${ees:-}" ]]; do
  ees=$(trim "${ees//$'\r'/}"); ees="${ees#$'\xef\xbb\xbf'}"
  pere=$(trim "${pere//$'\r'/}"); gh=$(trim "${gh//$'\r'/}")
  [[ -z "$ees" || "${ees,,}" == "eesnimi" ]] && continue

  u=$(slug "$ees")
  [[ -n "${kasutusel[$u]:-}" ]] && u="$u$(slug "$pere" | cut -c1)"
  n=2; base="$u"; while [[ -n "${kasutusel[$u]:-}" ]]; do u="$base$n"; n=$((n+1)); done
  kasutusel[$u]=1

  if id "$u" &>/dev/null; then
    echo "olemas:   $u ($ees $pere)"
  else
    useradd -m -s /bin/bash -c "$ees $pere" "$u"
    usermod -p '*' "$u"        # parool puudub, aga SSH-võtmega sisselogimine töötab
    echo "lisatud:  $u ($ees $pere)"
  fi

  install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
  ak="/home/$u/.ssh/authorized_keys"
  touch "$ak"; chown "$u:$u" "$ak"; chmod 600 "$ak"
  if [[ -n "$gh" ]]; then
    if keys=$(curl -fsS --max-time 10 "https://github.com/$gh.keys") && [[ -n "$keys" ]]; then
      while IFS= read -r k; do
        [[ -n "$k" ]] && ! grep -qxF "$k" "$ak" && echo "$k" >> "$ak"
      done <<<"$keys"
    else
      echo "  HOIATUS: GitHubis '$gh' all võtmeid pole – õpilane peab võtme GitHubi lisama"
    fi
  else
    echo "  HOIATUS: GitHubi kasutaja puudub – lisa võti käsitsi faili $ak"
  fi

  if [[ ! -d "/var/www/$u" ]]; then
    install -d -m 755 -o "$u" -g "$u" "/var/www/$u"
    echo "<h1>$ees – ootab deploy'd</h1>" > "/var/www/$u/index.html"
    chown "$u:$u" "/var/www/$u/index.html"
  fi
  loginctl enable-linger "$u"
done < "$CSV"

# Pordid kõigile õpilastele (stabiilne: port = 2000 + UID)
: > "$MAP"
printf '%-14s %-6s %s\n' KASUTAJA PORT AADRESS > "$TABEL"
while IFS=: read -r u _ uid _ gecos _; do
  (( uid >= 1001 && uid < 60000 )) && [[ -d "/var/www/$u" ]] || continue
  port=$((2000 + uid))
  echo "    $u $port;" >> "$MAP"
  printf '%-14s %-6s http://%s.%s   (%s)\n' "$u" "$port" "$u" "$DOMEEN" "${gecos%%,*}" >> "$TABEL"
done < <(getent passwd)

nginx -t && systemctl reload nginx
echo; cat "$TABEL"
echo; echo "Tabel salvestatud: $TABEL"
