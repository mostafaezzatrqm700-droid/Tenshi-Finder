'use strict';

const http = require('node:http');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const GAME_PLACE = 107778070777162;
const TTL_MS = 90_000;
const MAX_BODY = 96 * 1024;

function sha(value) {
  return crypto.createHash('sha256').update(String(value || '')).digest();
}
function safeEqual(a, b) {
  const left = sha(a), right = sha(b);
  return crypto.timingSafeEqual(left, right);
}
function validId(value) {
  return typeof value === 'string' && /^[A-Za-z0-9_-]{8,160}$/.test(value);
}
function cleanText(value, max = 90) {
  return typeof value === 'string'
    ? value.replace(/[\x00-\x1f\x7f]/g, '').slice(0, max)
    : '';
}
function validNumber(value, max = 1e35) {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0 && value <= max;
}
function cleanEgg(value) {
  if (!value || !validId(value.uid) || !cleanText(value.name) ||
      !validNumber(value.rate) || value.rate <= 0 || !validNumber(value.rank, 100)) return null;
  return {
    uid: value.uid,
    name: cleanText(value.name),
    category: cleanText(value.category),
    rarity: cleanText(value.rarity),
    rank: value.rank,
    rate: value.rate,
    scale: validNumber(value.scale, 1e6) ? value.scale : null,
    weight: validNumber(value.weight) ? value.weight : null,
    icon: typeof value.icon === 'string' && /^rbxassetid:\/\/\d{1,20}$/.test(value.icon) ? value.icon : '',
    area: cleanText(value.area),
    mutations: cleanText(value.mutations, 180),
    estimated: value.estimated === true,
    traitsKnown: value.traitsKnown === true,
    visualId: value.visualId === true,
    source: value.source === 'event' ? 'event' : 'field'
  };
}
function createServer({ now = Date.now } = {}) {

  const snapshots = new Map();
  const reservations = new Map();
  const rate = new Map();

  function send(res, status, body) {
    res.writeHead(status, {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff'
    });
    res.end(JSON.stringify(body));
  }
  function authorized(req) { return true; }
  function clean() {
    const t = now();
    for (const [key, snap] of snapshots) if (snap.expiresAt <= t) snapshots.delete(key);
    for (const [key, item] of reservations) if (item.expiresAt <= t) reservations.delete(key);
    for (const [key, item] of rate) if (t - item.start >= 60_000) rate.delete(key);
  }
  function limited(req, bucket, max) {
    const ip = String(req.headers['cf-connecting-ip'] || req.socket.remoteAddress || 'unknown');
    const key = bucket + ':' + ip;
    let item = rate.get(key);
    if (!item) { item = { start: now(), count: 0 }; rate.set(key, item); }
    item.count += 1;
    return item.count <= max;
  }
  async function readJson(req, maxBytes = MAX_BODY) {
    let size = 0;
    const chunks = [];
    for await (const chunk of req) {
      size += chunk.length;
      if (size > maxBytes) throw Object.assign(new Error('Request too large'), { status: 413 });
      chunks.push(chunk);
    }
    try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); }
    catch { throw Object.assign(new Error('Invalid JSON'), { status: 400 }); }
  }
  function ranked() {
    const rows = [];
    for (const snap of snapshots.values()) {
      for (const egg of snap.eggs) rows.push({
        ...egg, placeId: snap.placeId, jobId: snap.jobId,
        seenAt: snap.updatedAt, expiresAt: snap.expiresAt
      });
    }
    rows.sort((a, b) => b.rate - a.rate || a.jobId.localeCompare(b.jobId) || a.uid.localeCompare(b.uid));
    return rows;
  }

  return http.createServer(async (req, res) => {
    try {
      clean();
      const url = new URL(req.url, 'http://localhost');
      if (req.method === 'GET' && url.pathname === '/health') {
        return send(res, 200, { ok: true, service: 'independent-finder', version: '0.1.0' });
      }
      if (!authorized(req)) return send(res, 401, { error: 'Room key required' });
      if (req.method === 'POST' && url.pathname === '/v1/report') {
        if (!limited(req, 'report', 90)) return send(res, 429, { error: 'Too many reports' });
        if (!String(req.headers['content-type'] || '').includes('application/json'))
          return send(res, 415, { error: 'JSON required' });
        const report = await readJson(req);
        if (!report || report.placeId !== GAME_PLACE || !validId(report.jobId) ||
            !validId(report.reporterId) || !Array.isArray(report.eggs) || report.eggs.length > 40)
          return send(res, 400, { error: 'Invalid report' });
        const eggs = new Map();
        for (const raw of report.eggs) {
          const egg = cleanEgg(raw);
          if (egg) eggs.set(egg.uid, egg);
        }
        const best = [...eggs.values()].sort((a, b) => b.rate - a.rate).slice(0, 15);
        const receivedAt = now();
        const resetAt = Number.isFinite(report.resetAt) &&
          report.resetAt > receivedAt && report.resetAt <= receivedAt + 305_000
          ? report.resetAt : receivedAt + TTL_MS;
        snapshots.set(report.jobId, {
          placeId: GAME_PLACE, jobId: report.jobId, updatedAt: receivedAt,
          expiresAt: resetAt, eggs: best
        });
        return send(res, 200, {
          ok: true, accepted: best.length,
          expiresIn: Math.max(0, (resetAt - receivedAt) / 1000), resetAt
        });
      }
      if (req.method === 'GET' && url.pathname === '/v1/eggs') {
        if (!limited(req, 'eggs', 360)) return send(res, 429, { error: 'Too many requests' });
        const premium = url.searchParams.get('tier') === 'premium' ||
          Boolean(req.headers['x-nyx-viewer']);
        const placeId = Number(url.searchParams.get('placeId') || GAME_PLACE);
        if (placeId !== GAME_PLACE) return send(res, 400, { error: 'Unsupported place' });
        const minRate = Math.max(0, Number(url.searchParams.get('minRate')) || 0);
        const minRank = Math.max(0, Number(url.searchParams.get('minRank')) || 0);
        const offset = premium ? 0 : Math.max(0, Math.floor(Number(url.searchParams.get('offset')) || 0));
        const limit = Math.max(1, Math.min(premium ? 10 : 30,
          Number(url.searchParams.get('limit')) || (premium ? 10 : 30)));
        const excludeJob = url.searchParams.get('excludeJob') || '';
        const onlyJob = url.searchParams.get('onlyJob') || '';
        const all = ranked();
        const tierRows = premium ? all.slice(0, 10) : all;
        const visible = tierRows.filter(item =>
          item.jobId !== excludeJob && (!onlyJob || item.jobId === onlyJob) &&
          item.rate >= minRate && item.rank >= minRank
        );
        const items = visible.slice(offset, offset + limit).map((item, i) => ({
          ...item, ...(premium ? { globalRank: all.indexOf(item) + 1 } : { displayRank: offset + i + 1 })
        }));
        return send(res, 200, {
          tier: premium ? 'premium' : 'public', serverTime: now(),
          retainedServers: snapshots.size, ttlSeconds: TTL_MS / 1000,
          participants: snapshots.size, servers: snapshots.size,
          total: visible.length,
          nextOffset: offset + limit < visible.length ? offset + limit : null,
          items
        });
      }
      if (req.method === 'POST' && url.pathname === '/v1/join') {
        if (!limited(req, 'join', 60)) return send(res, 429, { error: 'Too many join requests' });
        const data = await readJson(req, 2048);
        if (!data || data.placeId !== GAME_PLACE || !validId(data.jobId) || !validId(data.reporterId))
          return send(res, 400, { error: 'Invalid join' });
        const found = ranked().find(item => item.jobId === data.jobId && (!data.uid || item.uid === data.uid));
        if (!found) return send(res, 200, { ok: true, allowed: false, unavailable: true });
        const key = found.placeId + ':' + found.jobId + ':' + found.uid;
        const current = reservations.get(key);
        if (current) return send(res, 200, { ok: true, allowed: current.reporterId === data.reporterId, hideAt: current.hideAt });
        const hideAt = now() + 5000;
        reservations.set(key, { reporterId: data.reporterId, hideAt, expiresAt: hideAt + 30_000 });
        return send(res, 200, { ok: true, allowed: true, hideAt });
      }
      return send(res, 404, { error: 'Not found' });
    } catch (error) {
      return send(res, error.status || 500, { error: error.status ? error.message : 'Request failed' });
    }
  });
}

module.exports = { createServer };
if (require.main === module) {
  const configPath = process.argv[2] || path.join(__dirname, 'host-config.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const port = Number(config.port) || 32487;
  createServer({})
    .listen(port, '0.0.0.0', () => process.stdout.write('Independent Finder API listening on ' + port + '\n'));
}
