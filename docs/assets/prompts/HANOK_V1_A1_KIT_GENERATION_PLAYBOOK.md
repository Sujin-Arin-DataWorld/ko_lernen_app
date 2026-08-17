# A1 부품 키트 생성 플레이북 (2026-08-17, 검증됨)

이 문서는 A1 단계 이미지를 **같은 품질로 재현**하기 위한 실행 지침이다. 성공한 프롬프트
원문, 모델 설정, BBANANA task ID, 정렬 파라미터를 그대로 담는다. 새 세션은 이 문서만
읽고 이어서 작업한다. 계약(무엇이 허용되는가)은
`HANOK_V1_A1_TRANSPARENT_LAYER_CONTRACT.md`, 매핑 설계는
`docs/superpowers/specs/2026-08-17-living-hanok-v1-mapping-kit-pipeline-design.md`.

## 0. 작업 위치·불변 규칙

- 워크트리 `C:/Users/vjinn/.codex/worktrees/ko_lernen_app-hanok-a1-kit`, 브랜치
  `claude/hanok-a1-kit-20260817`. **메인 트리·main 브랜치는 건드리지 않는다**(Jin 지시).
- 산출물은 전부 `assets_unused/pending_review/a1_kit/` (raw / generated / qa / model_inputs).
  런타임(`assets/`)·pubspec은 Jin 장별 승인 + ledger 기록 뒤에만 건드린다.
- 생성 모델 입력 allowlist는 지금도 3개뿐이다. **실제로 쓰는 것은 완성 사랑채 1장**:
  BBANANA 업로드 URL
  `https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/upload-storage/mcp-f523e93ff70040cef5066ee93caeb1e2.png`
  (= `assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png`, sha `f523e93f…`).
  hanokdb·서울포털·비바샘 이미지, Jin 화면, `hanok_stages/`·`gye/`·`hanok_compound/`는 입력 금지.
- 완성 사랑채 기하는 **앞기둥 8개 · 칸 7개**다(2026-08-17 Jin 확인). 7+7 안은 폐기.

## 1. 모델 설정 (이 조합만 성공했다)

| 항목 | 값 |
|---|---|
| 모델 | `Nano Banana Pro` (`edit_image` / `generate_image`) |
| 해상도 | `2K` |
| 비율 | **21:9** (건물 단계) / 4:3 (소품 시트) |
| 크레딧 | 호출당 4 |
| 배경 지시 | `flat pure #00FF00 chroma-key green, no gradient` |

**4:3으로 건물을 편집하면 모델이 캔버스를 다시 잡아 전체를 축소한다**(2026-08-17 task
`260fb03750d14f34a4c5674d293cc78d`에서 실측). 건물 단계는 21:9 + 아래 §2 수치 블록을 쓴다.

## 2. 필수 수치 블록 (건물 단계 프롬프트에 그대로 넣는다)

```
CRITICAL PROPORTIONS — obey exactly, the building is extremely wide and low:
- total width of the stone platform: 854 units;
- the eight front columns are only 87 units tall (about one tenth of the width);
- from the top of the stone platform to the ridge beam at the very top: only 240 units;
- so the whole structure is about 3.5 times wider than it is tall. Draw a long, low,
  horizontal frame — NOT a tall barn.
```

이 블록이 없으면 모델은 기둥이 폭 대비 4배 높은 헛간을 그리고, 정렬 시 2~3배 비등방
찌그러짐이 난다(task `260fb037…`에서 a/c=2.39 실측).

## 3. 검증된 프롬프트 원문

### 3.1 07·08 골조 — task `p9hh9hpgk9rmy0d01zb80bs7v0` (채택)

`edit_image(model="Nano Banana Pro", image_url=<완성 사랑채>, aspect_ratio="21:9", resolution="2K")`

```
Redraw the attached finished Korean hanok (a long, very wide and low seven-bay
sarangchae) as the SAME building at the timber-frame stage, before the roof was
covered and before any wall, door or window was fitted. Same camera as the attached
image: straight from the front, only slightly above eye level, no rotation, no
perspective change.

<§2 수치 블록>

Keep from the attached image, in the same position and size: the long stone platform
with its central stone steps, the small stone column bases, and the eight front
wooden columns (same thickness, same spacing, corner columns at both ends).

Remove: every roof tile, the ridge tiles, the roof boards, all plaster walls, all
lattice doors and paper windows. The frame must be open so the sky shows through it.

Draw the exposed hanok timber frame in the same faceted painterly wood style and warm
walnut colours as the columns:
- eight rear columns on the back edge of the platform, one directly behind each front
  column, mostly hidden behind them so only their heads and the gap between them show;
- a square capital block on every column head;
- one long continuous head beam along the front row and another along the rear row;
- eight short cross beams, each running from a front column head straight back to the
  rear column head behind it;
- above them a second, higher tier of two long purlins carried on short posts;
- one ridge beam at the very top running the whole length, carried on short king posts;
- one diagonal brace closing each end.
No rafters, no roof boards, no tiles, no walls, no floor boards, no ground, no shadow
on the ground, no people, no text.

Background: flat pure #00FF00 chroma-key green everywhere outside the object, no
gradient, no vignette.
```

