# K-TVA4-26MS · Rakendusserverid ja automaatne deploy

Kursus 12 kontakttundi (4 kohtumist × 3 tundi) + iseseisev töö.

## Kursuse eesmärk

Õpilane saab aru, kuidas veebirakendus jõuab arendaja arvutist päris serverisse ja kasutajani, ning oskab selle teekonna ise automatiseerida:

**kood GitHubis → Pull Request → GitHub Actions → Linux server → kasutaja brauser**

Kursuse lõpuks õpilane:

1. selgitab, mis on rakendusserver, veebiserver ja reverse proxy ning kuidas HTTP päring nende vahel liigub;
2. kasutab Giti harusid ja Pull Requeste meeskonnatöö vormina;
3. logib SSH-võtmega Linux serverisse ja teeb käsitsi deploy (`rsync`);
4. seadistab GitHub Actionsi, mis kontrollib PR-i (CI) ja paigaldab `main` haru serverisse (CD);
5. paigaldab lihtsa REST API rakenduse (Node.js) teenusena Nginxi taha;
6. teab turvalise deploy põhimõtteid: eraldi kasutaja, ainult võtmed, *secrets*, *known_hosts*, HTTPS.

## Ajakava

| # | Teema | Tulemus | Materjal |
|---|---|---|---|
| 1 | Rakendusserver, HTTP, Git + PR, GitHub Pages, SSH, käsitsi deploy | Leht on live GitHub Pagesis **ja** ühises serveris | [tunnid/01.md](tunnid/01.md) |
| 2 | CI/CD GitHub Actionsiga | PR-i merge uuendab serveris oleva lehe automaatselt | [tunnid/02.md](tunnid/02.md) |
| 3 | Rakendusserver päriselt: Node.js REST API + systemd + Nginx | Oma API töötab aadressil `nimi.kursus…/api/` | [tunnid/03.md](tunnid/03.md) |
| 4 | Oma server, HTTPS, Docker (valik), lõputöö esitlus | Iseseisvalt deploy'tud projekt | [tunnid/04.md](tunnid/04.md) |

## Repo sisu

```
README.md            ← see fail
RAKENDUSSERVER.md    ← mis on rakendusserver, millised tüübid on olemas
SPIKKER.md           ← HTTP, REST, curl, DNS, SSH, Linux, Git, Nginx
tunnid/              ← iga kohtumise plaan, harjutused ja kodutöö
naide/               ← näidisrakendus ja workflow'd, mida kopeerida
OPETAJALE.md         ← ühise kursuseserveri seadistus
server/              ← serveri seadistus- ja õpilaste lisamise skriptid
```

## Mida on vaja

- GitHubi konto
- Git ja VS Code (või muu redaktor)
- terminal, kus on `ssh` (Windows 10/11 PowerShell sisaldab seda), soovi korral WSL
- Node.js (alates 3. kohtumisest)

## Kursusel tehtud valikud

- **Server:** esimesed kolm kohtumist kasutatakse ühist kursuseserverit (Ubuntu 26.04 LTS), kus igal õpilasel on oma kasutaja ja alamdomeen. Seetõttu ei pea keegi alguses serverit ostma. Oma VPS (Zone, Hetzner vms) on 4. kohtumise valikteema.
- **Rakendusserveri tüübid:** praktiliselt teeme staatilise saidi (Nginx) ja Node.js API. Python (Gunicorn/Uvicorn) on lisaülesanne. Ülevaade: [RAKENDUSSERVER.md](RAKENDUSSERVER.md).

## Välised juhendid

| Teema | Link |
|---|---|
| Git harjutamine brauseris | https://learngitbranching.js.org/?locale=et_EE |
| Git raamat | https://git-scm.com/book/en/v2 |
| GitHub Actions | https://docs.github.com/en/actions |
| GitHub Pages + Actions | https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages |
| SSH-võtme loomine | https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent |
| HTTP (MDN) | https://developer.mozilla.org/en-US/docs/Web/HTTP |
| REST (MDN sõnastik) | https://developer.mozilla.org/en-US/docs/Glossary/REST |
| Ubuntu Server | https://documentation.ubuntu.com/server/ |
| Nginx | https://nginx.org/en/docs/ |
| Let's Encrypt / Certbot | https://certbot.eff.org/ |
| Node.js | https://nodejs.org/en/learn |
