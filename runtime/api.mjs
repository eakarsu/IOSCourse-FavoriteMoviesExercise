import crypto from 'node:crypto';
import http from 'node:http';
import { runAiAttempt } from './attempts.mjs';
import { literal, query } from './db.mjs';
import { openRouter } from './provider.mjs';

const port = Number(process.env.BACKEND_PORT);
const allowedOrigin = `http://127.0.0.1:${process.env.FRONTEND_PORT}`;
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const json = (response, status, payload) => {
  const body = JSON.stringify(payload);
  response.writeHead(status, { 'Cache-Control': 'no-store', 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body), 'Access-Control-Allow-Origin': allowedOrigin, 'X-Content-Type-Options': 'nosniff' });
  response.end(body);
};
const readBody = request => new Promise((resolve, reject) => {
  let text = '';
  request.on('data', chunk => { text += chunk; if (text.length > 16_384) reject(Object.assign(new Error('request too large'), { status: 413 })); });
  request.on('end', () => { try { resolve(JSON.parse(text || '{}')); } catch { reject(Object.assign(new Error('invalid JSON'), { status: 400 })); } });
  request.on('error', reject);
});
function verify(password, stored) {
  const [kind, salt, digest] = String(stored).split('$');
  if (kind !== 'scrypt' || !salt || !digest) return false;
  const candidate = crypto.scryptSync(password, salt, 32); const expected = Buffer.from(digest, 'hex');
  return candidate.length === expected.length && crypto.timingSafeEqual(candidate, expected);
}
function actor(request) {
  const token = String(request.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!token) return null;
  const row = query(`SELECT u.id,u.email,u.display_name,u.role FROM runtime_sessions s JOIN runtime_users u ON u.id=s.user_id WHERE s.token_hash=${literal(sha(token))} AND s.expires_at>NOW() AND u.active=TRUE LIMIT 1`, { rows: true });
  if (!row) return null;
  const [id, email, displayName, role] = row.split('\t'); return { id, email, displayName, role };
}
const server = http.createServer(async (request, response) => {
  const started = Date.now();
  const url = new URL(request.url || '/', `http://127.0.0.1:${port}`);
  response.on('finish', () => console.log(JSON.stringify({ level: 'info', method: request.method, path: url.pathname, status: response.statusCode, durationMs: Date.now() - started })));
  if (request.method === 'OPTIONS') { response.writeHead(204, { 'Access-Control-Allow-Origin': allowedOrigin, 'Access-Control-Allow-Headers': 'Authorization, Content-Type', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS' }); response.end(); return; }
  try {
    if (request.method === 'GET' && url.pathname === '/api/health/ready') { query('SELECT 1'); json(response, 200, { status: 'ready', database: 'connected' }); return; }
    if (request.method === 'POST' && url.pathname === '/api/auth/login') {
      const body = await readBody(request); const email = String(body.email || '').trim().toLowerCase(); const password = String(body.password || '');
      const row = query(`SELECT id,email,password_hash,display_name,role FROM runtime_users WHERE email=${literal(email)} AND active=TRUE LIMIT 1`, { rows: true });
      if (!row) { json(response, 401, { error: { code: 'INVALID_CREDENTIALS' } }); return; }
      const [id, userEmail, passwordHash, displayName, role] = row.split('\t');
      if (!verify(password, passwordHash)) { json(response, 401, { error: { code: 'INVALID_CREDENTIALS' } }); return; }
      const token = crypto.randomBytes(32).toString('base64url');
      query(`INSERT INTO runtime_sessions(token_hash,user_id,expires_at) VALUES(${literal(sha(token))},${literal(id)}::uuid,NOW()+INTERVAL '8 hours')`);
      json(response, 200, { token, user: { id, email: userEmail, displayName, role } }); return;
    }
    if (request.method === 'GET' && url.pathname === '/api/auth/me') {
      const user = actor(request); json(response, user ? 200 : 401, user ? { user } : { error: { code: 'UNAUTHORIZED' } }); return;
    }
    if (request.method === 'POST' && url.pathname === '/api/runtime-ai/movie-library-readiness') {
      const user = actor(request); if (!user) { json(response, 401, { error: { code: 'UNAUTHORIZED' } }); return; }
      const body = await readBody(request); const workflowSummary = String(body.workflowSummary || '').trim();
      if (workflowSummary.length < 20 || workflowSummary.length > 2000) { json(response, 400, { error: { code: 'VALIDATION_ERROR' } }); return; }
      const result = await runAiAttempt({ user, workflowSummary, invoke: openRouter });
      json(response, 200, result); return;
    }
    json(response, 404, { error: { code: 'NOT_FOUND' } });
  } catch (error) {
    console.error(JSON.stringify({ level: 'error', event: 'request_failed', path: url.pathname, code: error.code || 'INTERNAL_ERROR' }));
    json(response, error.status || 500, { error: { code: error.code || 'INTERNAL_ERROR' } });
  }
});
server.listen(port, '127.0.0.1', () => console.log(`Favorite Movies runtime API listening on 127.0.0.1:${port}`));
