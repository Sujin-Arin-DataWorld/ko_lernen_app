# 인수인계 — Hören "살아있는 책가도" 재설계 + 공유 이미지 패밀리

**작성** 2026-08-19 (Claude Fable 5, Windows) · **기준** `origin/main` = `6fad2bab`
**브랜치** `claude/hoeren-redesign-mockups-20260819` (워크트리 `.claude/worktrees/hoeren-redesign-20260819`)
**이 세션이 만든 것** 비평 · 설계 · 목업 · 이 문서. **앱 코드 변경 0.** 구현은 다음 세션.

**같이 읽을 것(순서대로)**
1. 목업(브라우저로 열기): `docs/mockups/hoeren_redesign_2026-08-19.html` — 저장소 상대경로로 실제 에셋을 그린다. 클라우드 사본(이미지 인라인): https://claude.ai/code/artifact/d93d8951-30c0-4271-b92a-025c16fb8a03
2. 8/17 데이터·UI 접합 인수인계: `docs/HANDOFF_HOEREN_GRID_2026-08-17.md` (데이터 계약·게이트·함정 — 전부 유효)
3. 8/19 콘텐츠 UI/UX 마감 계획: `docs/CONTENT_UIUX_FINISH_PLAN_2026-08-19.md` (Phase 2 두루마리 공유 회수 · Phase 3 타이포/제스처 — 이 문서는 그 위에 얹힌다)
4. 아트 레시피: `docs/LISTENING_CARD_ART_SPEC.md` §공통 프롬프트 골격 + 2026-08-18 반전 절
5. 스타일 정본: `docs/assets/STYLE_LOCK.json` > `docs/HANOK_ASSET_INVENTORY_2026-08-17.md` > `docs/ASSET_GENERATION_BIBLE.md` §1

---

## 0. 한 줄 요약

Hören은 **책가도(冊架圖) 은유를 장난감 해상도로 그린 상태**다. 은유·데이터 계약·에셋은 전부 살리고
**칸을 민화 정물로, 나무를 면 3톤+어긋남으로, 레벨을 층/서랍으로, 두루마리를 진짜 두루마리로**
바꾼다. 새 색 0개, 새 아트는 C1/C2 23장뿐. 공유 이미지는 두루마리(안 A, 잠금) 위에
**같은 DNA로 5종을 더 얹는 한 렌더러**로 간다.

---

## 1. 지금 상태 (실측, 추정 아님)

| 무엇 | 어디 | 상태 |
|---|---|---|
| 서재 화면 | `lib/screens/listening_screen.dart` (316줄) | 10:3 `HanokHeader(listening_hero.png)` → 부제 → 메타 → h3 → 레벨 `SoriChip` 6개 → 9px 단청 띠 → `ChaekgadoShelfCase` |
| 칸 렌더 | `lib/widgets/sori/chaekgado/shelf_case.dart` (451줄) | 2열 고정 `_ShelfRow`, 칸=아이보리 면 + 상단 알약 라벨 + **책등 N개(= 시나리오 수, 6색 순환)** + 소품 1(108칸 공용 4종 순환) + 라벨 밑 진행선 |
| 두루마리 | `lib/widgets/sori/chaekgado/scroll_sheet.dart` (416줄) | `showGeneralDialog` **중앙 다이얼로그**(배리어 `0x941E160E`), 위아래 `_Rod/_RodCap`은 작은 못처럼만 보임, 본문은 16:10 일러스트 + 번호 리스트 + `n/15` 풋노트 |
| 칸 정의 | `lib/data/chaekgado_shelf.dart` | 6레벨 × 15칸(기능 12 + Social 3 공용) · `imageKey` → `assets/illustrations/listening/{Key}.webp` |
| 카드 아트 | `assets/illustrations/listening/` | **50장** (A1 12 · A2 12 · B1 12 · B2 12 · C1 1 · Social 3). 4:3 · 아이보리 `#F4E8D0` · 적 `#B94B32`/청 `#5F9A93` 모서리 삼각 · 점군 |
| 목재·소품 | `assets/illustrations/chaekgado/` | 8장(기둥·널판·단청띠·축 + 청자·붓통·사발·두루마리) |
| 도장 | `assets/illustrations/stamps/` | 12장 |
| 공유 렌더러 | `lib/widgets/sori/share_slip.dart` (main 168줄) / `5229be29`·워크트리 `p7-scroll-share-slip` 340줄 | main 것은 크림 바닥+나무 띠 2+글+`한` 네모 도장. p7 것은 축·마개·널판·말림까지 그린 두루마리(안 A 잠금본). 회수 절차는 FINISH_PLAN Phase 2 |
| 공유 호출 | `custom_pack_play · hangul · legacy_vocab · listening_play · review_session · vocab_pack` | 6곳, 전부 `ContentShareService.shareStory(korean, gloss)` |
| 테스트 | `test/chaekgado_shelf_test.dart` · `listening_shelf_route_test.dart` · `scenario_shelf_contract_test.dart` · `content_share_slip_test.dart`(p7) | 계약 테스트 — UI 교체 시 갱신 대상 |

