#!/usr/bin/env node
// 릴스 JSON -> 1080x1920 mp4 + 커버 jpg + 캡션 txt
//
// 사용법:
//   node build/render.mjs willkommen-01
//   node build/render.mjs --all
//   node build/render.mjs willkommen-01 --sheet    # 참조 미디어 대조 시트만 생성
//
// ⚠ 반드시 지킬 것 (실측으로 확인한 함정)
//  1. blend=all_mode=multiply 금지. 체인 끝이 yuv420p 면 ffmpeg 8 이 blend 를 YUV 평면에서
//     실행해 U/V(128 오프셋)까지 곱하고 화면 전체가 형광 초록이 된다. 양쪽 입력에 format=rgba 를
//     못 박아도 재현된다. 흰 배경 캐릭터 클립은 matte:"white"(colorkey + overlay)로 처리한다.
//  2. 브랜드 폰트는 시스템에 없다. 작업폴더 fonts/ 로 복사한 뒤 ass 필터에 fontsdir=fonts 를 준다.
//  3. 새 클립을 쓰기 전에 반드시 --sheet 로 시작·중간·끝 프레임을 눈으로 본다.
//     (magpie_bob.mp4 는 6.5초에 까치가 프레임 밖으로 날아간다. 파일명만 보고 고르면 이런 사고가 난다.)

import { spawn } from 'node:child_process';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildAss } from './lib/ass.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const MARKETING = path.resolve(HERE, '..');
const REPO = path.resolve(MARKETING, '..');

const IMAGE_RE = /\.(png|jpe?g|webp)$/i;

const run = (cmd, args, opts = {}) =>
  new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { ...opts, windowsHide: true });
    let err = '';
    let out = '';
    p.stderr.on('data', (d) => { err += d.toString(); });
    p.stdout.on('data', (d) => { out += d.toString(); });
    p.on('error', reject);
    p.on('close', (code) =>
      code === 0 ? resolve({ out, err }) : reject(new Error(`${cmd} exit ${code}\n${err.slice(-4000)}`)));
  });

async function probe(file) {
  const { out } = await run('ffprobe', [
    '-v', 'error', '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height', '-show_entries', 'format=duration',
    '-of', 'default=noprint_wrappers=1:nokey=1', file,
  ]);
  const lines = out.trim().split(/\r?\n/);
  const w = Number(lines[0]);
  const h = Number(lines[1]);
  const duration = Number(lines[2]) || 0;
  if (!w || !h) throw new Error(`크기를 읽지 못했다: ${file}`);
  return { w, h, duration };
}

const even = (n) => Math.max(2, Math.round(n / 2) * 2);

/**
 * box[x,y,w,h] 안에 원본을 넣는 scale(+crop) 필터와 배치 좌표.
 *  - contain: 박스 안에 다 들어오게 축소
 *  - cover:   박스를 꽉 채우고 넘치는 부분을 중앙에서 잘라낸다
 */
function fitBox(src, box, mode = 'contain', anchor) {
  const [bx, by, bw, bh] = box;
  if (mode === 'cover') {
    const scale = Math.max(bw / src.w, bh / src.h);
    const sw = even(src.w * scale);
    const sh = even(src.h * scale);
    const cw = even(bw);
    const ch = even(bh);
    // anchor[0..1] 로 크롭 위치를 잡는다. 0.5 가 중앙.
    // 가로 소스를 세로로 자를 때 인물을 오른쪽으로 밀어 왼쪽 위에 타이포 여백을 비우는 데 쓴다.
    const ax = Math.min(Math.max(anchor?.[0] ?? 0.5, 0), 1);
    const ay = Math.min(Math.max(anchor?.[1] ?? 0.5, 0), 1);
    return {
      x: Math.round(bx), y: Math.round(by),
      filter: `scale=${sw}:${sh},crop=${cw}:${ch}:${Math.round((sw - cw) * ax)}:${Math.round((sh - ch) * ay)}`,
    };
  }
  const scale = Math.min(bw / src.w, bh / src.h);
  const w = even(src.w * scale);
  const h = even(src.h * scale);
  return {
    x: Math.round(bx + (bw - w) / 2), y: Math.round(by + (bh - h) / 2),
    filter: `scale=${w}:${h}`,
  };
}

