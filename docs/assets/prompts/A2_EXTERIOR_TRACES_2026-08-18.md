# A2 외관 흔적 4종 — 생성 원장 (2026-08-18)

hanok 원장(provenance) 관할. 참조는 allowlist `sarangchae.png` 1장만 사용했다.

---

## 0. 시도 1 — 탈락 (Nano Banana Pro, 4cr)

`25664c7a3794d475cbb181c982cee633` · Nano Banana Pro · 2K · 4:3 · 참조 1장(sarangchae.png).
A1 소품 시트가 썼던 정확한 프롬프트 골격(`a1_kit_prompts.json`의 `5baedfca…`)을 오브젝트 목록만
바꿔 그대로 재사용했으나, 결과가 **부드러운 수채/그라데이션**으로 나와 A1 소품(각진 면분할)과
어긋났다. A1 소품들은 각목·석재처럼 원래 각진 재질이라 우연히 faceted로 나왔을 뿐, 연기·까치·
항아리·등롱처럼 유기적인 대상에는 같은 문구로도 부드럽게 그려진다는 것을 이번에 확인했다.
산출물은 `assets_unused/pending_review/estate_overlays/raw/exterior_props_sheet_v1.png`
(폐기, 런타임 미사용).

## 1. 시도 2 — 채택 (GPT Image 2, 4cr)

`task-unified-1787045881-08w10ryc` · GPT Image 2 · 2K · 4:3 · 참조 1장(sarangchae.png, 동일).
A2 가구 12종에서 검증된 "LOW-POLY FACETED planes — every surface is broken into flat angular
colour facets like folded paper" 명시적 문구를 그대로 가져와 각 오브젝트 설명에도 "faceted
paper-cutout", "flat angular facets"를 박아 넣었다. 결과가 A1 소품과 같은 면분할 화풍으로
나와 채택.

산출물: `assets_unused/pending_review/estate_overlays/raw/exterior_props_sheet_v2.png`
(2368×1776 RGB, sha256 확인은 각 컷 파일에 기록).

### 프롬프트 원문

```
Create a clean sprite sheet in exactly the same illustrated style as the attached reference building (a traditional Korean hanok estate map: LOW-POLY FACETED planes — every surface is broken into flat angular colour facets like folded paper, NO drawn outlines, matte finish, subtle hanji paper grain visible inside the facets, warm wood/stone colors, top-left lighting).

Flat pure #00FF00 chroma-key green background, each object fully separated from the others with generous green space between them, no ground, no cast shadows on the ground, no text, no labels, no people.

Objects, all seen from the front and slightly above (same camera as the reference), arranged in a loose grid:
1. a thin rising column of pale grey-white chimney smoke, built from flat angular puffs like folded paper stacked upward, narrow at the bottom and wider at the top, no soft blur, no transparency gradient;
2. one small Korean magpie perched, side view facing left, made of flat angular colour facets like the reference building — black head and back, white belly and shoulder patch, long dark tail — NOT a soft painterly bird, a faceted paper-cutout bird; standing on nothing (feet at the bottom edge of the cutout);
3. two dark-brown glazed Korean onggi jars (jangdok) side by side, one slightly larger, built from flat angular facets, each with a wide belly, a narrow mouth and a flat lid;
4. a hanging paper lantern, LIT: warm ivory-yellow paper glowing softly from within as one flat glowing facet (not a smooth gradient), dark wood frame top and bottom, no external glow halo, no rays.

Every object is a complete, self-contained cutout with crisp faceted edges — same construction-material faceting as the reference building's stone chimney and wood beams. Restricted palette: walnut #8E6646 #7E5A3D #5C4028 #3E3024, stone #8B8478, cream #FAF6EC, dancheong gold #DFA951, slate #2A3340, onggi brown #4B2E1E, magpie black #1A1410, magpie white #F4E8D0.

ABSOLUTELY AVOID: smooth painterly rendering, soft gradients, watercolour blending, photorealism, glossy 3D render, black outlines, text, labels.

IMPORTANT: match the geometric faceted style of the attached reference building exactly. This must look like part of the same illustrated set.
```

## 2. 컷 (0cr, 결정론)

