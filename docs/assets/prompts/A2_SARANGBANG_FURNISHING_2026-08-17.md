# A2 사랑방 가구 12종 — 생성 원장 (2026-08-17~18)

이 문서가 A2 장식 생성의 **정본**이다. 프롬프트 원문·모델·크기·참조·taskId·크레딧·판정·정규화 커맨드·출력 SHA를 남긴다.
A1이 `docs/assets/prompts/a1_kit_prompts.json`으로 같은 일을 했고, 그것을 남기지 않았던 2026-08-04 사랑방 6종은
프롬프트를 잃어버려 2026-08-17 재시도가 28크레딧을 태우고 어긋났다. 그 실패를 반복하지 않기 위한 문서다.

---

## 0. 기준선 — 왜 "복구된 프롬프트"를 쓰지 않는가

인수인계 `docs/HANDOFF_LIVING_HANOK_V1_2026-08-17.md` §6.3은 기존 6종의 원본 프롬프트를 복구해 기준으로 삼으라고 했다.
`get_status`로 세 개를 실제로 복구했다:

| taskId | 품목 | 프롬프트 성격 |
|---|---|---|
| `gvi_1785839371699_kh2ia` | 문방사우 | *"soft watercolour-and-gouache … hand-painted museum catalogue plate … pure white background"* |
| `gvi_1785839433358_iy9mit` | 소반 | 동일 수채 규약 |
| `gvi_1785839407073_1b2ygb` | 갓·부채 | 동일 수채 규약 |

**그런데 번들에 있는 파일은 수채가 아니라 Faceted Minhwa 로우폴리 컷아웃이다.**
`f63b5174`(2026-08-04) `docs/superpowers/plans/2026-08-04-sarangbang-production-assets.md`가 그 수채 산출물을
*"watercolour outlines, white canvases … violate the visual contract"* 로 **명시 기각**하고,
`#00FF00` chroma-key + Faceted Minhwa + no-outline + subtle hanji grain + 팔레트 hex + 단일 오브젝트 3% 여백
규약으로 다시 만든 것이 `9b16bad8`로 출시된 지금 파일이다.

⇒ **기준은 번들 PNG 자체.** 복구된 수채 프롬프트는 "쓰면 안 되는 계보"로만 기록한다.

**실패한 A2 2건**(`663d7694…`, `4db5dd10…`, 합계 28cr)의 프롬프트는 **복구 불가**다 —
`list_my_generations`는 최근 50건까지인데 2026-08-17 저녁 듣기카드 배치가 그 창을 채웠고, 인수인계에 적힌 ID는 잘려 있다.

---

## 1. 고정 설정 (모든 품목 동일)

| 항목 | 값 | 근거 |
|---|---|---|
| 모델 | **GPT Image 2** | 아래 §2 대조군 시험에서 선정 |
| 해상도 | `2K` | `generate_image`의 `resolution` 기본값은 1K라 **반드시 명시** |
| 참조 | **정확히 1장** — 앵커 시트 URL(아래) | Nano Banana Pro는 참조 3장에서 24cr이 빠진 실측이 있다. 참조 수는 고정한다 |
| 비율 | 품목별 2:3 / 3:2 / 1:1 | 정사각 contain 박스에서 잘 읽히도록. 세로세로·가로가로 3:1 넘지 않게 |
| 단가 | 4cr (2K) | 호출 응답의 `remainingCredit`으로 매번 확인 |

**앵커 참조 시트** — `assets_unused/pending_review/a2_furnishing/model_inputs/a2_style_ref_sheet_v1.png`
(2048×1536 원본, 업로드는 400px WebP 축소본 9,638B)
`tool/build_a2_style_ref_sheet.py`가 만든다: 출시된 `seoan`·`soban`·`munbangsau`·`jagae_mungap` 4장을
**flat #00FF00** 위 2×2로 배치.

- 원본 sha256 `23443df0bdc7e949806fba380fa7ee4dd01741960a971032f03b78ab82f6b89b`
- 업로드본 sha256 `7443a7789357…`(400px webp), 업로드 URL
  `https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/upload-storage/mcp-49737df0a06df9ffa42f350d249db1b1.webp`
