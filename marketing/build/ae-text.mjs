#!/usr/bin/env node
// 릴스 JSON 의 ae_text[] -> After Effects 텍스트 레이어 스크립트(.jsx) + 사람이 읽는 스펙(.md)
//
//   node build/ae-text.mjs --all
//   node build/ae-text.mjs hanok-waechst-02
//
// 왜 이렇게 하나
//   영상에 자막을 굽지 않는다. clean visual master 는 글자가 0이고, 모든 카피는 AE 의 별도
//   텍스트 레이어로 올린다. 그래야 문구를 고치거나 DE/EN/KO 버전을 만들 때 영상을 다시
//   만들 필요가 없다. (v2 까지는 ASS 로 구웠고, 흰 글자+검은 외곽선이 밈 자막처럼 보이고
//   호랑이 얼굴·한옥 지붕 같은 핵심 비주얼을 덮는 문제가 있었다.)
//
// 타이포 규칙 (Jin 확정)
//   Inter SemiBold / Medium. 외곽선 없음. 검은 스트로크 없음. 큰 중앙정렬 자막 없음.
//   왼쪽 정렬. 먹색. 애니메이션은 opacity 0->100 + Y +16px->0, 0.25~0.35초. 그게 전부다.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const MARKETING = path.resolve(HERE, '..');

/** 역할별 타이포 스펙. px 는 1080x1920 기준. */
const ROLES = {
  headline: { font: 'Inter-SemiBold', size: 68, color: 'ink',   opacity: 100, note: '최대 2줄. 왼쪽 정렬.' },
  sub:      { font: 'Inter-Medium',   size: 38, color: 'ink',   opacity: 80,  note: '헤드라인 보조 1줄.' },
  chapter:  { font: 'Inter-Medium',   size: 34, color: 'ink',   opacity: 70,  note: '작은 챕터 라벨. 문장 금지.' },
  tag:      { font: 'Inter-SemiBold', size: 26, color: 'cream', opacity: 100, note: '녹청 사각형 위 크림 글씨. 첫 1~2초만.' },
  cta:      { font: 'Inter-SemiBold', size: 36, color: 'cream', opacity: 100, note: '녹청 pill 위 크림 글씨. 작고 고급스럽게.' },
};

const hexToRgb01 = (hex) => {
  const h = hex.replace('#', '');
  return [0, 2, 4].map((i) => (parseInt(h.slice(i, i + 2), 16) / 255).toFixed(4));
};