산출 `assets_unused/pending_review/a1_kit/raw/07_frame_v2_p9hh9hpg.png`.

### 3.2 09 서까래 — task `gvi_1786972511933_46an1e` (채택)

`edit_image(image_url=<3.1의 결과 URL>, 21:9, 2K)` — **이전 단계 결과를 베이스로 이어 쌓는다.**

```
Continue building the same wooden hanok frame shown in the attached image. Keep every
existing timber exactly where it is: the stone platform, the stone bases, the eight
front columns, the rear columns, the capital blocks, the head beams, the cross beams,
the two purlin tiers, the ridge beam and the end braces must all stay unchanged in the
same position, size and colour. Keep the same camera, same framing, same scale, same
lighting, and the same flat pure #00FF00 chroma-key background.

ONLY ADD the rafter layer of a Korean hanok roof:
- about forty-five straight round rafters laid side by side, evenly spaced, each
  running from the ridge beam at the top down over the purlins to the eaves, forming
  the two sloping roof planes;
- the rafters overhang beyond the head beam at the bottom so their cut ends make a neat
  row along the eave line;
- one thin continuous eave batten laid across the rafter ends;
- at each of the four corners, one thicker hip rafter set at forty-five degrees,
  sticking out slightly further than the others.

Still NO roof boards, NO clay, NO tiles, NO walls, NO doors, NO floor, NO ground, NO
people, NO text. The sky must still show between the rafters. The finished silhouette
must stay as wide and low as in the attached image; do not make the roof taller.
```

산출 `raw/09_rafters_gvi46an1e.png`.

### 3.3 10 개판·산자·보토 — task `35cc41266087587f901b7a0e141aab82` (채택)

`edit_image(image_url=<3.2의 결과 URL>, 21:9, 2K)`

```
Continue building the same wooden hanok shown in the attached image. Keep the stone
platform, the stone bases, all columns, the beams, the purlins and the ridge exactly
where they are, same size, same colour, same camera, same framing, same lighting, same
flat pure #00FF00 chroma-key background.

ONLY ADD the layers that go on top of the rafters, in this order, so the roof planes
become closed but still bare:
- thin wooden roof boards laid across the rafters, covering both sloping planes;
- on top of them a rough layer of woven twigs and small wood scraps;
- on top of that a thick, smooth layer of brown-grey earth, spread evenly and slightly
  rounded so the roof already shows the gentle hanok curve;
- leave the bottom row of cut rafter ends visible along the eave line, below the earth
  layer;
- leave the ridge line as bare earth, with no ridge tiles.

Still NO clay roof tiles of any kind, NO walls, NO doors, NO windows, NO floor boards,
NO ground, NO people, NO text. Keep the silhouette exactly as wide and low as in the
attached image; do not raise the roof.
```

산출 `raw/10_roofbase_35cc4126.png`.

### 3.4 소품 시트 15종 — task `5baedfcabb9a487981741880369c800e` (채택)

`generate_image(model="Nano Banana Pro", image_urls=[<완성 사랑채>], aspect_ratio="4:3", resolution="2K")`

```
A clean sprite sheet of isolated construction-site props for a traditional Korean
hanok, drawn in exactly the same faceted, painterly illustration style, warm
wood/stone colors and top-left lighting as the attached reference building. Flat pure
#00FF00 chroma-key green background, each object fully separated from the others with
generous green space between them, no ground, no cast shadows on the ground, no text,
no labels, no people, no animals.

Objects, all seen from the front and slightly above (same camera as the reference),
arranged in a loose grid:
1. a bundle of five roughly squared timber beams tied with straw rope, resting on two
   log rollers;
2. a second, smaller bundle of round logs tied with rope, on log rollers;
3. a low sawhorse (a wooden trestle) with one squared beam lying on it;
4. four wooden survey stakes with a thin white string stretched between them forming a
   rectangle;
5. a wooden drawing board on a low trestle with a rolled plan on it;
6. a small stone stepping stone with a pair of traditional white rubber shoes placed
   neatly on it;
7. a hanging paper lantern with a small wooden frame;
8. a rolled bamboo blind;
9. two small glazed flower pots with a green plant;
10. a short chimney made of stacked stone with a small tiled cap;
11. a low arched firebox opening framed with dark stones;
12. a small pile of clay roof tiles;
13. one square wooden capital block (the block that sits on top of a column);
14. one short wooden king post;
15. one diagonal wooden brace.

Every object is a complete, self-contained cutout with crisp edges. Restricted palette:
walnut #8E6646, #7E5A3D, #5C4028, #3E3024, stone #8B8478, cream #FAF6EC, dancheong gold
#DFA951, slate #2A3340. Subtle hanji paper grain on the objects only. Aspect ratio 4:3.
```