/** 알파 페이드 인/아웃 필터 조각 (레이어 등장·퇴장, 크로스페이드 대용) */
function fadeChain(start, end, fadeIn, fadeOut) {
  const parts = [];
  if (fadeIn > 0) parts.push(`fade=t=in:st=${start.toFixed(3)}:d=${fadeIn.toFixed(3)}:alpha=1`);
  if (fadeOut > 0) parts.push(`fade=t=out:st=${(end - fadeOut).toFixed(3)}:d=${fadeOut.toFixed(3)}:alpha=1`);
  return parts;
}

async function copyFonts(tokens, workDir) {
  const fontsDir = path.join(workDir, 'fonts');
  await fs.mkdir(fontsDir, { recursive: true });
  let copied = 0;
  for (const rel of tokens.fonts.sourceDirs) {
    const dir = path.resolve(REPO, rel);
    let entries = [];
    try { entries = await fs.readdir(dir); } catch { console.warn(`  ! 폰트 디렉터리 없음: ${rel}`); continue; }
    for (const name of entries) {
      if (!/\.(otf|ttf)$/i.test(name)) continue;   // libass 는 woff2 를 못 읽는다
      await fs.copyFile(path.join(dir, name), path.join(fontsDir, name));
      copied += 1;
    }
  }
  if (copied === 0) console.warn('  ! 브랜드 폰트 복사 실패 — libass 가 시스템 폰트로 폴백한다.');
  return copied;
}

/** background.sequence 를 풀블리드 레이어 목록으로 펼친다 (알파 페이드 = 크로스페이드) */
function expandSequence(seq, W, H, xf) {
  const out = [];
  let t = 0;
  seq.forEach((item, i) => {
    const d = item.duration;
    out.push({
      path: item.path,
      box: [0, 0, W, H],
      fit: item.fit ?? 'cover',
      start: t,
      end: t + d + xf,
      fadeIn: i === 0 ? 0 : xf,
      fadeOut: xf,
      anchor: item.anchor,
    });
    t += d;
  });
  return out;
}

