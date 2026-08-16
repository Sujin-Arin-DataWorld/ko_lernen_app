# Hanok V1 A1-05 timber-preparation layer — 2026-08-17

## 목적과 입력 lineage

`05_timber_preparation`은 승인된 `06_columns` transparent raw에서 세운 기둥만
제거해 바로 이전 누적 공정을 만드는 QA-only 자산이다. 최초 조상은 프로젝트 소유
`sarangchae.png`이며, 사용자 첨부 화면, Vivasam, PDF, legacy/Gye 자산은 입력하지 않았다.

입력:

```text
assets_unused/pending_review/a1_layers/raw/06_columns_imagegen_20260817.png
sha256 e4c4c6874bde2c35b96aa4d5964cd914e9e30d1f74c6fe77f2bebf6b653b37a9
```

## 첫 생성 — rejected

- generation: `exec-cacd4ecc-faa8-4530-85b3-c3abe299e878`
- occurred: `2026-08-16T23:37:39Z`
- prompt SHA-256: `b77d16cba8de05e63dffa4ac38a46d2172a30d97184d6b81ff20bc36ffab825c`
- output: 2149×732 RGB PNG, 1,221,588 bytes
- output SHA-256: `a79e34e512d34acf767c583b21dcfaadcfacb691b7f86f016775c0bbdd13d488`
- decision: rejected

프롬프트:

```text
Edit this project-owned transparent construction layer into the immediately preceding A1 hanok construction stage, 05_timber_preparation. Preserve pixel-consistent geometry, perspective, warm faceted-minhwa material style, lighting, stone foundation/gidan, front steps, every square cornerstone base, carts, and all measured/marked timber stacks exactly where they are. Remove all seven upright wooden columns completely, including their vertical wood and any column-only shadows, so no vertical structural member remains. Do not remove the square stone cornerstone bases beneath them. Do not add beams, changbang, purlins, rafters, roof, walls, doors, windows, tools, workers, animals, landscape, ground, sky, text, labels, UI, border, or watermark. Output one isolated construction layer on a genuinely transparent RGBA background with clean alpha edges and ample transparent margin, same wide front-oblique composition and aspect ratio as the input. No black matte and no colored chroma background.
```

형태는 기단·초석·준비 목재만 남겨 의미상 맞았지만, 생성기가 회색 체크무늬를 실제
픽셀로 구워 RGB를 반환했다. compositor가 `Generated layer mode RGB must be RGBA`로
즉시 거부했다. 이 파일은 `assets_unused/pending_review/a1_layers/rejected/`에만 보존한다.

## alpha-only 수정 — approved

- generation: `exec-faf34bc5-ec7a-45a7-b878-6d4bfa62a23b`
- occurred: `2026-08-16T23:38:50Z`
- prompt SHA-256: `c9f49f42cdee9af53328d8acb020f60cd9b9ee5e43a908dd47d455842a7c4188`
- input: 위 rejected RGB output의 exact SHA
- output: 2160×728 RGBA PNG, 801,696 bytes
- output SHA-256: `8e7ed71d53e94cae3ee709f37833ae2f2f1e988bdb64bc6eedda37cb4bf94607`
- decision: approved QA raw

프롬프트:

```text
Preserve the hanok construction object in this image exactly: same stone foundation and steps, same seven empty square cornerstone bases, same carts and every stacked measured timber, same perspective, scale, colors, lighting, and placement. Change only the background: remove the entire gray-and-white checkerboard and all background pixels and output genuine transparent RGBA alpha around the object. Do not repaint, crop, resize, move, add, or remove any part of the construction object. Do not add columns, beams, roof, walls, ground, shadow plane, text, labels, UI, border, watermark, black matte, white matte, or chroma background. The final file must have real transparent pixels extending to every canvas edge, not an illustrated checkerboard.
```

## 정규화·합성 결과

```text
normalized  assets_unused/pending_review/a1_layers/05_timber_preparation_layer.png
sha256      aa9bca77204f7e9ef9eebcbf84482c1e713939548a0e8b789383d57cefb22e36
size        854x309 RGBA, 178584 bytes
alpha       0.2754181729989465
anchor      909 pixels
chroma      0 pixels

composite   assets_unused/pending_review/a1_states/05_timber_preparation.webp
sha256      308e4d3f1aa25b729acf61f4bcd7013bd41159dbca4eb7d96220c45f289bb75d
size        1536x1152 RGB WebP, 276882 bytes
outside     0 source changed pixels
inside      74296 source changed pixels
decode err  3.3901172035340394 mean channel error outside socket
encoder     Pillow 11.3.0, quality 82, method 6
```

육안 검수에서 기단·초석·치목한 목재가 보이고 세운 기둥과 이후 공정은 전혀 보이지
않았다. 전체 대지 카메라·배경은 deterministic compositor가 보존한다. 아직 runtime
asset이나 `pubspec.yaml`에는 추가하지 않았다.
