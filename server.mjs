import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname);
const PORT = Number(process.env.PORT || 3000);
const HOST = process.env.HOST || '0.0.0.0';

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.xml': 'application/xml; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
  '.md': 'text/markdown; charset=utf-8',
};

function resolveSafePath(urlPath) {
  let cleanPath = decodeURIComponent((urlPath || '/').split('?')[0]);
  if (cleanPath === '/' || cleanPath === '') {
    cleanPath = '/index.html';
  } else if (cleanPath === '/admin' || cleanPath === '/admin/') {
    cleanPath = '/admin-web/index.html';
  } else if (cleanPath === '/admin-web' || cleanPath === '/admin-web/') {
    cleanPath = '/admin-web/index.html';
  }

  const candidate = path.resolve(ROOT, '.' + cleanPath);
  if (candidate !== ROOT && !candidate.startsWith(ROOT + path.sep)) {
    return null;
  }
  return candidate;
}

const server = http.createServer(async (req, res) => {
  try {
    const filePath = resolveSafePath(req.url);
    if (!filePath) {
      res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Forbidden');
      return;
    }

    let target = filePath;
    let stat = await fs.stat(target).catch(() => null);
    if (stat && stat.isDirectory()) {
      target = path.join(target, 'index.html');
      stat = await fs.stat(target).catch(() => null);
    }

    if (!stat || !stat.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end('<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><title>404 | DAZREVO</title><body style="font-family:sans-serif;background:#090B0E;color:#F5F2EB;display:grid;place-items:center;min-height:100vh;margin:0"><main style="text-align:center"><h1>404</h1><p>الصفحة غير موجودة</p><a href="/" style="color:#DFBE7D">العودة للرئيسية</a></main></body></html>');
      return;
    }

    const ext = path.extname(target).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    const content = await fs.readFile(target);
    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-cache',
    });
    res.end(content);
  } catch {
    res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Internal Server Error');
  }
});

server.listen(PORT, HOST, () => {
  console.log(`DAZREVO preview server listening on http://${HOST}:${PORT}`);
});
