# P2a 개인 한옥 완성 지도 — 에셋 제작 시트

**상태:** 제작 중

**정본 설계:** `docs/superpowers/specs/2026-08-04-personal-hanok-compound-growth-design.md`

## 공통 공간 계약

- 캔버스 기준: `site_base.png`는 정확히 **1536×1152, 4:3**. 모든 좌표는 이 기준의 분수다.
- 카메라: 남쪽 솟을대문을 아래에 둔 **elevated three-quarter plan**, 위에서 약 35° 내려다보는 한옥 배치도 시점.
- 광원: 왼쪽 위. 모든 기와·기둥·돌의 그림자 방향은 오른쪽 아래.
- 화풍: Faceted Minhwa. 각진 색면, 절제된 한지 결, `#FAF6EC #2A3340 #1A2028 #8E6646 #5C4028 #8B8478 #3D9A7F #C24A45 #DFA951` 중심 팔레트, 검은 외곽선·매끈한 그라데이션 금지.
- base만 불투명이다. 건물 레이어는 PNG `RGBA`, 모서리 4곳 alpha 0, chroma `#00FF00` 잔류 0이어야 한다.
- 구조물은 바닥 접점만 가진다. 벽·길·수목·다른 건물·사람·텍스트·아이콘·잠금 표식은 어떤 구조 레이어에도 넣지 않는다.

## 배치 좌표

| id | left | bottom | width | z | 역할 |
|---|---:|---:|---:|---:|---|
| `anchae` | 0.18 | 0.50 | 0.43 | 20 | 윗 안마당을 남쪽으로 열어 둔 ㄷ자 안채 |
| `sadang` | 0.74 | 0.52 | 0.17 | 동쪽 별도 담장 안의 사당 |
| `haengrangchae` | 0.11 | 0.24 | 0.25 | 서쪽/전면의 행랑채 |
| `sarangchae` | 0.22 | 0.18 | 0.42 | 긴 남향 사랑채, 기존 사랑방 진입점 |
| `sotdaeulmun` | 0.46 | 0.02 | 0.16 | 남쪽 정문 |
| `daecheongmaru` | 0.57 | 0.38 | 0.15 | 두 마당 사이의 열린 대청마루 |
| `gye_pond_large` | 0.62 | 0.09 | 0.27 | 개인 후원 연못, 기존 파일 직접 재사용 |
| `gye_bridge` | 0.68 | 0.075 | 0.15 | 개인 후원 돌다리, 기존 파일 직접 재사용 |

## 기존 자산 재사용

`assets/illustrations/gye/gye_pond_large.png`와
`assets/illustrations/gye/gye_bridge.png`만 개인 후원의 같은 milestone으로
직접 참조한다. 두 파일은 복사하지 않고, 개인 `PersonalHanokProgress`가
나중에 해금 여부만 결정한다. `GyeMeta`, 계 weekly goal, 계 pulse, 계 저장값은
절대 읽지 않는다.

`gye_gate_grand`, `gye_haenglangchae`, `gye_byeoldang`, `gye_jeongja`는 화풍
레퍼런스일 뿐, 개인 지도에는 넣지 않는다. 이들은 도면형 elevated-plan보다
앞/3분할 시점이라 실제 발자국이 어긋난다.

## 생성 프롬프트

### `site_base.png`

```text
Use case: historical-scene
Asset type: opaque 4:3 ground layer for an interactive Korean Hanok compound map
Input images: traditional-plan mockup = layout reference; gye_pond_large.png = material and Faceted Minhwa reference
Primary request: an empty, elevated-plan Joseon jongga compound ground plane, asymmetrical traditional layout. South/front outer wall has an open reserved footprint for a raised main gate. Lower-left and lower-center reserve a long sarangchae footprint; a smaller west service-wing footprint sits nearby. Upper inner court reserves a large U-shaped anchae footprint. A separated east shrine enclosure has an empty building footprint. A clear open-hall footprint connects the courts. In the lower-right rear garden leave an empty pond basin and a short curved path for a bridge.
Scene/backdrop: warm hanji cream terrain, pale stone perimeter walls, sandy paths, restrained rocks and low planting only; no sky, no people, no text.
Style/medium: Faceted Minhwa, angular color planes, subtle hanji grain, upper-left light, elevated three-quarter plan camera.
Composition/framing: exactly 4:3 landscape, full compound visible with 4% outer hanji margin; all seven future elements have open, uncluttered ground anchors.
Constraints: no completed building, no roof, no gate, no pond water, no bridge, no colored circles, no labels, no placeholder pads, no white rectangle, no cast object shadow beyond terrain.
Avoid: outlines, isometric game tiles, Chinese/Japanese architecture, random cranes, photorealism, 3D render, watermark, text.
IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like part of the same illustrated set.
```

### `sotdaeulmun.png`

```text
Use case: stylized-concept
Asset type: transparent layer for the south entrance of a Korean Hanok master map
Primary request: one raised traditional Korean sotdaeulmun gate, south-facing in an elevated three-quarter plan camera, dark curved tiled roof, warm walnut double doors, correct Korean upturned eaves, granite step, restrained dancheong under the eaves.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for removal.
Style/medium: Faceted Minhwa, angular planes, subtle hanji grain, upper-left light.
Composition/framing: gate alone, full object inside canvas, generous 8% clear margin, grounded at the bottom edge.
Constraints: no wall, no terrain, no people, no trees, no signboard text, no cast shadow, no #00ff00 on the object.
Avoid: outline drawing, Chinese pagoda roof, Japanese torii, photorealism, watermark, text.
IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like part of the same illustrated set.
```