---

## 2. 비평 (수석 디자이너 관점 — 목업 §1과 동일)

1. **은유의 해상도.** 책가도는 역원근·쌓인 기하·굵은 색면의 정물화 = 우리 스타일 그 자체. 구현은 같은 책등 5개+빨간 점+소품을 15칸에 복붙. 100px에서 모든 칸이 똑같이 읽힌다.
2. **정보/장식 전도.** 책등 개수=재고는 누구도 세지 않고, 진행(라벨 밑 1px)은 안 보인다. 재고 0칸은 고장처럼 보인다.
3. **위계 역전.** 수채풍 히어로(스타일 이질) + 텍스트 3줄이 유일한 과제(주제 고르기)를 폴드 아래로 민다.
4. **레벨 필터가 "내 것"을 말하지 않는다.** 칩 6개가 동급 탭. 요구는 "내 층 먼저, 나머지는 손 닿는 곳".
5. **두루마리가 두루마리가 아니다.** 흰 Material 다이얼로그 + 못 2개. 나무 책장 위에 흰 앱 시트 = 세계가 깨진다.
6. **라벨 잘림.** `Erster Besuch bei der Partnerfa…`. 짧은 이름 ARB 키 필요(8/17 §7-4 미결 그대로).

**살릴 것:** 2단 구조(칸→두루마리), 레벨×15칸 데이터, `loadLevel` LRU, 카드 아트 50장, 목재·소품 8장, 도장 12장, `errorBuilder` 계약, `hanji_texture.dart`.

---

## 3. 설계 — 다섯 규칙 (목업 §2·§4가 사양)

| # | 규칙 | 구현 핵심 |
|---|---|---|
| ① | **칸 = 정물 한 점** | 칸 내부 = 카드 아트 `BoxFit.cover` 세로 중앙(아트 세이프 12~88%). 아트의 적·청 모서리 삼각이 칸 안에서 보석 컷처럼 읽힌다. 재고 0 = `#EADDC2` + 소품 1 + "bald" 꼬리표. 아트 없음 → `#F4E8D0` + 소품(폴백). |
| ② | **나무 = 면 3톤 + 어긋남** | 널판 9dp `#A87F55 30% / #8E6646 44% / #5C4028 26%` 하드엣지, 행마다 `skewY ±0.5°`, 윗변 1px 적 `#B94B32` α.28(리소 2판 어긋남). 기둥 11dp 3면. 장 안쪽 `#3E2B1B`. **CustomPainter**로 그리고 PNG 타일은 폴백. 그레인 1겹 multiply(전체). |
| ③ | **진행 = 붓선 + 도장** | 칸 바닥 3~4dp 녹청 `#1F7A6B` 붓선(길이=진행률, 끝 삐침 −0.4°), 0%면 없음. 완료 = `stamps/stamp_*.png` 36~40dp −9° 좌하단(motif = slug 해시 고정) + 카운트 칩이 적 배경으로. 숫자 `n/재고`(8/17 §7-2 기본값). |
| ④ | **레벨 = 층/서랍** | 크라운에 한지 꼬리표: 내 레벨만 아이보리+도장(열린 층), 나머지 나무색 작은 꼬리표(카운트 포함). 열린 층 아래 "Weitere Regale" = 닫힌 서랍 행(한지 라벨 + 놋쇠 손잡이 = 유일한 황). 서랍 탭 → 그 층이 열리고 크라운 꼬리표가 바뀜(`setState(_shelfLevel)` 그대로). C1/C2는 `dim`. |
| ⑤ | **두루마리 = 널판 밑에서 풀린다** | `showGeneralDialog` 중앙 → **바텀시트**(`showModalBottomSheet` 또는 기존 `showGeneralDialog`에 `Align(bottom)`+slide). 위 축+놋쇠 마개 → 한지 → 카드 아트(찢은 가장자리 clip) → 제목/메타 → 항목(번호 도장: 적=들음·녹청=다음·한지색=아직, 제목, `n Zeilen`, 길이) → 아래 축. 화면 폭 전체. |