async function renderReel(reelPath, tokens) {
  const reel = JSON.parse(await fs.readFile(reelPath, 'utf8'));
  const id = reel.id;
  const [W, H] = reel.size ?? [tokens.video.width, tokens.video.height];
  const fps = reel.fps ?? tokens.video.fps;
  const dur = reel.duration;
  if (!dur) throw new Error(`${id}: duration 이 없다`);

  const workDir = path.join(MARKETING, 'out', id);
  await fs.mkdir(workDir, { recursive: true });

  // 텍스트 큐가 없으면 clean visual master 로 렌더한다.
  // 모든 카피는 After Effects 의 별도 텍스트 레이어로 올린다 — 영상에 굽지 않는다.
  // 그래야 문구 수정이나 DE/EN/KO 버전을 만들 때 영상을 다시 만들 필요가 없다.
  const isClean = (reel.text ?? []).length === 0;

  console.log(`\n▶ ${id}  (${dur}s, ${W}x${H}@${fps})${isClean ? '  [clean master · 자막 없음]' : ''}`);
  if (!isClean) {
    console.log(`  폰트 ${await copyFonts(tokens, workDir)}개 준비`);
    await fs.writeFile(path.join(workDir, 'reel.ass'), buildAss(reel, tokens), 'utf8');
  }

  const inputs = [];
  const filters = [];
  let idx = 0;
  let step = 0;

  // 0) 크림 바탕
  inputs.push('-f', 'lavfi', '-i', `color=c=${tokens.colors.cream}:s=${W}x${H}:r=${fps}`);
  filters.push(`[${idx++}:v]format=rgba[canvas0]`);
  let canvas = 'canvas0';

  // 1) 배경 (단일 소스). fill:"blur" 면 흐린 확대본으로 화면을 채우고 그 위에 선명한 원본을 얹는다.
  //    가로 소스를 세로 프레임에 넣을 때 잘라내지 않고 풀블리드를 얻는 방법이다.
  const bg = reel.background;
  if (bg?.path) {
    const file = path.resolve(REPO, bg.path);
    const src = await probe(file);
    if (IMAGE_RE.test(file)) inputs.push('-loop', '1');
    else if (bg.loop !== false) inputs.push('-stream_loop', '-1');
    inputs.push('-i', file);
    const bi = idx++;

    const op = bg.opacity ?? 1;
    const fill = bg.fill ?? 'cover';

    if (fill === 'blur') {
      const fitW = fitBox(src, [0, 0, W, H], 'contain');
      const cover = fitBox(src, [0, 0, W, H], 'cover');
      filters.push(`[${bi}:v]split=2[bgs][bgb]`);
      filters.push(`[bgb]${cover.filter},fps=${fps},gblur=sigma=42,eq=brightness=0.06:saturation=0.85,format=rgba[bgblur]`);
      filters.push(`[${canvas}][bgblur]overlay=0:0:format=auto[canvas${++step}]`);
      canvas = `canvas${step}`;
      filters.push(`[bgs]${fitW.filter},fps=${fps},format=rgba[bgsharp]`);
      filters.push(`[${canvas}][bgsharp]overlay=${fitW.x}:${fitW.y}:format=auto[canvas${++step}]`);
      canvas = `canvas${step}`;
    } else {
      // 풀블리드 cover. kenburns.mode = panX | panY 면 crop 좌표를 시간 함수로 움직인다.
      const kb = bg.kenburns;
      let chain;
      if (kb && (kb.mode === 'panX' || kb.mode === 'panY')) {
        const over = kb.over ?? 1.12;                       // 크롭 여유분
        const sw = even(Math.max(W, (H * src.w) / src.h) * over);
        const sh = even(Math.max(H, (W * src.h) / src.w) * over);
        const xExpr = kb.mode === 'panX' ? `(iw-ow)*(t/${dur})` : `(iw-ow)/2`;
        const yExpr = kb.mode === 'panY' ? `(ih-oh)*(t/${dur})` : `(ih-oh)/2`;
        chain = `scale=${sw}:${sh},crop=${W}:${H}:'${xExpr}':'${yExpr}'`;
      } else {
        chain = fitBox(src, [0, 0, W, H], 'cover').filter;
      }
      filters.push(`[${bi}:v]${chain},fps=${fps},format=rgba,colorchannelmixer=aa=${op}[bg]`);
      filters.push(`[${canvas}][bg]overlay=0:0:format=auto[canvas${++step}]`);
      canvas = `canvas${step}`;
    }
  }

  // 2) 배경 시퀀스 (알파 페이드로 크로스페이드)
  const seqLayers = bg?.sequence ? expandSequence(bg.sequence, W, H, bg.crossfade ?? 0.4) : [];

  // 3) 스크림 — 배경 위, 전경 레이어 아래. 화려한 아트 위에서 텍스트가 읽히게 한다.
  //    2x64 로 만든 그라데이션을 확대해서 쓴다 (geq 를 큰 해상도에 돌리면 느리다).
  const scrim = reel.scrim;
  const scrimOps = [];
  if (scrim?.top) {
    const th = scrim.topHeight ?? 620;
    inputs.push('-f', 'lavfi', '-i', `color=c=${tokens.colors.cream}:s=2x64:r=${fps}`);
    const si = idx++;
    filters.push(`[${si}:v]format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='255*${scrim.top}*(1-Y/63)',scale=${W}:${th},setsar=1[scrimtop]`);
    scrimOps.push(['scrimtop', 0, 0]);
  }
  if (scrim?.bottom) {
    const bh = scrim.bottomHeight ?? 560;
    inputs.push('-f', 'lavfi', '-i', `color=c=${tokens.colors.cream}:s=2x64:r=${fps}`);
    const si = idx++;
    filters.push(`[${si}:v]format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='255*${scrim.bottom}*(Y/63)',scale=${W}:${bh},setsar=1[scrimbot]`);
    scrimOps.push(['scrimbot', 0, H - bh]);
  }

  const fgLayers = reel.layers ?? [];

  const emitLayer = async (layer) => {
    const file = path.resolve(REPO, layer.path);
    const src = await probe(file);
    const box = layer.box ?? [0, 0, W, H];
    const fit = fitBox(src, box, layer.fit ?? 'contain', layer.anchor);

    if (IMAGE_RE.test(file)) inputs.push('-loop', '1');
    else if (layer.loop !== false) inputs.push('-stream_loop', '-1');
    inputs.push('-i', file);
    const li = idx++;

    const s = layer.start ?? 0;
    const e = layer.end ?? dur;
    const fi = layer.fadeIn ?? 0;
    const fo = layer.fadeOut ?? 0;

    const chain = [layer.matte === 'white' || layer.matte === 'multiply'
      ? `${fit.filter},fps=${fps},format=rgba,colorkey=color=white:similarity=${layer.keySimilarity ?? 0.10}:blend=${layer.keyBlend ?? 0.08}`
      : `${fit.filter},fps=${fps},format=rgba`];
    if (layer.opacity != null && layer.opacity < 1) chain.push(`colorchannelmixer=aa=${layer.opacity}`);
    chain.push(...fadeChain(s, e, fi, fo));
    filters.push(`[${li}:v]${chain.join(',')}[o${li}]`);

    // 알파 페이드를 쓰면 enable 이 필요 없다. 페이드가 없을 때만 enable 로 구간을 자른다.
    const needEnable = (fi === 0 && fo === 0) && (s > 0 || e < dur);
    const enable = needEnable ? `:enable='between(t,${s},${e})'` : '';
    filters.push(`[${canvas}][o${li}]overlay=${fit.x}:${fit.y}:format=auto${enable}[canvas${++step}]`);
    canvas = `canvas${step}`;
  };

  for (const layer of seqLayers) await emitLayer(layer);
  for (const [label, x, y] of scrimOps) {
    filters.push(`[${canvas}][${label}]overlay=${x}:${y}:format=auto[canvas${++step}]`);
    canvas = `canvas${step}`;
  }
  for (const layer of fgLayers) await emitLayer(layer);

  // 4) 무음 오디오 (Reels 는 오디오 트랙이 없으면 처리 실패가 잦다)
  inputs.push('-f', 'lavfi', '-i', `anullsrc=channel_layout=stereo:sample_rate=${tokens.video.audioSampleRate}`);
  const audioIdx = idx++;

  filters.push(isClean
    ? `[${canvas}]format=yuv420p[v]`
    : `[${canvas}]ass=filename=reel.ass:fontsdir=fonts,format=yuv420p[v]`);

  const mp4 = isClean ? `${id}-master-1080x1920.mp4` : `${id}-1080x1920.mp4`;
  await run('ffmpeg', [
    '-y', '-hide_banner', '-loglevel', 'error',
    ...inputs,
    '-filter_complex', filters.join(';'),
    '-map', '[v]', '-map', `${audioIdx}:a`,
    '-t', String(dur),
    '-c:v', 'libx264', '-profile:v', 'high', '-preset', tokens.video.preset,
    '-crf', String(tokens.video.crf), '-pix_fmt', 'yuv420p',
    // 주의: -colorspace/-color_primaries/-color_trc 는 달지 않는다.
    '-r', String(fps), '-g', String(fps * 2),
    '-c:a', 'aac', '-b:a', tokens.video.audioBitrate,
    '-movflags', '+faststart',
    mp4,
  ], { cwd: workDir });

  const cover = isClean ? `${id}-master-cover.jpg` : `${id}-cover.jpg`;
  await run('ffmpeg', [
    '-y', '-hide_banner', '-loglevel', 'error',
    '-ss', String(reel.cover_at ?? Math.min(1.5, dur / 2)), '-i', mp4,
    '-frames:v', '1', '-q:v', '2', cover,
  ], { cwd: workDir });

  const p = reel.post ?? {};
  const caption = [p.caption_de ?? '', '', p.cta ?? '', '',
    (p.hashtags ?? tokens.defaults.hashtags).join(' ')].join('\n').trim();
  await fs.writeFile(path.join(workDir, 'post.txt'), caption + '\n', 'utf8');

  const stat = await fs.stat(path.join(workDir, mp4));
  console.log(`  ✓ ${mp4}  ${(stat.size / 1048576).toFixed(2)} MiB`);
  console.log(`  ✓ ${cover}  ✓ post.txt`);
  if (reel.manual_todo?.length) {
    console.log('  ⚠ 사람이 해야 할 일:');
    for (const t of reel.manual_todo) console.log(`     - ${t}`);
  }
}