### `haengrangchae.png`

```text
Use case: stylized-concept
Asset type: transparent west service-wing layer for a Korean Hanok master map
Primary request: one low traditional Korean haengrangchae service wing, shorter and humbler than the sarangchae, viewed in the same elevated three-quarter plan camera, dark tile roof, warm wooden pillars, pale plaster panels, low stone foundation.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for removal.
Style/medium: Faceted Minhwa, angular planes, subtle hanji grain, upper-left light.
Composition/framing: building alone, front edge grounded at the bottom edge, generous clear margin.
Constraints: no jars, no walls, no paths, no trees, no people, no gate, no neighboring building, no cast shadow, no #00ff00 on the object.
Avoid: outline drawing, Chinese/Japanese architecture, photorealism, watermark, text.
IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like part of the same illustrated set.
```

### `sarangchae.png`

```text
Use case: stylized-concept
Asset type: transparent long guest-and-study wing for a Korean Hanok master map
Primary request: one long south-facing traditional Korean sarangchae in an elevated three-quarter plan camera, dark tiled roof, visible warm wooden porch, central open threshold that hints at a daecheong, lattice doors, stone foundation; clearly a long horizontal wing.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for removal.
Style/medium: Faceted Minhwa, angular planes, subtle hanji grain, upper-left light.
Composition/framing: building alone, 8% clear margin, bottom ground anchor, designed to sit in the lower central court.
Constraints: no furniture, no people, no wall, no terrain, no trees, no gate, no other building, no cast shadow, no #00ff00 on the object.
Avoid: outline drawing, photorealism, watermark, text.
IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like part of the same illustrated set.
```

### `anchae.png`

```text
Use case: stylized-concept
Asset type: transparent inner-residence layer for a Korean Hanok master map
Primary request: one U-shaped Korean anchae inner residence in an elevated three-quarter plan camera. The high dark tiled roof forms a U around an open inner court that opens toward the south/lower edge. Warm walnut columns, pale plaster, wooden lattice doors, stone base.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for removal.
Style/medium: Faceted Minhwa, angular planes, subtle hanji grain, upper-left light.
Composition/framing: building alone, bottom anchor, generous clear margin; the U-shaped silhouette must remain legible at small size.
Constraints: no furniture, no people, no wall, no terrain, no trees, no gate, no pond, no cast shadow, no #00ff00 on the object.
Avoid: outline drawing, a closed rectangular house, photorealism, watermark, text.
IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like part of the same illustrated set.
```

### `daecheongmaru.png`

```text
Use case: stylized-concept
Asset type: transparent open-hall layer for a Korean Hanok master map
Primary request: one compact roofed but visibly open Korean daecheongmaru, an airy wooden great hall between courts, elevated three-quarter plan camera, visible floorboards and open pillars, dark tile roof, warm walnut wood, stone base.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for removal.
Style/medium: Faceted Minhwa, angular planes, subtle hanji grain, upper-left light.
Composition/framing: single hall only, bottom anchor, generous clear margin.
Constraints: no furniture, no people, no wall, no terrain, no trees, no gate, no closed house facade, no cast shadow, no #00ff00 on the object.
Avoid: outline drawing, photorealism, watermark, text.
IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like part of the same illustrated set.
```

### `sadang.png`

```text
Use case: stylized-concept
Asset type: transparent ancestral-shrine building layer for a Korean Hanok master map
Primary request: one compact dignified Korean sadang in a separate east enclosure, elevated three-quarter plan camera, traditional dark tiled roof, restrained dancheong under eaves, closed lattice doors, stone threshold.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for removal.
Style/medium: Faceted Minhwa, angular planes, subtle hanji grain, upper-left light.
Composition/framing: building alone, bottom anchor, generous clear margin.
Constraints: no ancestor portraits, no tablets, no incense, no furniture, no people, no wall, no garden, no neighboring roof, no cast shadow, no #00ff00 on the object.
Avoid: outline drawing, photorealism, watermark, text.
IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like part of the same illustrated set.
```

## 합격 기준

1. `python tool/check_hanok_compound_assets.py`가 7개 파일 모두 `[pass]`와 exit `0`을 낸다.
2. `site_base`는 배치 지점을 가리는 완성 건물이나 마커가 없다.
3. 구조물 6종은 흰 사각·초록 fringe·배경/지형·옆 건물이 없고, 모서리가 완전 투명이다.
4. 360×270, 600×450, 800×600, 1280×960 합성에서 각각의 채와 연못/다리가 서로 구분된다.
5. 연못과 다리는 `assets/illustrations/gye/`의 기존 파일을 참조하며, 어떤 Gye progress/state도 참조하지 않는다.

## 확정 runtime path 목록

```text
assets/illustrations/hanok_compound/site_base.png
assets/illustrations/hanok_compound/sotdaeulmun.png
assets/illustrations/hanok_compound/haengrangchae.png
assets/illustrations/hanok_compound/sarangchae.png
assets/illustrations/hanok_compound/anchae.png
assets/illustrations/hanok_compound/daecheongmaru.png
assets/illustrations/hanok_compound/sadang.png
assets/illustrations/gye/gye_pond_large.png
assets/illustrations/gye/gye_bridge.png
```
