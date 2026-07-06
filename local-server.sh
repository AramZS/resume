#!/usr/bin/env bash

PORT="${1:-3000}"
HOST="${HOST:-127.0.0.1}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$HOST" = "*********" ]; then
  HOST="localhost"
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is not installed or not in PATH."
  exit 1
fi

echo "Serving ${ROOT_DIR} at http://${HOST}:${PORT}"

node - "$PORT" "$HOST" "$ROOT_DIR" <<'NODE'
const http = require('http');
const fs = require('fs');
const path = require('path');

const [portArg, host, rootDir] = process.argv.slice(2);
const port = Number(portArg);

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.txt': 'text/plain; charset=utf-8'
};

const server = http.createServer((req, res) => {
  try {
    const requestPath = decodeURIComponent(req.url.split('?')[0]);
    const safePath = path.normalize(requestPath).replace(/^(\.\.[/\\])+/, '');
    let filePath = path.join(rootDir, safePath === '/' ? 'index.html' : safePath);

    if (!filePath.startsWith(rootDir)) {
      res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Forbidden');
      return;
    }

    if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Not Found');
        return;
      }

      const ext = path.extname(filePath).toLowerCase();
      const contentType = mimeTypes[ext] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(data);
    });
  } catch (error) {
    res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Internal Server Error');
  }
});

server.listen(port, host, () => {
  console.log(`Local server running at http://${host}:${port}`);
});
NODE
