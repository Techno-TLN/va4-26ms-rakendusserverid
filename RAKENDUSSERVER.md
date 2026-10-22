# Mis on rakendusserver?

## Lühidalt

**Rakendusserver on programm, mis käivitab rakenduse koodi ja vastab HTTP päringutele.** Ta ei saada ainult valmis faile, vaid arvutab vastuse: loeb andmebaasi, kontrollib sisselogimist, tagastab JSON-i.

Ajalooliselt tähendas "application server" suurt Java platvormi (WebSphere, JBoss, WebLogic), mis majutas korraga mitut rakendust. Tänapäeval kasutatakse sõna laiemalt. Rakendusserver on **protsess, kus sinu rakendus jookseb**, näiteks Node.js protsess, Gunicorn Pythonile, PHP-FPM või Spring Booti sisseehitatud Tomcat. Sageli on see konteineri sees.

## Tüüpiline ülesehitus

```
Brauser / mobiilirakendus / teine süsteem
        │  HTTPS päring:  GET https://mari.193.40.160.3.sslip.io/api/notes
        ▼
DNS  ──►  nimi → IP-aadress
        ▼
Veebiserver / reverse proxy  (Nginx)
   • HTTPS (TLS-sertifikaat)
   • staatilised failid (HTML, CSS, pildid)  ──► vastab ise
   • /api/...  ──► edastab edasi (proxy_pass)
        ▼
Rakendusserver  (Node.js, Gunicorn, PHP-FPM, Kestrel, Tomcat…)
   • sinu kood: marsruudid, loogika, autentimine
        ▼
Andmebaas / failid / teised API-d
```

**Miks Nginx on rakenduse ees?** Ta tegeleb HTTPS-iga, serveerib staatilisi faile kiiresti, piirab koormust ja võimaldab ühes serveris mitut rakendust (alamdomeenid, teed). Rakendusserver kuulab ainult `127.0.0.1` pordil (nt 3000) ega ole internetist otse kättesaadav.

## Rakendusserverite tüübid

| Tüüp | Näited | Kuidas jookseb | Kursusel |
|---|---|---|---|
| **Staatiline sait** | HTML/CSS/JS, Hugo, Vite build | Rakendusserverit pole, Nginx serveerib faile | ✅ 1.–2. kohtumine |
| **Node.js** | Express, Fastify, Next.js | Oma protsess pordil, systemd või PM2 hoiab käigus | ✅ 3. kohtumine |
| **Python** | Flask, Django (WSGI) → Gunicorn; FastAPI (ASGI) → Uvicorn | Gunicorn/Uvicorn protsess, Nginx ees | ➕ lisaülesanne |
| **PHP** | Laravel, WordPress | PHP-FPM, mida Nginx kutsub iga päringu jaoks | 📖 teooria |
| **Java** | Spring Boot (sisseehitatud Tomcat), Tomcat, WildFly | JVM protsess | 📖 teooria |
| **.NET** | ASP.NET Core (Kestrel), IIS | Kestrel protsess, ees Nginx või IIS | 📖 teooria |
| **Konteiner** | Docker, Podman | Mis tahes eelmine, pakitud image'isse | ➕ 4. kohtumine |

## Kus server asub (majutusmudelid)

| Mudel | Mida haldad ise | Näited |
|---|---|---|
| **Staatiline majutus** | Ainult faile | GitHub Pages, Cloudflare Pages |
| **PaaS** | Koodi | Render, Azure App Service, Heroku |
| **IaaS / VPS** | Kogu serverit: OS, uuendused, tulemüür | Zone CloudServer, Hetzner, DigitalOcean |
| **Konteinerplatvorm** | Image'it ja konfiguratsiooni | Kubernetes, Azure Container Apps |
| **Serverless** | Üksikuid funktsioone | AWS Lambda, Cloudflare Workers |

Kursusel valime **VPS-i**, sest seal on kõik kihid näha. PaaS teeb sama töö ära, aga peidab selle.

## Loe lisaks

- MDN – kuidas veeb töötab: https://developer.mozilla.org/en-US/docs/Learn_web_development/Getting_started/Web_standards/How_the_web_works
- Nginx reverse proxy: https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/
- The Twelve-Factor App (kuidas ehitada deploy'tavat rakendust): https://12factor.net/
