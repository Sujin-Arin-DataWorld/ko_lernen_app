# Hanok V1 A1-07 beams/changbang rejected attempt — 2026-08-17

## 호출

- generation: `exec-dd61711c-8e20-41d6-ac7a-1eb489918480`
- occurred: `2026-08-16T23:49:56Z`
- input: approved `06_columns` raw, SHA
  `e4c4c6874bde2c35b96aa4d5964cd914e9e30d1f74c6fe77f2bebf6b653b37a9`
- prompt SHA-256: `a3d3f33500f2c11144346885cd5de025c3fc8883f589a693cab1a08885b6d26a`
- output: 1802×873 RGB PNG, 1,503,129 bytes
- output SHA-256: `17f61d8502f57fee6dd4ba7d8b319d819de93ac8eda1635f4cc4e8d783c3c63e`
- decision: rejected

프롬프트:

```text
Edit this approved project-owned transparent A1-06 hanok construction layer into the next cumulative stage, 07_beams_changbang. Preserve the stone foundation/gidan, front steps, every cornerstone, all seven upright columns, carts, remaining measured timber stacks, exact column spacing, perspective, scale, warm faceted-minhwa wood and stone style, and top-left lighting. Add only the structurally plausible horizontal changbang rails and main timber beams that join and lock the tops of the existing columns into one frame. Show clearly visible mortise-and-tenon timber connections; use a small portion of the prepared timber so the remaining stacks still appear. Do not add purlins or ridge members above the beam line, rafters, eaves, roof base, thatch or tiles, walls, plaster, floors, ondol, doors, windows, tools, workers, people, animals, landscape, ground, sky, shadow plane, text, labels, UI, border, or watermark. Output one isolated wide front-oblique construction layer on genuine transparent RGBA alpha with clean edges and transparent pixels to every canvas edge. No checkerboard, black/white matte, or chroma background. The immediately preceding A1-06 geometry must remain visually continuous; the only new construction is beams and changbang.
```

## 거절 이유와 후속 계약

보·창방의 의미는 보였지만 생성기가 체크무늬를 픽셀로 구운 RGB를 반환했다. 또한
입력 2172×724의 넓은 footprint 대신 1802×873의 좁고 높은 구도로 재배치했다. 이를
기존 bbox-fit 정규화에 넣으면 기단 폭과 기둥 간격이 축소되어 단계 전환 때 집 전체가
움직인다. alpha-only 수정으로 승인하지 않았다.

후속 호출 전 compositor에 cumulative continuity gate를 추가했다. 직전 승인 normalized
layer와 새 layer의 아래 80px foundation alpha mask가 IoU 0.94 이상이고 좌우 footprint
edge drift가 12px 이하여야 한다. 다음 A1-07 후보는 처음부터 A1-06과 같은 wide canvas,
foundation width, column position/scale을 유지해야 한다.
