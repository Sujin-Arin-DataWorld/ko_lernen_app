# Hanok V1 A1-07 beams/changbang — 2026-08-17

## 결과

`07_beams_changbang`은 A1-06의 기단·계단·일곱 기둥을 그대로 유지하고 기둥
상부에만 보와 창방을 결구한 누적 상태다. 수장 단계에 해당하는 중간 높이 벽선,
추가 기둥, 도리, 서까래, 지붕과 벽은 없다. 최종 후보는 진짜 RGBA alpha를 가지며
직전 단계와의 foundation continuity gate와 육안 검수를 모두 통과했다.

최초의 좁고 높은 실패 후보와 gate 도입 사유는
`HANOK_V1_A1_07_BEAMS_CHANGBANG_REJECTED_2026-08-17.md`에 별도로 보존한다.

## 1. 넓은 geometry 복구 — 거절

- generation: `exec-e3b3a60c-af45-4891-9638-b4b2f4c82718`
- occurred: `2026-08-16T23:57:21Z`
- prompt SHA-256:
  `4fd2831b225fd53142cf6b76b413febb28aa2ce6b968e2f64776609fe6697409`
- output: 2172×724 RGB PNG, 1,537,791 bytes
- output SHA-256:
  `4877d172013db57fa5ec239be03c4818fea8cc8390163d29659f800434e01c51`
- decision: rejected — baked checkerboard, premature mid-height rails, secondary posts

```text
Create one corrected transparent A1-07 beams/changbang layer. Treat the approved 06_columns_imagegen image as the immutable geometry and canvas: preserve its exact 2172×724 wide 3:1 canvas, stone foundation width and position, front steps, seven cornerstone bases, seven upright columns, column spacing, object scale, perspective, remaining carts/timber stacks, colors, and lighting. Treat the rejected 07 image only as a conceptual example of horizontal beam and changbang joinery; do not copy its narrow/tall composition, extra posts, resized foundation, or checkerboard. Add only horizontal changbang rails and main beams at the existing column tops, with plausible mortise-and-tenon joints. Keep the entire foundation and lower 80-pixel footprint aligned pixel-consistently with approved A1-06. Do not add or move columns, rear posts, purlins, ridge pieces, rafters, roof, walls, floors, doors, windows, landscape, people, animals, tools, text, labels, UI, border, watermark, or shadow plane. Output exactly one 2172×724 RGBA PNG with genuine transparent alpha to every edge; no illustrated checkerboard, black/white matte, or chroma background. The only visible construction change from A1-06 is the newly joined beams and changbang.
```

## 2. ImageGen alpha-only 수정 — 거절

- generation: `exec-d4925923-526f-4dbf-afca-4dbc4f340105`
- occurred: `2026-08-16T23:58:22Z`
- prompt SHA-256:
  `be823143a1d47a72e5db1ca3d6240aa9a9a3167dc4425a29d1ef7745ec1a400f`
- output: 2172×724 RGB PNG, 1,618,252 bytes
- output SHA-256:
  `c6c957b56d8601504c73f553eda7a80bdf27f7b2bdf809562f0b766ac0bd311c`
- decision: rejected — checkerboard remained baked RGB

```text
Preserve this A1-07 hanok construction object exactly: same 2172×724 canvas, stone foundation and front steps, cornerstone bases, seven primary columns, horizontal changbang and beams, carts, timber stacks, perspective, scale, colors, lighting, and every object position. Change only the background. Remove the entire gray-and-white checkerboard and all background pixels, producing genuine transparent RGBA alpha around the object to every canvas edge. Do not repaint, crop, resize, move, add, or remove any part of the construction. Do not add purlins, rafters, roof, walls, floors, doors, windows, landscape, ground, shadows, text, labels, UI, border, watermark, black/white matte, or chroma. Final output must remain exactly 2172×724 and must use real transparent pixels, not an illustrated checkerboard.
```

## 3. Recraft 배경 제거 — geometry 통과, 의미 거절

- task: `14b2fe52f6b88d171714ec32adc0e864`
- model: `Recraft Remove Background`
- occurred: `2026-08-17T00:00:37.826628Z`
- cost: 0.3 BBANANA credits
- prompt SHA-256: empty prompt
  `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- output: 2172×724 RGBA PNG, 1,724,987 bytes
- output SHA-256:
  `85a53d16e13bf5869e45a52574f8fdba266e0a414fb4e42bfbb3a5460394238b`
- decision: rejected — true alpha와 foundation geometry는 통과했지만 중간 벽선과
  보조 기둥이 A1-12 수장 공정을 앞당겨 표현함

## 4. 구조 의미 수정 — alpha 때문에 거절

- generation: `exec-b9eeee42-168e-48aa-b774-a80d7ccb1c7d`
- occurred: `2026-08-17T00:02:54Z`
- prompt SHA-256:
  `bbf129bbd29ad244d21fb6402df89d8913d645bd646c9b97384daa78db9a43d2`
- output: 2172×724 RGB PNG, 1,388,410 bytes
- output SHA-256:
  `62e869ee9f497d223949349bc3e5c7915fa2429a92af0ed4a5e02e80a3ae8833`
- decision: rejected — 기둥 7개와 상부 결구만 남기는 의미 수정은 통과했지만
  checkerboard가 실제 RGB 픽셀로 구워짐

```text
Correct this transparent A1-07 beams/changbang construction layer while preserving the 2172×724 canvas, foundation, steps, cornerstone bases, timber stacks, perspective, scale, lighting, and top horizontal beams/changbang. Keep exactly the same seven primary upright columns that correspond to the prior A1-06 stage. Remove every thin mid-height horizontal rail across the wall bays, because middle/lower wall framing belongs to the later A1-12 sujang stage. Remove any duplicate, secondary, or rear upright posts so only seven primary columns remain. Preserve the upper horizontal main beam/changbang joinery at the column tops; do not remove it. Do not add purlins, rafters, roof, wall framing, walls, floors, doors, windows, landscape, ground, people, tools, text, UI, border, or watermark. Output exactly one 2172×724 true-transparent RGBA PNG with alpha to every edge, no checkerboard, matte, or chroma. The approved foundation footprint and scale must not move; the only structure above the columns is the upper beams/changbang.
```

## 5. 최종 alpha 복구 — 승인

- task: `d9e21709256e9cdebf3041c70394b608`
- model: `Recraft Remove Background`
- occurred: `2026-08-17T00:03:20.647515Z`
- cost: 0.3 BBANANA credits
- prompt SHA-256: empty prompt
  `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- raw output: 2172×724 RGBA PNG, 1,558,117 bytes
- raw SHA-256:
  `7d5bafe5720a2f6de555c2540eff326ee7352237495d997b6818aba09f32d0c0`
- decision: approved QA-only

정규화 레이어는 854×309 RGBA, 228,583 bytes, alpha 35.83%, anchor 991,
chroma 0이다. A1-06과 아래 80px foundation mask의 alpha IoU는 0.969821이고
좌우 edge drift는 0px다. 결정론적 합성 WebP는 1536×1152 RGB, 278,848 bytes,
source socket 밖 변경 0, decoded socket 밖 평균 오차 3.39198이다.

## 런타임 경계

모든 파일은 `assets_unused/pending_review/`에 있는 QA 자산이다. PR4에서 전체
A1 01–16 상태와 썸네일·메모리·시각 QA가 끝나기 전에는 `pubspec.yaml`이나
production route에 등록하지 않는다.
