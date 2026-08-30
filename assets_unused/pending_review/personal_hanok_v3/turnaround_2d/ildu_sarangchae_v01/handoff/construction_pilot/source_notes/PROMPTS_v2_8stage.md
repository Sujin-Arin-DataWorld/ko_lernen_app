# 2026-08-29 사랑채 6·7단계 수정 프롬프트

모드: Codex 내장 `image_gen` 편집 모드.

## 6단계 — 지붕 바탕만

편집 대상: 기존 `stage_06_roof_bed_tiles.png`
구조 참조: `stage_05_rafters_sanja.png`

```text
Use case: precise-object-edit
Asset type: cumulative construction sprite for a Flutter learning game
Primary request: Correct only the roof construction state. Remove every finished
dark grey or black clay roof tile from the right numaru roof, roof junction,
ridges, and every roof plane. Replace them with continuous unfinished traditional
Korean roof substrate: tightly tied laths/sanja, woven reed and straw matting,
and even packed straw-earth/mud roof bed.
Constraints: preserve the exact L-shaped building geometry, timber frame, stone
foundation, stairs, camera and ground contact; keep wall/changho openings empty;
transparent background; no completed tiles anywhere.
```

생성 원본 SHA-256:
`4f653c167610b94d520e8ce020e916d6bf4c23c22723a8ab700abd9e503396d2`

## 7단계 — 벽체·창호 설치 중

편집 대상: 기존 `stage_07_walls_changho.png`
정체성 참조: byte-identical `stage_08_complete_v3.png`

```text
Use case: precise-object-edit
Asset type: cumulative construction sprite for a Flutter learning game
Primary request: Keep the tiled roof complete, but show only 60–70 percent of
wall and changho work installed. Across the front bays mix finished wooden
frames without hanji, partial lattice members, partially papered lattice, and at
least two visibly unfinished openings. Preserve the numaru railing and leave its
outer bays partly open.
Constraints: change only wall/changho completeness; preserve roof, eaves, posts,
beams, foundation, stairs, camera, scale and ground contact; transparent
background; no fully finished row and no redesign.
```

생성 원본 SHA-256:
`4e372c37669a416a62fe6c82ae32b7d044493a339584510d8e9ce5ad1e60e455`