- 배경을 초록으로 둔 이유: ① 출력에 요구하는 형식과 같다(2026-08-04 기각 사유가 "white canvases") ②
  흰 배경 플러드필이 방석·병풍의 아이보리를 갉는 문제를 피한다 ③ **실측**: 출시 6종의 최대 greenness(G−max(R,B))는
  23이고 55 초과 픽셀은 0개 — 키잉이 이 팔레트를 갉지 않는다.

## 1.1 방 편집기 제약 (그림에 직접 영향)

사랑방은 자유 배치다(`lib/widgets/sori/free_room_layer.dart`). 아이템은 **정사각 박스 안에서 `BoxFit.contain`** 으로
그려지고 **그 박스 중심을 축으로 회전**하며, 폭은 캔버스의 .08~.72 사이에서 사용자가 정한다. 따라서:

1. **바닥 그림자 금지** — 그림자가 오브젝트와 함께 회전해 즉시 깨진다. (출시 6종도 전부 그림자가 없다.)
2. **프레임 중앙·사방 여백 균등** — 회전축이 bbox 중심이라 치우치면 흔들린다. 정규화의 3% 패딩이 이를 보장한다.
3. **가로세로비 3:1 이내** — 정사각 contain이라 길쭉하면 같은 폭에서 훨씬 작아 보인다. 거문고는 대각선으로 눕힌다.

---

## 2. 대조군 시험 — 모델 선정 (5cr)

정답이 이미 있는 **소반**을 같은 프롬프트·같은 참조로 두 모델에 돌려 번들 파일과 비교했다.

| 모델 | cr | 결과 |
|---|---:|---|
| Seedream V4.5 (2K, 3:2) `0bd5d0b776438b8a41646ecd4b2dd192` | 1 | **탈락** — 바닥에 캐스트 그림자 발생(회전 시 깨짐), 면분할 대신 매끈한 3D 렌더 질감, 청록이 밝음, 초록 배경에 그라데이션 |
| **GPT Image 2** (2K, 3:2) `task-unified-1787006341-wzpe397p` | 4 | **채택** — 면분할·매트·한지 결·윤곽선 없음·**그림자 없음**·짙은 청록. 출시 소반과 같은 세트로 읽힘 |

산출물 `assets_unused/pending_review/a2_furnishing/raw/control_soban_gpt2_1787006389177.png`
(sha256 `d1295a37f51ff7d530dd27b8cdd8a84e42a1df8bb4e0bcc78f4739732a32c16c`)
→ 컷 `cut/decoration_soban_v2.png` → 정규화 `normalized/decoration_soban_v2.png` (1330×985, RGBA, 게이트 PASS)

검수 시트: `qa/sheet_compare.png`(출시 6종과 나란히) · `qa/sheet_transform.png`(회전 0/−20/25/90/180° × 110/200/320px) ·
`qa/sheet_room.png`(실제 `defaultWidth`로 사랑방 배경 위 합성)

---

## 3. 프롬프트 템플릿 (원문 · `{SUBJECT}`만 교체)

```
Create a NEW illustration in exactly the same illustrated-set style as the reference image (a Korean scholar's-room furniture set: LOW-POLY FACETED planes — every surface is broken into flat angular colour facets like folded paper, NO drawn outlines, matte finish, subtle hanji paper grain visible inside the facets, warm walnut wood with dark lacquer and small muted dancheong accents), but with this subject instead:

{SUBJECT}

Do not redraw any object that appears in the reference image; the reference is for style, palette, camera and lighting only.

CAMERA AND LIGHT: exactly one object, seen from the front and a little from the left, from slightly above eye level (three-quarter view), so the top surface and the front face are both visible; soft light from the upper left; gentle self-shading on the facets only; NO cast shadow, NO shadow on the ground, NO floor, NO wall, NO room, NO horizon line.

COMPOSITION RULES: the object is centred in the frame with an even margin of clear green on every side; it is a complete, self-contained cutout with crisp edges; nothing is cropped by the frame; one object only, no variants, no extra props.

BACKGROUND: flat pure #00FF00 chroma-key green everywhere outside the object, no gradient, no vignette, no shadow on the green.

IMPORTANT COLOR: keep exactly the reference palette — wood #A2663A #8F5130 #844A2D with facet shadows #633720 #5A3623 #3B271B, dark lacquer #2C221D #211914, aged hanji ivory #DBBC8D #C6AE8B, dancheong gold #BD924C, deep muted teal #274A3F, dark brick red #6A2316, stone grey #8B8478. Do NOT brighten, do NOT desaturate, do NOT use bright teal or bright red; matte only, no gloss.

ABSOLUTELY AVOID: black or dark outlines, line art, watercolour wash, soft painterly blending, gradients inside a facet, cast shadow, drop shadow, ground plane, room interior, white canvas, cute style, glossy 3D render, photorealism, sepia, people, hands, animals, readable text, letters, digits, hangul or hanja on any surface, extra objects, multiple variants of the object.

IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference image exactly. This must look like part of the same illustrated set.
```