산출 URL `.../bbanana/1786971320877.jpg` (다운로드해 `raw/`에 두고 오브젝트별로 잘라 쓴다).

### 3.5 13 흙벽 초벽 텍스처 — task `bce56a89247c1aa410dfd7d7602e8795` (채택)

`generate_image(model="Nano Banana Pro", image_urls=[<완성 사랑채>], aspect_ratio="4:3", resolution="2K")`

```
A flat, seamless wall TEXTURE — no objects, no building, no scene, no border, no
frame, no text — filling the whole image edge to edge.

Subject: the rough first coat of a traditional Korean earth wall (초벽), the layer
applied before any white finishing plaster. Wet ochre clay mixed with chopped rice
straw, pressed by hand between timber members: warm yellow-brown earth with straw
fibres and small pebbles showing through, shallow trowel dents and hand marks, a few
darker damp patches and a few paler dried patches, faintly visible woven twig lath
texture under the surface in a couple of places.

Style: exactly the same faceted, painterly illustration style, restricted palette,
subtle hanji paper grain and soft top-left lighting as the attached reference building
— the same hand painted this. Keep the palette close to earth #8E6646, #7E5A3D,
#5C4028, straw cream #FAF6EC and a little slate #2A3340 in the deepest dents. No
strong highlights, no gloss, no vignette, no drop shadow, even flat lighting overall
so the texture can be tiled. Straight-on view, perfectly frontal, no perspective.
```

산출 `raw/13_earthwall_texture_bce56a89.png`. **주의:** 원본은 밝은 마른 황토여서 소켓
크기에서 뒷배경 땅색과 구분이 안 된다. `make_kit_parts.py`가 `EARTH_TONE=(0.84,0.76,0.66)`
로 눌러 젖은 초벽 톤을 만들고 `EARTH_TEXTURE_SCALE=10`으로 짚 결을 잘게 줄인다(부품에
구워 넣음, 합성 후 후처리 아님).

### 3.6 폐기 사례 (반복하지 말 것)

- task `260fb03750d14f34a4c5674d293cc78d` — 4:3 + 수치 블록 없음 → 건물 전체 축소, 자기 기단·마루를
  새로 그림. 골조 디자인 자체는 좋았으나 정렬 시 a/c=2.39 비등방 → 폐기
  (`raw/07_frame_bbanana_260fb037.jpg`).

## 4. 정렬·합성 실행 커맨드 (검증된 파라미터)

```bash
cd C:/Users/vjinn/.codex/worktrees/ko_lernen_app-hanok-a1-kit
R=assets_unused/pending_review/a1_kit/raw
G=assets_unused/pending_review/a1_kit/generated
Q=assets_unused/pending_review/a1_kit/qa

# (1) 골조 4장: 07 = 아래쪽(창방·보) / 08 = 전체(도리·종도리)
python tool/align_model_frame.py $R/07_frame_v2_p9hh9hpg.png $G/07_frame_beams.png \
  --ridge-row 45 --top-row 112
python tool/align_model_frame.py $R/07_frame_v2_p9hh9hpg.png $G/08_frame_purlins.png \
  --ridge-row 45
# 09·10 은 07 이미지에서 잰 변환을 재사용한다 (직접 재면 서까래를 기둥으로 오인)
python tool/align_model_frame.py $R/09_rafters_gvi46an1e.png $G/09_frame_rafters.png \
  --ridge-row 45 --fit-from $R/07_frame_v2_p9hh9hpg.png
python tool/align_model_frame.py $R/10_roofbase_35cc4126.png $G/10_frame_roofbase.png \
  --ridge-row 45 --fit-from $R/07_frame_v2_p9hh9hpg.png

# (2) 소품 시트 → 16개 스프라이트(최종 크기까지 여기서 리사이즈)
python tool/cut_prop_sheet.py $R/props_sheet_5baedfca.jpg $G/props \
  --report $Q/props_cut_report.json

# (3) 프로그램 조립 부품 7개 (01·02·05·12·13·14·16)
python tool/make_kit_parts.py all --texture $R/13_earthwall_texture_bce56a89.png

# (4) parts.json 에 sha256 등록(decision: pending_jin_review) 뒤 01→16 순서로 합성
python tool/compose_hanok_a1_state.py --kit-manifest docs/assets/hanok_a1_kit/stage_09.json \
  $Q/09.webp --normalized-layer $Q/09_layer.png \
  --previous-manifest docs/assets/hanok_a1_kit/stage_08.json \
  --previous-layer $Q/08_layer.png --allow-unapproved-parts
```

