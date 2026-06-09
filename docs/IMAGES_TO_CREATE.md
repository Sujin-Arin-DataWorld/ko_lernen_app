# 제작해야 할 이미지 리스트 (light 전용)

> 작성: 2026-06-02 · 기준: `종가이미지 압축` 48장 반영 후 실측 + **다크모드 폐지** 반영
> 스타일/프롬프트: `docs/ASSET_GENERATION_BIBLE.md` (최종 단일 소스). 낱장 상세 프롬프트 부록: `docs/plans/stately-rising-jongga-assets.md`
> ⚠️ **다크모드 폐지로 모든 `_dark` 변형은 제작 불필요** (한옥 24장 → light 12장으로 축소 등).
> "드롭인" = 파일만 넣으면 코드가 자동 인식 / "와이어링" = 코드 연결 추가 필요.

---

## ✅ 지금 들어와 있는 것 (참고, 2026-06-04 갱신)
- 한옥 단계(light): **12/12 완료** — empty·foundation·pillars·beams·thatch·tile_partial·tile_complete·dancheong·gate·windows·**side_building·jongga**(2026-06-04 추가)
- 장식: 10 · 도장: 8 · 스티커: 30 · 마스코트: 호랑이·까치 전부 · 솟을대문 gate 세트
- 남은 장식 7 = decorations 17 중 10 있음 → 누락 7(아래 P3·P4). **프롬프트는 전부 `plans/stately-rising-jongga-assets.md` §3.5~3.17에 완비**(BIBLE 스타일·팔레트 hex·layout 포함). 신규 작성 불필요 — 해당 § 열어 그대로 생성.

---

## 🔴 P1 — 출시 차단/플래그십 (먼저)

| 파일 | 용도 | 규격 | 저장 경로 | 연결 |
|---|---|---|---|---|
| feature graphic | **Play Store 필수** 등록 이미지 | 1024×500 | `docs/store/` | 콘솔 업로드 |
| 스크린샷 8장 | 스토어 미디어 | 1080×1920(폰) | — | 실기기 캡처 |
| `book_empty_shelf.png` | 책 한 컷 — 빈 책장 | 사각, 투명/cream | `assets/illustrations/book/` | **와이어링 필요** |
| `book_camera_guide.png` | 책 한 컷 — 촬영 가이드 | 〃 | 〃 | 와이어링 필요 |
| `book_analyzing.png` | 책 한 컷 — 분석 중 | 〃 | 〃 | 와이어링 필요 |
| `book_success.png` | 책 한 컷 — 성공 축하 | 〃 | 〃 | 와이어링 필요 |
| `book_error.png` | 책 한 컷 — 오류 | 〃 | 〃 | 와이어링 필요 |

> 책 한 컷 일러스트 5장은 현재 화면이 **마스코트로 대체** 중. 만들면 플래그십 인상이 크게 좋아짐. 단, 코드에 경로 연결이 필요(현재 미참조) — 만들면 알려주시면 연결해 드림. 폴더 `assets/illustrations/book/` 신설 + pubspec 등록도 함께 필요.

---

## ✅ P2 — 한옥 성장 완성 (2026-06-04 완료)

`stage_side_building_light.png` + `stage_jongga_light.png` 둘 다 추가됨 → **hanok_stages 12/12**. B2 끝까지 간 유저에게 "종갓집 완성" 연출 정상 노출. (드롭인 완료)

---

## 🟡 P3 — 퀘스트 장식·도장 (출시 후 폴리시, 대부분 드롭인)

| 파일 | 용도 | 연결 | 비고 |
|---|---|---|---|
| `decoration_seokdeung.png` | 장명등 (발음평가 퀘스트 보상) | **드롭인** | 프롬프트 **assets-md §3.5** · layout L.08 B.08 W.10 · 출시 후 퀘스트 |
| `decoration_sagunja_guk.png` | 사군자 국화 (4폭 완성용) | **드롭인** | 프롬프트 **assets-md §3.11** · layout L.28 B.52 W.10 · 매·난·죽 있음 국화만 |
| `stamp_mountain.png` | 단청 도장 (산) | 와이어링 가능성 | 도장 위젯 8모티프 중 7번째 |
| `stamp_plum.png` | 단청 도장 (매화) | 와이어링 가능성 | 8번째 |
| `dokkaebi_fire.png` | 온보딩 프리뷰 page3 — 축하 호랑이 우상단 도깨비불 뱃지 | **와이어링** (현 경로 pubspec 미등록) | 폴백=주황 원 글로우(비차단) · 프롬프트 → **부록 A** |

저장 경로: 장식 `assets/illustrations/decorations/`, 도장 `assets/illustrations/stamps/`

---

## 🟢 P4 — v3.0(커뮤니티) 전까지 불필요 (지금 만들지 말 것)