팔레트 hex는 BIBLE §1.3의 명목값이 아니라 **출시 6종 실측값**이다(명목 청 `#3D9A7F`·적 `#C24A45`는 이 세트보다 훨씬 밝다).

---

## 4. 품목별 기록

전부 GPT Image 2 · 2K · 참조 1장(앵커 시트) · 4cr.

| # | slug | 비율 | taskId | 판정 |
|---|---|---|---|---|
| — | `decoration_soban_v2` (대조군) | 3:2 | `task-unified-1787006341-wzpe397p` | 모델 선정용, 런타임 미배치 |
| 1 | `decoration_sabangtakja` | 2:3 | `task-unified-1787006765-9a80w4eo` | 채택 |
| 2 | `decoration_boryo_set` | 3:2 | `f9ae98a7-7f18-4069-8cf8-4729c2d59527` | 채택 |
| 3 | `decoration_bangseok_pair` | 3:2 | `task-unified-1787007169-o962lq7f` | 채택 |
| 4 | `decoration_bandaji` | 3:2 | `task-unified-1787006798-b6w7gprr` | 채택 |
| 5 | `decoration_hwaro` | 1:1 | `4f365097-352a-4a76-a1d6-69a7d8a1bd66` | 채택 |
| 6 | `decoration_deungjan` | 2:3 | `task-unified-1787007201-fbn7juqh` | 채택 |
| 7 | `decoration_geomungo` | 3:2 | `9d45017f-…` → **재생성 `cb88feb1-fece-413e-a63f-517e1690e9b1`** | v1은 **가야금**(가동 안족·12현)이 나와 폐기. v2에 "SIX strings, SIXTEEN fixed frets, NOT a gayageum, no movable bridges"를 넣어 해결 |
| 8 | `decoration_baduk` | 1:1 | `task-unified-1787007232-au4flm9a` → **재생성 `task-unified-1787008065-ilbrzfzv`** | v1은 네온 5.1%로 게이트 실패(나무가 밝음). v2에 "DARK aged wood / no bright orange" 추가 |
| 9 | `decoration_mokchim` | 3:2 | `task-unified-1787007378-zti8m76j` → **재생성 `task-unified-1787008032-hdiyzyqz`** | v1 네온 4.3% 실패 → 같은 방식으로 해결 |
| 10 | `decoration_byeongpung_small` | 1:1 | `task-unified-1787007410-nr771xkq` | 채택 |
| 11 | `decoration_gobi` | 2:3 | `ffc5a832-e09b-48e9-9eca-dfa2065929e4` | 채택 |
| 12 | `decoration_hyangno` | 3:2 | `task-unified-1787007483-j5ebx7rx` | 채택 |

**게이트가 실제로 잡아낸 것.** `check_decoration_cutouts.py`의 네온 비율(채도>0.65 **그리고** 밝기>0.75, 상한 4%)이
바둑판 5.1%·목침 4.3%를 잡았다 — 둘 다 나무가 세트보다 밝고 주황빛이었다. 프롬프트에 어두운 목재를 못 박아
재생성하니 통과했다. 거문고는 게이트가 아니라 육안 검수에서 악기 자체가 틀린 것이 드러났다(가야금).

**용량.** 12장 정규화 직후 합계 11.7MB → `pngquant --quality=80-98` 로 **4.5MB**(−62%).
색차는 평균 ΔRGB 1.0~2.5, Δalpha 0.03~0.25로 육안 무차이이며, 저장소의 마당 장식 10장이 이미 같은 팔레트 방식이다.
그래서 게이트의 mode 규칙을 "RGBA만"에서 **"진짜 알파(RGBA 또는 P+tRNS)"**로 고쳤다 — 알파 없는 RGB는 그대로 실패다.

### SUBJECT 원문

