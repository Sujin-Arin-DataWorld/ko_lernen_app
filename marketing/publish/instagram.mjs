#!/usr/bin/env node
// Instagram Reels 승인 큐 + 발행.
//
//   node publish/instagram.mjs list
//   node publish/instagram.mjs add <reelId>        # 렌더 결과를 큐에 draft 로 넣는다
//   node publish/instagram.mjs approve <reelId>    # Jin 승인 -> approved
//   node publish/instagram.mjs                     # dry-run (실제 발행 안 함)
//   node publish/instagram.mjs --live              # 실제 발행
//
// ⚠ 안전장치
//  - 기본이 dry-run 이다. --live 를 명시해야만 실제로 올라간다.
//  - status 가 approved 인 항목만 발행한다. draft 는 절대 안 올라간다.
//  - 토큰은 .env 에서만 읽는다. queue.json 에 쓰지 않는다.
//
// 사전 조건 (docs: developers.facebook.com/docs/instagram-platform/content-publishing)
//  - Instagram "비즈니스" 계정 (크리에이터 계정은 API 발행 불가)
//  - 앱 심사 통과: instagram_business_basic + instagram_business_content_publish
//  - video_url 은 공개 HTTPS URL 이어야 한다. 로컬 파일 업로드 불가.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const MARKETING = path.resolve(HERE, '..');
const QUEUE = path.join(HERE, 'queue.json');

async function loadEnv() {
  const env = { ...process.env };
  try {
    const raw = await fs.readFile(path.join(HERE, '.env'), 'utf8');
    for (const line of raw.split(/\r?\n/)) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
      if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  } catch { /* .env 없으면 프로세스 환경만 쓴다 */ }
  return env;
}

const readQueue = async () => {
  try { return JSON.parse(await fs.readFile(QUEUE, 'utf8')); }
  catch { return []; }
};
const writeQueue = (q) => fs.writeFile(QUEUE, JSON.stringify(q, null, 2) + '\n', 'utf8');

const nowIso = () => new Date().toISOString().replace(/\.\d+Z$/, 'Z');

async function cmdAdd(reelId, env) {
  const dir = path.join(MARKETING, 'out', reelId);
  const mp4 = `${reelId}-1080x1920.mp4`;
  await fs.access(path.join(dir, mp4)); // 없으면 throw
  const caption = await fs.readFile(path.join(dir, 'post.txt'), 'utf8');

  const base = (env.PUBLIC_MEDIA_BASE || 'https://REPLACE-ME.example/reels').replace(/\/$/, '');
  const q = await readQueue();
  if (q.some((e) => e.id === reelId)) {
    console.log(`이미 큐에 있다: ${reelId}`);
    return;
  }
  q.push({
    id: reelId,
    status: 'draft',
    videoUrl: `${base}/${mp4}`,
    coverUrl: `${base}/${reelId}-cover.jpg`,
    caption: caption.trim(),
    scheduledAt: null,
    publishedAt: null,
    containerId: null,
    permalink: null,
  });
  await writeQueue(q);
  console.log(`추가됨(draft): ${reelId}`);
  console.log(`  videoUrl: ${base}/${mp4}`);
  console.log('  ⚠ mp4/jpg 를 위 URL 로 실제 업로드해야 발행이 된다.');
}

async function cmdApprove(reelId, when) {
  const q = await readQueue();
  const e = q.find((x) => x.id === reelId);
  if (!e) throw new Error(`큐에 없다: ${reelId}`);
  e.status = 'approved';
  e.scheduledAt = when || nowIso();
  await writeQueue(q);
  console.log(`승인됨: ${reelId} (예정 ${e.scheduledAt})`);
}

