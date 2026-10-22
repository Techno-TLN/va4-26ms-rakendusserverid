// Lihtne REST API ilma sõltuvusteta (ainult Node.js sisseehitatud moodulid).
// Käivitamine: node server.js   (port: keskkonnamuutuja PORT, vaikimisi 3000)
const http = require('node:http');

const PORT = Number(process.env.PORT) || 3000;

// Andmed hoitakse mälus – taaskäivitusel kaovad (vt 3. kohtumise kodutöö)
let notes = [{ id: 1, text: 'Tere, maailm!' }];
let nextId = 2;

function send(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data));
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      try { resolve(JSON.parse(body || '{}')); } catch (e) { reject(e); }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const { pathname } = new URL(req.url, 'http://localhost');
  const idMatch = pathname.match(/^\/api\/notes\/(\d+)$/);
  console.log(`${new Date().toISOString()} ${req.method} ${pathname}`);

  // GET /api/health – tervisekontroll deploy jaoks
  if (pathname === '/api/health' && req.method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  // GET /api/notes – kõik märkmed
  if (pathname === '/api/notes' && req.method === 'GET') {
    return send(res, 200, notes);
  }

  // POST /api/notes – uus märge  { "text": "..." }
  if (pathname === '/api/notes' && req.method === 'POST') {
    try {
      const { text } = await readJson(req);
      if (!text) return send(res, 400, { error: 'väli "text" puudub' });
      const note = { id: nextId++, text: String(text) };
      notes.push(note);
      return send(res, 201, note);
    } catch {
      return send(res, 400, { error: 'vigane JSON' });
    }
  }

  // GET /api/notes/:id – üks märge
  if (idMatch && req.method === 'GET') {
    const note = notes.find((n) => n.id === Number(idMatch[1]));
    return note ? send(res, 200, note) : send(res, 404, { error: 'ei leitud' });
  }

  // DELETE /api/notes/:id – kustuta
  if (idMatch && req.method === 'DELETE') {
    const before = notes.length;
    notes = notes.filter((n) => n.id !== Number(idMatch[1]));
    if (notes.length === before) return send(res, 404, { error: 'ei leitud' });
    res.writeHead(204);
    return res.end();
  }

  send(res, 404, { error: 'ei leitud' });
});

// 127.0.0.1 = kättesaadav ainult samast masinast; internetti avab Nginx
server.listen(PORT, '127.0.0.1', () => {
  console.log(`API kuulab http://127.0.0.1:${PORT}`);
});