**히어로:** 10:3 `listening_hero.png`는 이 화면에서 **제거**(스타일 이질·30% 점유). 까치는 크라운 위 `magpie_perched.png` 46dp 컷아웃으로만. 되돌릴 수 있게 **단독 커밋**.

**타이포·색(FINISH_PLAN Phase 3·4 준수):** 꼬리표 `meta 12.5 w700`, 두루마리 제목 `h3`, 항목 제목 `gloss 17→15`, 메타 `meta`. raw `TextStyle(` 0개, `Pretendard` 리터럴 0개(`tt.*` 토큰만). CTA 색은 `primary` 하나. 황은 놋쇠 손잡이에만.

**접근성:** 칸 = `Semantics(button, label: "$label, $n von $m gehört")`, 최소 48dp 탭. 꼬리표 대비 먹/크림 ≥ 7:1. 서랍 = 버튼. 두루마리 항목 = 리스트 시맨틱. `reduceMotion` 시 붓선·도장 팝·서랍 슬라이드 전부 정적.

**모션(≤220ms):** 서랍 열림 = 플랭크가 위로 밀려 올라오는 120ms slide + 칸 fade-in stagger 40ms. 도장 찍힘 180ms scale 1.15→1. 두루마리 = 위 축 고정, 한지가 아래로 펴지는 200ms(`SizeTransition`). 피드 제스처 규칙(Phase 3.5)과 충돌 없음 — 이 화면엔 피드가 없다.

---

## 4. 구현 계획 (PR 3개, 화면당 커밋 1개 원칙)

> 전제: FINISH_PLAN Phase 0(환경 정리)·Phase 2(두루마리 공유 회수)가 먼저여도 되고 병행해도 된다. 겹치는 파일은 `share_slip.dart`뿐.

### PR-H1 서재 렌더 교체 (`shelf_case.dart` 재작성 + `listening_screen.dart` 다이어트)
1. `ChaekgadoCompartment`에 `imageAsset`(카드 아트 경로) · `stampAsset` · `isStocked` 유지. `label`은 **짧은 이름**을 받는다.
2. `_ShelfRow` → 칸 내부를 `Image.asset(imageAsset, fit: cover, alignment: Alignment(0,-0.1), errorBuilder: 소품 폴백)`로. 첫 칸 wide 옵션(`spanAll`)은 레벨의 첫 slot에만.
3. 새 `_PlankPainter`(3톤+skew+적 어긋남) · `_PillarPainter`. PNG 타일 `chaekgado_plank.png` 등은 폴백으로 유지(자산 가드 근거 문자열 생존).
4. 진행 붓선 `_BrushStroke(progress)` CustomPainter(한 번에 한 스트로크, 끝점 삐침). 완료 시 `Image.asset(stamp)`.
5. `listening_screen.dart`: `HanokHeader`·부제·메타·h3 삭제. 크라운 위젯 `ChaekgadoCrown(levels:, selected:, onSelect:)` 신설(꼬리표 행 포함). `SoriChip` 행 삭제. 아래 `ChaekgadoDrawers(levels, counts, onOpen)`.
6. ARB: `listeningShelfShort{Key}` 78키 DE/EN 추가(긴 이름은 두루마리 제목에 계속 사용). **하드코딩 금지.**
7. 테스트: `chaekgado_shelf_test.dart` 갱신(칸 수·재고 0 폴백·errorBuilder) + 골든 1장(`listening_shelf_a1`) + `accessibility_guideline_test`에 `/listening` 추가.