1. **사방탁자** — a Korean sabangtakja (사방탁자): a tall slender four-tier open display stand built from four thin square-section walnut posts and four thin square shelf boards stacked at even intervals, completely open on all four sides with no back panel and no side panels; only the lowest tier is enclosed as a small cabinet with two little doors and one tiny brass pull; one small pale celadon jar stands on the third shelf and nothing else; every member is thin and airy.
4. **반닫이** — a Korean bandaji chest (반닫이): a low wide heavy rectangular chest of dark walnut boards standing on four short square feet; the front face is split horizontally in half and the upper half is a drop-front door hinged at the middle; on the front there are wide dark iron strap hinges, a large round central lock plate with a small hanging padlock, and small stud nails arranged in a symmetric geometric pattern; the top is a plain flat board; proportions roughly three wide to two high to one and a half deep.
5. **화로** — a Korean charcoal brazier (화로): a wide low round bowl of dark cast iron standing on three short bowed legs, with a wide flat rim; inside the bowl are flat dull orange-red charcoal facets under a thin layer of pale ash, with no flame and no glow; one pair of long thin brass fire tongs rests across the rim.
7. **거문고** — a Korean geomungo zither (거문고) lying flat: a long narrow slightly convex paulownia soundboard with dark walnut end pieces, sixteen thin fixed wooden frets set across the middle section, and six strings running the whole length; one short thin bamboo plectrum stick rests on the strings. Lay the instrument diagonally across the frame from the lower left to the upper right so it fills the square area well.

(나머지 8종은 생성 시 여기에 추가한다.)

---

## 5. 후처리 (0크레딧, 결정론)

```bash
PY=/usr/local/bin/python3.12
S=assets_unused/pending_review/a2_furnishing

curl -fsSL -o $S/raw/<slug>_<taskid>.png "<resultUrl>"
$PY tool/cut_single_object.py $S/raw/<slug>_<taskid>.png $S/cut/<slug>.png \
    --expect-parts 1 --report $S/qa/<slug>_cut.json
cp $S/cut/<slug>.png assets/illustrations/decorations/_raw/<slug>.png
$PY tool/decoration_normalize.py                      # 트림 → 긴 변 1254 + 3% 여백(=1330)
$PY tool/check_decoration_cutouts.py <slug>
$PY tool/render_a2_contact_sheet.py --new … --out $S/qa
```

- `tool/cut_single_object.py` — `cut_prop_sheet.chroma_to_alpha`(greenness 15→55 램프, despill 12) 재사용.
  네 모서리의 greenness가 55 미만이면(= 키어가 완전 투명으로 못 만들면) 기각, 부품 수가 `--expect-parts`와 다르면 기각.
- `tool/check_decoration_cutouts.py` — RGBA8 · 긴 변 ≤1330 · alpha 커버리지 3~90% · 가시 ≥512 ·
  `#00FF00` 잔여 0 · green rim ≤0.5% · 외곽 행/열·모서리 투명 · 네온(채도>0.65 **그리고** 밝기>0.75) ≤4%.
  **모든 임계값은 출시 6종이 통과하도록 보정했다** — 승인된 그림을 떨어뜨리는 게이트는 잘못 재고 있는 것이다.

⚠️ **정규화 산출물은 화이트리스트 등록과 같은 커밋에서만 `assets/illustrations/decorations/` 에 넣는다.**
등록 없이 그 폴더에 두면 `test/decoration_slot_test.dart`가 즉시 실패한다(디스크↔화이트리스트 양방향 검사).

---

## 6. 크레딧

| 항목 | cr |
|---|---:|
| 대조군 Seedream V4.5 1장 (탈락) | 1 |
| 대조군 GPT Image 2 1장 (모델 선정) | 4 |
| 본편 12장 | 48 |
| 재생성 3장 (거문고·바둑판·목침) | 12 |
| **이 작업 합계** | **65** |

업로드(앵커 시트)는 무료. 잔액은 착수 시 788.7 → 작업 뒤 645.5로 보이지만, **동시에 다른 세션이 듣기 카드를
생성 중**이라 그 차이(≈78cr)는 이 작업 몫이 아니다. 이 표의 65cr만 A2 몫이다.

⚠️ 이 세션과 **동시에 다른 세션이 듣기 카드를 생성 중**이라 잔액은 두 작업이 함께 깎는다.
(788.7 → 688.7 구간의 감소분 대부분은 이 작업이 아니다.) 원장에는 이 작업의 호출만 적는다.