/**
 * 대조 시트 — 이 릴스가 참조하는 모든 미디어의 시작·중간·끝 프레임을 한 장으로 뽑는다.
 * 클립을 파일명만 보고 고르다 magpie_bob(6.5초에 프레임 밖으로 날아감) 사고가 났다. 그 재발 방지용.
 */
async function contactSheet(reelPath) {
  const reel = JSON.parse(await fs.readFile(reelPath, 'utf8'));
  const workDir = path.join(MARKETING, 'out', reel.id);
  await fs.mkdir(workDir, { recursive: true });

  const refs = [];
  if (reel.background?.path) refs.push(reel.background.path);
  for (const s of reel.background?.sequence ?? []) refs.push(s.path);
  for (const l of reel.layers ?? []) refs.push(l.path);
  const uniq = [...new Set(refs)];

  console.log(`\n▶ ${reel.id} 대조 시트 — 미디어 ${uniq.length}개`);
  const tiles = [];
  for (let i = 0; i < uniq.length; i += 1) {
    const rel = uniq[i];
    const file = path.resolve(REPO, rel);
    const src = await probe(file);
    const isImg = IMAGE_RE.test(file);
    const marks = isImg ? [0] : [src.duration * 0.08, src.duration * 0.5, src.duration * 0.92];
    console.log(`  [${String(i).padStart(2, '0')}] ${rel}  ${src.w}x${src.h}${isImg ? '' : ` ${src.duration.toFixed(1)}s`}`);
    for (let k = 0; k < marks.length; k += 1) {
      const out = path.join(workDir, `_sheet_${i}_${k}.png`);
      await run('ffmpeg', ['-y', '-v', 'error', '-ss', String(marks[k]), '-i', file,
        '-frames:v', '1', '-vf', 'scale=240:240:force_original_aspect_ratio=decrease,pad=240:240:(ow-iw)/2:(oh-ih)/2:color=0xdddddd', out]);
      tiles.push(out);
    }
  }

  const cols = 6;
  const rows = Math.ceil(tiles.length / cols);
  const inputs = [];
  const graph = [];
  let n = 0;
  for (let r = 0; r < rows; r += 1) {
    const rowTiles = [];
    for (let c = 0; c < cols; c += 1) {
      const t = tiles[r * cols + c];
      if (t) { inputs.push('-i', t); rowTiles.push(`[${n++}:v]`); }
      else { inputs.push('-f', 'lavfi', '-i', 'color=c=0xf5f5f5:s=240x240:d=1'); rowTiles.push(`[${n++}:v]`); }
    }
    graph.push(`${rowTiles.join('')}hstack=inputs=${cols}[r${r}]`);
  }
  graph.push(rows > 1
    ? `${Array.from({ length: rows }, (_, r) => `[r${r}]`).join('')}vstack=inputs=${rows}[v]`
    : `[r0]null[v]`);

  const sheet = path.join(workDir, '_contact-sheet.png');
  await run('ffmpeg', ['-y', '-v', 'error', ...inputs, '-filter_complex', graph.join(';'), '-map', '[v]', '-frames:v', '1', sheet]);
  for (const t of tiles) await fs.unlink(t).catch(() => {});
  console.log(`  ✓ ${path.relative(MARKETING, sheet)}  (미디어당 좌→우 시작·중간·끝, 6칸씩 줄바꿈)`);
}

async function main() {
  const tokens = JSON.parse(await fs.readFile(path.join(MARKETING, 'brand', 'tokens.json'), 'utf8'));
  const reelsDir = path.join(MARKETING, 'content', 'reels');
  const argv = process.argv.slice(2);
  const sheetOnly = argv.includes('--sheet');
  const names = argv.filter((a) => !a.startsWith('--'));

  const files = (names.length === 0 || argv.includes('--all'))
    ? (await fs.readdir(reelsDir)).filter((f) => f.endsWith('.json')).map((f) => path.join(reelsDir, f))
    : names.map((a) => path.join(reelsDir, a.endsWith('.json') ? a : `${a}.json`));

  if (!files.length) { console.error('릴스 JSON이 없다.'); process.exit(1); }

  let failed = 0;
  for (const f of files) {
    try {
      if (sheetOnly) await contactSheet(f);
      else await renderReel(f, tokens);
    } catch (e) {
      failed += 1;
      console.error(`\n✗ ${path.basename(f)}\n${e.message}\n`);
    }
  }
  console.log(`\n완료: ${files.length - failed}/${files.length}`);
  process.exit(failed ? 1 : 0);
}

main();