### PR-H2 두루마리 바텀시트 (`scroll_sheet.dart`)
1. `showChaekgadoScroll` 시그니처 유지(호출부 무수정), 내부를 바텀시트로. `_Rod/_RodCap` 재사용(p7 `share_slip.dart`가 같은 팔레트를 복제하고 있음 — hex 바꾸면 세 파일 함께).
2. 헤더 이미지 찢은 가장자리: `ClipPath(_TornEdgeClipper(seed: slug.hashCode))`.
3. 항목 번호 도장 3상태. 완료 `Storage.completedScenarios` 파생(분할 키 도입 금지 — 8/17 §4.5).
4. `listening_shelf_route_test.dart` 갱신(다이얼로그 → 시트 finder).

### PR-H3 공유 패밀리 (§5) — Phase 2 회수 뒤
- `ShareSlip(variant: ShareSlipVariant.scroll|note|nunchi|riddle|stampbook|listeningLine, ratio: ShareRatio.story|feed|square, content: ShareContent)`. 렌더러 1개, `content_share_slip_test.dart`에 variant×ratio 매트릭스 골든.

**게이트(항상):** `flutter analyze` 클린 · `flutter test test/chaekgado_shelf_test.dart test/listening_shelf_route_test.dart test/scenario_shelf_contract_test.dart test/asset_orphan_guard_test.dart test/typography_guard_test.dart` · 골든 갱신은 실측 후 · `docs/SESSION_LOG.md` 항목.

---

## 5. 공유 이미지 패밀리 — 한 렌더러, 여섯 얼굴

**왜 여럿인가.** 인스타에서 퍼지는 동기는 다섯 가지다: ① 나를 말해 준다 ② 저장해 두고 싶다 ③ 웃기거나 찔린다 ④ 자랑 ⑤ 맞히고 싶다. 두루마리(안 A)는 ①②만 맡는다. 같은 DNA로 나머지를 채운다.

| 변형 | 비율 | 콘텐츠 모델 | 트리거(앱 내 순간) | 퍼지는 이유 | 상태 |
|---|---|---|---|---|---|
| **A 두루마리** | 9:16 (1:1 크롭 안전) | `korean, gloss` | 뒷면 연 직후 · 좋아요 직후 | 예쁘다·나를 말한다 | **잠금**, p7 `5229be29` 회수 |
| **B 눈치 카드** | 4:5 | `korean(≤3음절), romanization, gloss(한 문장 정의)` | 단어망/뉘앙스 화면 · 주 1회 편집 픽(눈치·정·한·멍·답정너·빨리빨리…) | "독일어에 없는 말" = 자기소개. 바이럴 1순위 | 신규 |
| **C 시조 쪽지** | 1:1 | `korean, pos, gloss, example(ko/de)` | 책갈피 보관 직후 | 저장해 두는 카드, DM/왓츠앱에서 읽힘 | 바이블 안 C |
| **D Rätsel** | 9:16 × 2장 | 문제장 `korean` / 정답장 = A 재사용 | 듣기 한 줄 완료 후 "Freunde testen" | 스토리 답장을 부른다 | 신규 |
| **E 도장첩** | 1:1 | `streakDays, level, stats, stamps[]` | 스트릭 7·30·100 · 레벨 승급 · Gye 주간목표 | 자랑. 황 없이 도장이 보상 | 신규 |
| **F 듣기 한 줄** | 9:16 | `korean, gloss, shelfLabel, shelfArtAsset` | 플레이어 한 줄 길게 누름 → Teilen | 책가도 세계가 공유까지 이어진다 | 신규 |