async function cmdList() {
  const q = await readQueue();
  if (!q.length) return console.log('큐가 비어 있다.');
  for (const e of q) {
    const mark = { draft: '·', approved: '→', published: '✓', failed: '✗' }[e.status] ?? '?';
    console.log(`${mark} ${e.status.padEnd(9)} ${e.id}${e.scheduledAt ? `  예정 ${e.scheduledAt}` : ''}${e.permalink ? `  ${e.permalink}` : ''}`);
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function publishOne(entry, env, live) {
  const ver = env.IG_API_VERSION || 'v23.0';
  const user = env.IG_USER_ID;
  const token = env.IG_ACCESS_TOKEN;
  const api = `https://graph.instagram.com/${ver}`;

  if (!live) {
    console.log(`  [dry-run] 발행 생략: ${entry.id}`);
    console.log(`            video_url=${entry.videoUrl}`);
    console.log(`            caption=${entry.caption.slice(0, 60).replace(/\n/g, ' ')}…`);
    return;
  }
  if (!user || !token) throw new Error('IG_USER_ID / IG_ACCESS_TOKEN 이 .env 에 없다.');

  // 1) 컨테이너 생성
  const body = new URLSearchParams({
    media_type: 'REELS',
    video_url: entry.videoUrl,
    caption: entry.caption,
    share_to_feed: 'true',
    access_token: token,
  });
  if (entry.coverUrl) body.set('cover_url', entry.coverUrl);

  let res = await fetch(`${api}/${user}/media`, { method: 'POST', body });
  let json = await res.json();
  if (!res.ok || !json.id) throw new Error(`컨테이너 생성 실패: ${JSON.stringify(json)}`);
  entry.containerId = json.id;
  console.log(`  컨테이너 ${json.id}`);

  // 2) 처리 완료 대기 (영상 트랜스코딩)
  for (let i = 0; i < 60; i += 1) {
    await sleep(5000);
    res = await fetch(`${api}/${json.id}?fields=status_code,status&access_token=${encodeURIComponent(token)}`);
    const st = await res.json();
    if (st.status_code === 'FINISHED') break;
    if (st.status_code === 'ERROR' || st.status_code === 'EXPIRED') {
      throw new Error(`컨테이너 처리 실패: ${JSON.stringify(st)}`);
    }
    if (i === 59) throw new Error('컨테이너 처리 5분 초과');
  }

  // 3) 발행
  res = await fetch(`${api}/${user}/media_publish`, {
    method: 'POST',
    body: new URLSearchParams({ creation_id: entry.containerId, access_token: token }),
  });
  json = await res.json();
  if (!res.ok || !json.id) throw new Error(`발행 실패: ${JSON.stringify(json)}`);

  entry.status = 'published';
  entry.publishedAt = nowIso();
  entry.permalink = `https://www.instagram.com/reel/${json.id}/`;
  console.log(`  ✓ 발행됨 ${json.id}`);
}

async function cmdPublish(env, live) {
  const q = await readQueue();
  const now = Date.now();
  const due = q.filter((e) => e.status === 'approved' && (!e.scheduledAt || Date.parse(e.scheduledAt) <= now));

  if (!due.length) return console.log('발행할 승인 항목이 없다.');
  console.log(`${live ? '실제 발행' : 'DRY-RUN'} 대상 ${due.length}건\n`);

  for (const entry of due) {
    console.log(`▶ ${entry.id}`);
    try {
      await publishOne(entry, env, live);
    } catch (e) {
      entry.status = 'failed';
      entry.error = e.message;
      console.error(`  ✗ ${e.message}`);
    }
    await writeQueue(q);
  }
}

async function main() {
  const env = await loadEnv();
  const argv = process.argv.slice(2);
  const live = argv.includes('--live');
  const args = argv.filter((a) => !a.startsWith('--'));
  const [cmd, arg1, arg2] = args;

  try {
    if (cmd === 'add') await cmdAdd(arg1, env);
    else if (cmd === 'approve') await cmdApprove(arg1, arg2);
    else if (cmd === 'list') await cmdList();
    else await cmdPublish(env, live);
  } catch (e) {
    console.error(`오류: ${e.message}`);
    process.exit(1);
  }
}

main();