시트가 예상과 달리 **5개** 블록으로 갈렸다(장독 2개가 서로 안 붙어 각자 컴포넌트) — 4개를 요청했지만
2번 항목이 "two jars side by side"만 쓰고 "touching"을 못 박지 않아서다. `tool/cut_prop_sheet.py`의
`reading_order()`는 연기의 세로로 긴 bbox가 다른 모든 오브젝트의 y범위를 덮어 한 "행"으로 묶어버려
x좌표만으로 정렬되고, 그 결과 아래쪽 행에 있는 등롱이 중간 순서로 끼어드는 문제가 있었다. 신규
`tool/cut_a2_exterior_sheet.py`는 top 좌표만으로 정렬해 실제 사진과 대조 확인한 순서
(연기188 · 큰항아리310 · 까치363 · 작은항아리399 · 등롱933)를 그대로 쓴다.

```bash
/usr/local/bin/python3.12 tool/cut_a2_exterior_sheet.py \
  assets_unused/pending_review/estate_overlays/raw/exterior_props_sheet_v2.png \
  assets_unused/pending_review/estate_overlays/cut \
  --report assets_unused/pending_review/estate_overlays/qa/cut_report.json
```

| 파일 | 크기 | chroma 잔여 | green rim |
|---|---|---:|---:|
| `a2_chimney_smoke.png` | 40×160 | 0 | 4px |
| `a2_jangdok_big.png` | 44×53 | 0 | 0 |
| `a2_ridge_magpie.png` | 42×26 | 0 | 3px |
| `a2_jangdok_small.png` | 36×44 | 0 | 0 |
| `a2_lantern_lit.png` | 20×38 | 0 | 0 |

크기는 기존 A1 소품(`prop_lantern` 16×31, `prop_chimney` 24×38, `prop_flower_pots` 30×34)과
같은 스케일대에 맞췄다.

## 3. 합성 (0cr, 결정론) — `tool/compose_a2_exterior_overlays.py`

매니페스트 `docs/assets/hanok_a2_overlays/overlays.json`. 좌표는 소켓 offset (160,614)
(`docs/assets/HANOK_V1_ASSET_PROVENANCE.json` `camera.socket`)를 기준으로 계산:

| id | 소켓 좌표 근거 | 캔버스 anchor | zone |
|---|---|---|---|
| `a2_chimney_smoke` | 굴뚝(842,306)=canvas(1002,920) 상단(높이38) 위 | (1002,882) bottom-center | [970,700,1035,890] |
| `a2_lantern_lit` | 기존 `prop_lantern`(700,188)=canvas(860,802)와 동일 자리 | (860,802) bottom-center | [840,750,880,815] |
| `a2_ridge_magpie` | 용마루 실측 socket y17-20→canvas y631-634, x범위 310-860 중 x=550 | (550,632) bottom-center | [500,595,600,640] |

세 오버레이 모두 **zone 밖 alpha 위반 0**으로 통과했다. `assets/illustrations/personal_hanok_v2/a1/states/16_landscape_move_in.webp`
의 sha256(`2e460f1e3243…`)은 합성 전후 **불변**(읽기만 했다, 오버레이는 별도 파일).

`장독 2개는 매니페스트에 없다` — 최종 위치가 아직 Jin 확정 전이라 후보 2곳만 QA로 렌더했다:
- 후보 A `jangdok_candidate_A_anchae_courtyard.png` — 안채 자리 안뜰, anchor (905,598)
- 후보 B `jangdok_candidate_B_sarangmadang.png` — 사랑채 옆 마당, anchor (1060,905)

## 4. 아직 하지 않은 것

- **런타임 배선 없음.** `map/overlays/`는 pubspec에 선언되지 않았고 `personal_hanok_catalog.dart`에
  레이어 항목도 없다 — `asset_orphan_guard_test`가 막는다. 배선은 PR5b(디렉터리 선언 1줄 + 카탈로그
  엔트리 + `tool/promote_estate_layers.py` 신규)에서 한다.
- **원장(ledger) 미기록.** `HANOK_V1_ASSET_PROVENANCE.json`에 `kind: estateLayer` 레코드를
  아직 추가하지 않았다 — Jin 승인 뒤 기록한다.
- **장독 위치 미확정** — 위 후보 2장 중 Jin이 고른다.

## 5. 크레딧

| 항목 | cr |
|---|---:|
| 시도 1(탈락, Nano Banana Pro) | 4 |
| 시도 2(채택, GPT Image 2) | 4 |
| **합계** | **8** |

착수 잔액 623.9 → 617.2(다른 세션과 공유되는 잔액이라 차이 6.7 중 실제 이 작업분은 8 — 반올림/동시
차감 오차).