**공통 계약 (전 변형):** 한지 `#F4E8D0`/`#FAF6EC` + 그레인 · 외곽선 0 · 앱 크롬 0 · 한국어 Pretendard w700 92–120px@1080 · 뜻 36–40 · 푸터 `hangul-sori.com` 32px 먹-muted · 도장 석간주 `#B94B32` · 적·청 삼각 ≤2 · 점군 ≤2군집 · **텍스트는 9:16의 세로 22–78% 안**(1:1 크롭 보존) · 캡션 `text:` 페이로드 없음(Phase 2 결정) · 다크 변형 없음.
**렌더러:** p7의 오프스크린 `renderShareSlipToPng`(RenderView/PipelineOwner 직접 구동) 위에 `variant` 스위치. 색은 상수, Theme/Localizations 무의존 유지. 변형별 `CustomPainter`는 `_ChaekgadoFramePainter`처럼 파일 내 private.
**검증:** variant×ratio 골든 + "1:1 크롭 후 한국어 전부 보임" 픽셀 테스트(세로 22–78% 밖에 글리프 픽셀 0).

---

## 6. 에셋 — 필요한 것은 23장뿐

| 자산 | 추가 제작 | 레시피 |
|---|---|---|
| C1 11장 · C2 12장 카드 아트 | 23장 × 4크레딧 | `LISTENING_CARD_ART_SPEC.md` §공통 프롬프트 골격 그대로(아이보리 `#F4E8D0` 꽉, 적 `#B94B32`, 청 `#5F9A93`, 세이프 12~88%, 가는 선 금지). 소재만 §C1/§C2 표. **거칠기 문장 추가:** *"hand-pulled risograph, ink pooling at plane edges, slight plate misregistration, hanji fibres visible inside planes, matte — NOT clean vector"*. 후처리(`apply_riso_v2.py`) 금지(8/18 결정: 70KB 초과·효과 미미). |
| 까치(선택) | 1장 | 갓 쓴 까치 앉은 자세, 그린스크린 → `tool/cut_single_object.py`. 없어도 `magpie_perched.png`로 출시. |
| 목재·소품·도장 | 0 | — |
| `listening_hero.png` | 제거 (pubspec·가드 갱신) | — |

**거칠기의 실체(코드 쪽):** skew ±0.5° · 1px 적 어긋남 선 · 찢은 가장자리 clip · −1.2° 꼬리표 · 우하단 3px 깎은 모서리 · 그레인 multiply. "완벽한 평행선·완벽한 직각 금지"가 전부다.

---

## 7. Jin 결정 필요 (무응답 시 기본값으로 진행)

| # | 질문 | 기본값 |
|---|---|---|
| 1 | 히어로(수채 까치 배너) 제거 동의? | 제거, 단독 커밋 |
| 2 | 다른 레벨 접근 = 크라운 꼬리표 + 아래 서랍 **둘 다**? 아니면 꼬리표만? | 둘 다(서랍이 "내 층" 아래 자연스런 발견 경로) |
| 3 | 첫 칸(레벨의 slot 0)을 wide로? | A1만 wide(인사), 나머지 레벨은 2열 균일 |
| 4 | 공유 변형 우선순위 | B 눈치 → F 듣기 한 줄 → C 쪽지 → D → E |
| 5 | C1/C2 23장 생성 시점 | PR-H1 머지 후, 폴백(소품)으로 먼저 출시 |
| 6 | 짧은 칸 이름 — 세션이 78키 초안을 쓸지, Jin이 검수할지 | 세션이 초안, Jin 검수 |

---

## 8. 다음 세션 시작 절차

```powershell
git fetch origin
git worktree add .claude/worktrees/hoeren-impl-$(Get-Date -Format yyyyMMdd) -b claude/hoeren-living-chaekgado origin/main
# 1) 이 문서 + 목업 HTML을 브라우저로 연다 (docs/mockups/…html — 상대경로 이미지)
# 2) PR-H1부터. 화면당 커밋 1개. SESSION_LOG 최상단 항목.
```

**하지 말 것:** `scenarios.json` 부활 · `lib/data/chaekgado_shelf.dart`에 id→칸 하드코딩 복귀 · 진행도 키 분할 · 황(gold)을 칸/카드에 · 검정 외곽선 · 회색 원 아이콘 · `FittedBox(scaleDown)` · raw `TextStyle(` · `showDialog` 중앙 두루마리 · 카드 아트를 `backdrop`에서 파생(shelf≠backdrop) · 공유 이미지에 앱 스크린샷.