// ExtendScript 는 .jsx 를 시스템 코드페이지로 읽을 수 있다. 독일어 움라우트(ü, ä, ö, ß)가
// 깨지지 않게 ASCII 밖 문자는 전부 \uXXXX 로 이스케이프한다.
const esc = (s) => String(s)
  .replace(/\\/g, '\\\\')
  .replace(/"/g, '\\"')
  .replace(/\n/g, '\\r')
  .replace(/[^\x20-\x7E]/g, (c) => `\\u${c.charCodeAt(0).toString(16).padStart(4, '0')}`);

function buildJsx(reel, tokens) {
  const [W, H] = reel.size ?? [1080, 1920];
  const fps = reel.fps ?? 30;
  const col = {
    ink: hexToRgb01(tokens.colors.ink),
    cream: hexToRgb01(tokens.colors.cream),
    teal: hexToRgb01(tokens.colors.teal),
  };

  const layers = (reel.ae_text ?? []).map((t, i) => {
    const r = ROLES[t.role] ?? ROLES.headline;
    const rgb = col[r.color];
    const x = t.x ?? 96;
    const y = t.y ?? 300;
    const fadeIn = t.fadeIn ?? 0.3;
    return `
  // ---- ${i + 1}. ${t.role} : ${String(t.content).replace(/\n/g, ' / ').slice(0, 60)}
  (function () {
    var L = comp.layers.addText("${esc(t.content)}");
    L.name = "${esc(t.id ?? `${t.role}-${i + 1}`)}";
    var d = L.property("Source Text").value;
    d.font = "${r.font}";
    d.fontSize = ${t.size ?? r.size};
    d.fillColor = [${rgb.join(', ')}];
    d.applyFill = true;
    d.applyStroke = false;                 // 외곽선 금지
    d.justification = ParagraphJustification.LEFT_JUSTIFY;
    d.tracking = ${t.tracking ?? -10};
    d.leading = ${t.leading ?? Math.round((t.size ?? r.size) * 1.22)};
    L.property("Source Text").setValue(d);

    L.inPoint  = ${t.start};
    L.outPoint = ${t.end};

    var P = L.property("Transform").property("Position");
    P.setValueAtTime(${t.start}, [${x}, ${y + 16}]);
    P.setValueAtTime(${(t.start + fadeIn).toFixed(3)}, [${x}, ${y}]);
    easeKeys(P);

    var O = L.property("Transform").property("Opacity");
    O.setValueAtTime(${t.start}, 0);
    O.setValueAtTime(${(t.start + fadeIn).toFixed(3)}, ${r.opacity});
    O.setValueAtTime(${Math.max(t.start + fadeIn, t.end - 0.25).toFixed(3)}, ${r.opacity});
    O.setValueAtTime(${t.end}, 0);
    easeKeys(O);
  })();`;
  }).join('\n');

  return `// ${reel.id} — Hangul Sori 릴스 텍스트 레이어
// 자동 생성됨: marketing/build/ae-text.mjs. 손으로 고치지 말고 릴스 JSON 의 ae_text[] 를 고쳐라.
//
// 쓰는 법
//   1) After Effects 에서 ${reel.id}-master-1080x1920.mp4 를 ${W}x${H} / ${fps}fps 컴프에 넣는다.
//   2) 그 컴프를 선택한 상태에서 File > Scripts > Run Script File 로 이 파일을 실행한다.
//   3) 텍스트 레이어가 지정된 위치·타이밍·애니메이션으로 생성된다.
//
// 폰트: Inter SemiBold / Inter Medium 이 설치돼 있어야 한다. 없으면 AE 가 대체 폰트로 바꾼다.
// tag / cta 는 글자만 만든다. 녹청(${tokens.colors.teal}) 사각형·pill 배경은 AE 에서 셰이프로 깐다.

(function () {
  var comp = app.project.activeItem;
  if (!(comp && comp instanceof CompItem)) {
    alert("컴프를 먼저 선택해라. (${W}x${H}, ${fps}fps)");
    return;
  }
  app.beginUndoGroup("Hangul Sori text — ${reel.id}");

  function easeKeys(prop) {
    var easeIn  = new KeyframeEase(0, 75);
    var easeOut = new KeyframeEase(0, 75);
    for (var k = 1; k <= prop.numKeys; k++) {
      var dim = prop.value instanceof Array ? prop.value.length : 1;
      var ins = [], outs = [];
      for (var d = 0; d < dim; d++) { ins.push(easeIn); outs.push(easeOut); }
      try { prop.setTemporalEaseAtKey(k, ins, outs); } catch (e) {}
    }
  }
${layers}

  app.endUndoGroup();
})();
`;
}

function buildSpecMd(reel, tokens) {
  const rows = (reel.ae_text ?? []).map((t) => {
    const r = ROLES[t.role] ?? ROLES.headline;
    return `| ${t.start}–${t.end}s | \`${t.role}\` | ${String(t.content).replace(/\n/g, ' ⏎ ')} | ${t.x ?? 96}, ${t.y ?? 300} | ${r.font} ${t.size ?? r.size}px |`;
  }).join('\n');

  return `# ${reel.id} — AE 텍스트 스펙

영상: \`${reel.id}-master-1080x1920.mp4\` (**글자 0. clean visual master**)
스크립트: \`${reel.id}-ae.jsx\` (AE에서 실행하면 아래 레이어가 자동 생성된다)

## 타이포 규칙

- Inter SemiBold / Medium. **외곽선·검은 스트로크·드롭섀도 금지.**
- 왼쪽 정렬. 먹색 \`${tokens.colors.ink}\`. 헤드라인 최대 2줄.
- 큰 중앙정렬 자막 금지. 호랑이·까치 얼굴과 한옥 지붕 위에 글자를 올리지 않는다.
- 애니메이션은 **opacity 0→100 + Y +16px→0, 0.25~0.35초**. 그게 전부다.
  단어별 등장·흔들림·줌인·타자기·바운스 전부 금지.
- 하단 300px(y 1620~)에는 아무것도 두지 않는다. 인스타 UI가 덮는다.

## 레이어

| 시간 | 역할 | 문구 | x, y | 폰트 |
|---|---|---|---|---|
${rows}

## 색

| 이름 | 값 |
|---|---|
| 먹 ink | \`${tokens.colors.ink}\` |
| 크림 cream | \`${tokens.colors.cream}\` |
| 녹청 teal | \`${tokens.colors.teal}\` |

\`tag\`와 \`cta\`는 글자만 생성된다. 녹청 사각형/pill 배경은 AE에서 셰이프 레이어로 깔아라.
`;
}

async function main() {
  const tokens = JSON.parse(await fs.readFile(path.join(MARKETING, 'brand', 'tokens.json'), 'utf8'));
  const reelsDir = path.join(MARKETING, 'content', 'reels');
  const argv = process.argv.slice(2);
  const names = argv.filter((a) => !a.startsWith('--'));

  const files = (names.length === 0 || argv.includes('--all'))
    ? (await fs.readdir(reelsDir)).filter((f) => f.endsWith('.json')).map((f) => path.join(reelsDir, f))
    : names.map((a) => path.join(reelsDir, a.endsWith('.json') ? a : `${a}.json`));

  for (const f of files) {
    const reel = JSON.parse(await fs.readFile(f, 'utf8'));
    if (!(reel.ae_text ?? []).length) { console.log(`· ${reel.id}: ae_text 없음 — 건너뜀`); continue; }
    const dir = path.join(MARKETING, 'out', reel.id);
    await fs.mkdir(dir, { recursive: true });
    await fs.writeFile(path.join(dir, `${reel.id}-ae.jsx`), buildJsx(reel, tokens), 'utf8');
    await fs.writeFile(path.join(dir, `${reel.id}-text-spec.md`), buildSpecMd(reel, tokens), 'utf8');
    console.log(`✓ ${reel.id}  텍스트 레이어 ${reel.ae_text.length}개 → ${reel.id}-ae.jsx + -text-spec.md`);
  }
}

main();