- `--ridge-row 45`: 프레임 밴드(기둥머리 157 ~ 모델 용마루)를 우리 지붕 볼륨 157→45에 맞춘다.
- `--top-row 112`: 한 골조 이미지를 07(112행 아래)과 08(전체)로 나눈다.
- **`--clip-dilate-px` 기본값 0**: 정렬 결과를 완성 실루엣 **안쪽으로만** 클립한다. 1px이라도
  넘치면 11(완성 기와)이 그 픽셀을 덮지 못해 연속성 게이트가 26px 손실로 떨어진다(실측).
- **골조 레이어는 누적**이다: 08 = beams+purlins, 09 = +rafters, 10 = +roofbase. 모델이 매장
  프레임을 조금씩 다시 그리므로, 앞 부품을 아래에 깔지 않으면 09에서 387px이 사라진다(실측).
- 소품(01·02·05·14·16)은 `propsZone`(소켓 여백 + 기단 양끝 쐐기 + 바닥 띠) 안 또는 완성
  실루엣 위에만 놓인다. `make_kit_parts.py`가 저장 직전에 그 마스크로 클립한다.
- 12·13은 추가로 **완성 벽 패널의 완전 불투명 픽셀**로 클립된다 → 15에서 패널이 완전히 덮어
  `sarangchae.png`와 픽셀 동일이 유지된다.
- `parts.json` 필드: `generated.<id> = {file, sha256, source, decision}`.
  `stage_NN.json` 필드: `{schemaVersion, stage, id, note, layers[{part, z, rear?, transient?, prop?, at?}]}`.
  `prop: true` = 영구 소품(굴뚝·아궁이·신발·등롱·발·화분) → `sarangchae_props` 대상이며
  `render_manifest(include_props=False)`로 빼면 15·16이 완성본과 픽셀 동일해야 한다(테스트).

## 5. 16단계 완성 상태 (2026-08-17)

16장 모두 합성되어 게이트를 통과했다: kit anchor OK · containment 위반 0 · 구조 recall 1.0 ·
edge drift 0 · 최대 285,696 B(상한 350,000). 대조 시트 `qa/contact_sheet_a1_16.png`.

| 단계 | 부품 | 출처 | 크레딧 |
|---|---|---|---|
| 01 site_setout | `props_01_setout` (transient) | 소품 #16 말뚝 1개 ×4 + 발자국 실선 | 0 |
| 02 plan_layout | `props_02_layout` (transient) | 먹줄 격자(프로그램) + 소품 #5 도행판 | 0 |
| 03 foundation_gidan | `platform` | crop + 결정론 보정 | 0 |
| 04 cornerstones_choseok | `choseok_1..8` 앞·뒤 | crop + 원근 벡터 | 0 |
| 05 timber_preparation | `props_05_timber` (transient) | 소품 #1·#2·#3 | 0 |
| 06 columns | `pillar_1..8` 앞·뒤 | crop + 원근 벡터 | 0 |
| 07 beams_changbang | `frame_beams` | 3.1 골조 (top-row 112) | 4 |
| 08 purlins_sangnyang | `+frame_purlins` | 3.1 골조 전체 | 4 |
| 09 rafters_roof_frame | `+frame_rafters` | 3.2 | 4 |
| 10 roof_base | `+frame_roofbase` | 3.3 | 4 |
| 11 giwa_roof | `band_changbang`·`band_rafter_ends`·`roof` | crop | 0 |
| 12 wall_frame_sujang | `parts_12_sujang` | 완성본 목재 스트립으로 프로그램 도색 | 0 |
| 13 earth_walls | `parts_13_earthwall` | 3.5 초벽 텍스처 타일링 | 4 |
| 14 ondol_maru | `props_14_ondol` (prop) | 소품 #10 굴뚝·#11 아궁이 | 0 |
| 15 changho_finish | `panel_1..7`·`band_habang`·`wall_shadow` | crop — props 제외 시 완성본과 픽셀 동일 | 0 |
| 16 landscape_move_in | `props_16_movein` (prop) | 소품 #6 섬돌+신발·#7 등롱·#8 발·#9 화분 | 0 |

총 생성 24 credit(골조 16 + 소품 시트 4 + 초벽 4), 잔액 876.7.

**남은 일:** Jin 장별 승인 → provenance `generationLedger`에 `kind=part`(부품 11개)·
`kind=state`(합성 16장) 기록 → `promote_hanok_a1_states.py --apply` → pubspec 등록.
D1 rename(`11_choga_roof` → `11_giwa_roof`)은 PR5a에서 카탈로그·테스트와 함께.
`props_14_ondol`·`props_16_movein`은 PR5b에서 `sarangchae_props`로도 분리 승격한다.
