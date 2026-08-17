// ASS 자막 생성기.
// 기존 관례(docs/social/bbanana/sori-check-01-reel.ass)를 계승하되 두 가지를 고친다:
//  1) 모든 스타일 Alignment=8(상단 중앙) + MarginV=상단으로부터의 y  -> 배치가 결정적이다.
//  2) Reels UI 안전영역을 지킨다. 하단 420px(캡션/액션바)·우측 180px(액션 레일)에 글자를 두지 않는다.

/** '#rrggbb' -> ASS '&HAABBGGRR' (AA=00 이 불투명) */
export function hexToAss(hex, alpha = 0) {
  const h = hex.replace('#', '').trim();
  const r = h.slice(0, 2);
  const g = h.slice(2, 4);
  const b = h.slice(4, 6);
  const a = alpha.toString(16).padStart(2, '0');
  return `&H${a}${b}${g}${r}`.toUpperCase();
}

/** 초 -> ASS 타임코드 h:mm:ss.cc */
export function assTime(seconds) {
  const s = Math.max(0, seconds);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = Math.floor(s % 60);
  const cs = Math.round((s - Math.floor(s)) * 100);
  const cc = cs === 100 ? 99 : cs;
  return `${h}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}.${String(cc).padStart(2, '0')}`;
}

/**
 * 스타일 표.
 * y = 상단으로부터의 픽셀. size = 폰트 크기. font: 'sans' | 'display'.
 * box=true 면 BorderStyle 3(불투명 배경 박스)로 렌더한다.
 */
// 풀블리드 아트 위에 얹히므로 v1 대비 크기를 올리고 그림자를 줬다.
// shadow: ASS Shadow 값. 화려한 배경 위에서 외곽선만으로는 글자가 뜨지 않는다.
export const STYLES = {
  Series:   { y: 150,  size: 30,  font: 'sans',    color: 'cream', outline: 'teal',  bold: true,  box: true,  spacing: 2,  shadow: 0 },
  Eyebrow:  { y: 250,  size: 36,  font: 'sans',    color: 'red',   outline: 'cream', bold: true,  box: false, spacing: 3,  shadow: 1 },
  Title:    { y: 300,  size: 96,  font: 'sans',    color: 'cream', outline: 'ink',   bold: true,  box: false, spacing: -2, shadow: 3 },
  Hook:     { y: 320,  size: 76,  font: 'sans',    color: 'ink',   outline: 'cream', bold: true,  box: false, spacing: -2, shadow: 2 },
  Display:  { y: 430,  size: 200, font: 'display', color: 'teal',  outline: 'cream', bold: false, box: false, spacing: 0,  shadow: 2 },
  Question: { y: 640,  size: 58,  font: 'sans',    color: 'ink',   outline: 'cream', bold: true,  box: false, spacing: -2, shadow: 2 },
  Ko:       { y: 700,  size: 86,  font: 'display', color: 'teal',  outline: 'cream', bold: false, box: false, spacing: 0,  shadow: 2 },
  Roman:    { y: 660,  size: 54,  font: 'sans',    color: 'ink',   outline: 'cream', bold: true,  box: false, spacing: -1, shadow: 2 },
  Choice:   { y: 1150, size: 50,  font: 'sans',    color: 'ink',   outline: 'cream', bold: true,  box: false, spacing: 0,  shadow: 2 },
  Body:     { y: 1310, size: 52,  font: 'sans',    color: 'ink',   outline: 'cream', bold: true,  box: false, spacing: -1, shadow: 2 },
  Correct:  { y: 250,  size: 34,  font: 'sans',    color: 'red',   outline: 'cream', bold: true,  box: false, spacing: 3,  shadow: 1 },
  CTA:      { y: 1470, size: 42,  font: 'sans',    color: 'cream', outline: 'teal',  bold: true,  box: true,  spacing: -1, shadow: 0 },
  Handle:   { y: 1575, size: 28,  font: 'sans',    color: 'muted', outline: 'cream', bold: true,  box: false, spacing: 0,  shadow: 1 },
};

export function buildAss(reel, tokens) {
  const [W, H] = reel.size ?? [tokens.video.width, tokens.video.height];
  const fam = { sans: tokens.fonts.sans, display: tokens.fonts.display };
  const col = tokens.colors;

  const styleLines = Object.entries(STYLES).map(([name, s]) => {
    const primary = hexToAss(col[s.color]);
    const outline = hexToAss(col[s.outline]);
    // BorderStyle 3 은 OutlineColour 를 배경 박스 색으로 쓴다.
    const borderStyle = s.box ? 3 : 1;
    const outlineWidth = s.box ? 12 : 4;
    const shadow = s.shadow ?? 0;
    return [
      `Style: ${name}`,
      fam[s.font],
      s.size,
      primary,
      '&H000000FF',
      outline,
      '&H00000000',
      s.bold ? -1 : 0,
      0, 0, 0,
      100, 100,
      s.spacing,
      0,
      borderStyle,
      outlineWidth,
      shadow,
      8,           // Alignment: 상단 중앙 고정
      70, 70,      // MarginL, MarginR
      s.y,         // MarginV = 상단으로부터의 y
      1,
    ].join(',');
  });

  const events = (reel.text ?? []).map((cue) => {
    const style = STYLES[cue.style] ? cue.style : 'Body';
    const start = assTime(cue.start ?? 0);
    const end = assTime(cue.end ?? reel.duration);
    // 개행은 \N, 중괄호는 ASS 오버라이드 문법이라 제거한다.
    const text = String(cue.content).replace(/[{}]/g, '').replace(/\n/g, '\\N');
    const fade = cue.fade === false ? '' : '{\\fad(180,180)}';
    // MarginV 를 큐 단위로 덮어쓸 수 있게 한다(같은 스타일 재사용).
    const mv = cue.y ?? 0;
    return `Dialogue: 0,${start},${end},${style},,0,0,${mv},,${fade}${text}`;
  });

  return [
    '[Script Info]',
    'ScriptType: v4.00+',
    `PlayResX: ${W}`,
    `PlayResY: ${H}`,
    'WrapStyle: 2',
    'ScaledBorderAndShadow: yes',
    'YCbCr Matrix: TV.709',
    '',
    '[V4+ Styles]',
    'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding',
    ...styleLines,
    '',
    '[Events]',
    'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text',
    ...events,
    '',
  ].join('\n');
}