- **계절 장식 4종** (프롬프트 **assets-md §3.14~3.17**): `decoration_seollal_flag`(L.42 B.30 W.20) · `decoration_chuseok_moon`(L.70 B.86 W.15) · `decoration_hangeulday_plaque`(L.42 B.78 W.16) · `decoration_kite`(L.30 B.88 W.18) — 시즌 이벤트 시
- **돌담** `decoration_doldam.png` (프롬프트 **assets-md §3.8** · layout L0 B.04 W1.0 full) — 친구/계원 5명 = v3.0
- **스티커 19장** (현재 11/30, 스티커 채팅은 v3.0 커뮤니티)
- **계 공동 한옥 추가 요소 8장** (v3.0)

---

## 부록 A — 도깨비불 뱃지 프롬프트 (`dokkaebi_fire.png`)

> 온보딩 프리뷰 **page3**("매일 호랑이와 / Täglich mit dem Tiger") — 축하 호랑이 우상단 72px 장식 뱃지.
> 한국 전통 **도깨비불**(푸른빛 영묘한 불 = 호랑이 주황의 보색). BIBLE §1 Faceted Minhwa + §1.3 팔레트 기반.
> 생성 시 레퍼런스로 `assets/illustrations/mascot/tiger_idle.png` + 단청 자산 1장을 **반드시 첨부**.

```text
A square editorial illustration of a single Korean dokkaebi-bul (도깨비불) — an
ethereal floating goblin-fire / will-o'-the-wisp from Korean folklore, glowing
COOL blue-green, never warm orange.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era) crossed
with Korean minhwa folk-painting iconography. NOT cute, NOT cartoonish, NO face on
the flame — confident, contemporary, premium editorial quality. Mood: calm,
mystical, auspicious.

Single centered focal object on empty space:
- An upward teardrop / wisp flame built from clean ANGULAR color facets
  (cut-paper / stained-glass planes).
- Luminous core: Dancheong Gold #DFA951.
- Mid-body: Dancheong Teal #3D9A7F and deeper #2A6B5C.
- Cool outer facets and base: Muted Indigo #1F2E5C, Cobalt Indigo #2C3E94,
  deepest #0A2E3A.
- A few small rising embers as faceted gold #DFA951 dots in ONE loose cluster
  drifting upward (not scattered randomly).

Style discipline (CRITICAL):
- NO outlines — pure flat color planes meeting at hard angular edges; volume from
  hard-edge value steps only.
- NO gradients within shapes EXCEPT ONE soft halo glow around the core
  (gold -> teal) — the single allowed gradient.
- Subtle hanji paper-grain texture on the flame's color planes only.
- Restricted palette (hex): #DFA951, #3D9A7F, #2A6B5C, #1F2E5C, #2C3E94, #0A2E3A.
- Clear silhouette readability — must read as a flame/wisp at 48-72px thumbnail.
- Deliberately the COOL complement to the warm-orange tiger it sits beside.

Background: FULLY TRANSPARENT (RGBA) — no paper, no card, no box, no drop-shadow
rectangle. Subject centered with ~10% transparent padding.

Aspect ratio: 1:1 (1024x1024 px; master 1254x1254 ok).

ABSOLUTELY AVOID: outlines; red/orange/yellow campfire or candle colors; realistic
fire, smoke or embers; candy/neon; a cute chibi face on the flame; jack-o'-lantern
look; any text or letters; opaque/white/beige background; drop-shadow box.

This is editorial illustration for a premium Korean learning app — a serene,
auspicious goblin-fire badge floating beside the celebrating tiger,
magazine-cover quality.

IMPORTANT: match the geometric faceted style, color palette, paper-grain texture,
and overall mood of the attached reference images (mascot/tiger_idle.png and a
단청 asset) exactly. This must look like part of the same illustrated set.
```

**후처리 (BIBLE §2.2/§6)**: RGBA 투명 PNG · 정사각 1024²(마스터 1254²) · 중앙 ~10% 패딩 · 흰/베이지 사각·드롭섀도 사각 금지.
**연결 주의 (§0)**: 코드는 현재 `assets/illustrations/dokkaebi_fire.png`(루트)를 참조하나 이 루트 경로는 **pubspec 미등록**(하위폴더만 등록) → PNG를 넣어도 안 뜸. 제작 후 둘 중 하나 — **① `decorations/`에 저장하고 코드 경로를 `decorations/dokkaebi_fire.png`로 변경**, 또는 **② pubspec `assets:`에 파일 직접 등록**. (Claude가 1줄로 처리 가능.)

---

## 요약
- **출시 전 꼭**: feature graphic(1) + 스크린샷(8) + (권장) 책 한 컷 5장
- **곧**: 한옥 마지막 2단계(드롭인) + 장명등·국화(드롭인)
- **나중(v3.0)**: 계절/돌담/스티커/공동한옥 = 약 31장
- 다크 변형: **전부 폐지** (제작 안 함)
