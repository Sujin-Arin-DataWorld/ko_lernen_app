> **Superseded.** 다음 세션 정본은
> `.claude/handoffs/2026-08-18-235200-hanok-asset-skill-audit.md` 이다.
> 이 파일은 git 위상·참고 3장 숫자는 맞지만, 릴리스 원장 파일 존재,
> 책가도 3 props F-A 통과, A1 unused=런타임 해시 동일, main tip `a00fc1d1`,
> 파이프라인 게이트 미병합을 빠뜨렸다.

# Handoff: 살아 있는 한옥 — 실측으로 다시 고정한 인수인계 (2026-08-18 밤)

## Session Metadata
- Created: 2026-08-18 23:48:00
- Project: `/workspace` (Cursor Cloud VM). 원본 Mac 경로는 `/Users/sujinpark/Developer/ko_lernen_app`.
- Branch to continue from: **`origin/main` @ `6b600eea`**. 이 문서는 `cursor/living-hanok-verified-handoff-fb5a`에 올라간다.
- Session duration: 선행 Mac 세션(한옥 PR-B~D + Phase 2 + 소품 감사 + 1차 핸드오프) + 이 Cloud 세션(전항 재검증).

### Recent Commits (for context, independently verified 2026-08-18)

`origin/main` tip (`6b600eea`, 2026-08-19 00:37 +0200):
  - `6b600eea` Merge PR #79 (CI concurrency)
  - `a0113ef4` fix(ci): workflow_dispatch를 최상단 concurrency 그룹 경합에서 뺀다
  - `089018c3` Merge PR #77
  - `c4271f75` fix(ci): release-website 배포에 전용 concurrency 그룹을 준다
  - `2ab4c8d9` docs(handoff): correct style-match verdict + repo'd reference images **← 1차 핸드오프 정정본, 이미 main에 있음**
  - `68c4aeef` docs: session handoff for hanok ledger/PR-C~D/Phase 2
  - `3541c452` fix(test): regenerate stale vocab_packs golden baselines
  - `d4061faa` Merge PR #75 (hoeren-shelf-15slots)
  - `ad80baea` content(batch16): C2 6칸 24편 — 책가도 90칸 전부 완성
  - `fe7f04dd` Merge remote-tracking branch origin/main into main
  - `145e7928` Merge branch `chore/hanok-asset-ledger-backfill` into main **← 한옥 코드 작업 전부**

한옥 작업 커밋 (이미 main ancestor):
  - `e50fd520` PR-B 원장 소급 + 크레딧 상한 600 + 고아 가드
  - `e2b06af1` PR-C 데이터 절반 (`canDoSegmentEvidenceProgress`)
  - `7b7e5d36` PR-D `kRoomFurnishingPool`
  - `3a2d8a6f` Phase 2-1~2-4(부분) 스타일 자동화 착수
  - `770bd48b` Phase 2-3 `asset_recipe.py` + 레시피 6종

## Handoff Chain

- **Continues from**: [2026-08-18-231606-living-hanok-and-decoration-audit.md](./2026-08-18-231606-living-hanok-and-decoration-audit.md)
- **Supersedes**: 위 문서. 그 문서는 내용 골격은 맞지만 **git 위상·테스트 수·다음 브랜치 선택·chaekgado 화병 실측이 틀렸거나 빠졌다.** 다음 세션은 이 파일을 정본으로 읽고, 이전 파일은 대화 맥락용으로만 본다.

> 두 국면은 그대로다. (A) 살아 있는 한옥 PR-B~D + Phase 2는 **이미 main에 병합**됐다. (B) 사랑방 소품 감사는 조사·실측까지 끝났고, **무엇을 새로 그릴지는 Jin 결정이 남았다.**

## Current State Summary

선행 Mac 세션은 `chore/hanok-asset-ledger-backfill`에서 PR-B(원장)·PR-C(데이터 절반)·PR-D(방별 가구 풀)·Phase 2 스타일 파이프라인을 끝낸 뒤 `145e7928`로 main에 넣었다. Jin이 박물관 사진과 참고 이미지 3장(백자술병·자개함·보석함)을 보내 소품 감사를 시작했고, 1차 핸드오프는 이미지를 저장소에 안 넣은 채 "판정 애매"로 끝났다. Jin이 확신을 재차 묻자 같은 세션이 `~/Downloads/` 원본을 `docs/assets/reference_images/`로 넣고 F-A 게이트를 실측한 뒤 `chore/hanok-pr-e-prep`에 커밋했다.

이 Cloud 세션이 그 핸드오프를 **내용까지** 다시 대조했다. 결론:

1. 참고 이미지 3장과 F-A 실측 숫자는 **그대로 재현**됐다.
2. 1차 핸드오프가 안 돌린 비교를 돌렸다. `chaekgado_prop_vase.png`도 F-A 실패(satMean 0.197). 이미 출시된 `decoration_jagae_mungap.png`는 F-A **통과**.
3. 1차 핸드오프의 git 안내는 **이미 틀리다.** `chore/hanok-pr-e-prep`는 빈 브랜치가 아니고 `fe7f04dd` 위의 핸드오프 2개만 있다. 같은 핸드오프 내용은 `2ab4c8d9`로 **이미 origin/main에 있다.** 다음 작업은 prep 브랜치를 이어받지 말고 `origin/main`에서 새 브랜치를 딴다.
4. `validate_handoff.py`의 100/100은 섹션·TODO·시크릿만 본다. 내용 검증이 아니다.

레거시 한옥이 여전히 라이브 정본이다. PR-E cutover·PR-F 발행·Phase 3 별당/서고 생성은 하지 않았다.

## Codebase Understanding

## Architecture Overview

**라이브 vs dark 한옥 (변하지 않음).**
- 라이브: `PersonalHanokProjection` / `hanok_stage_service.dart`. 사용자가 보는 화면은 전부 여기.
- Dark: `HanokExperienceProjector` + draft grant 86개 (`tools/content_factory/drafts/hanok_grants.json`, schema 1 / `hanok_v1_core_2026_v1`). 릴리스 grant 원장 파일은 **아직 없다.** 코멘트의 `publishedGrants: []`는 그 빈 릴리스 원장을 가리키는 말이다. UI 호출자 0. PR-E를 하기 전까지 레거시가 정본.

**STYLE_LOCK family 4개** (`docs/assets/STYLE_LOCK.json`, 이 세션에서 멤버 수·게이트 재확인):
- F-A 18종 — 사랑방 실내. satMean `[0.30, 0.80]`, valMean `[0.25, 0.65]`, neonMax `0.04`.
- F-B 18종 — 마당/절기. 같은 `decorations/` 디렉터리, members로만 구분.
- F-C-estate 21종 — 지도 건물 7 + 단계 PNG 14.
- F-C-a1states 16종 — A1 결정론 합성.

`assets/illustrations/chaekgado/` 8장은 **네 번째 소품 계열**이고 STYLE_LOCK에 없다. 다른 세션 소유. 파일 편집 금지. 재사용은 참조 등록만, Jin 승인 후.

**환경.** 선행 Mac 세션은 여러 Claude가 같은 워킹 디렉터리를 공유해 브랜치가 여러 번 바뀌었다. **이 Cloud VM은 격리된 체크아웃**이라 그 위험이 여기엔 없다. Windows/Mac으로 돌아가면 다시 `git rev-parse --abbrev-ref HEAD`를 커밋 직전에 확인한다.

## Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `docs/assets/STYLE_LOCK.json` | 스타일 정본, family 4개 실측 게이트 | 소품 "우리 화풍" 판단 기준. chaekgado 미등록 |
| `tool/style_lock.py`, `tool/check_style_conformance.py` | 리더 + family 게이트 | 신규 이미지 승인 전 필수. `GREEN_RIM_EXEMPT_FAMILIES = {F-B, F-C-estate}` |
| `tool/asset_recipe.py`, `tool/ledger_append.py` | 레시피 러너 / 원장 append | 신규 소품은 cutout 레시피 → `--check` → `--emit-work-order` → 1장 승인 → `--ingest` |
| `docs/assets/recipes/` | 레시피 6개 | frameEdit 4(솟을대문·행랑채·안채·사당) + newBuilding DRAFT 2(별당·서고) |
| `lib/widgets/sori/placed_decoration.dart` | `kAvailableDecorations`(36) · `kRoomFurnishingPool`(사랑방 12) · `furnishedDecorSlugs()` | 신규 소품 등록 지점 |
| `lib/data/personal_hanok_estate_stage_catalog.dart` | 14개 단계 PNG 리졸버 | orphan guard용. 렌더러는 아직 안 씀 |
| `lib/services/productive_assessment_service.dart` | `canDoSegmentEvidenceProgress()` | PR-C. 라이브 필터 변경 없음 |
| `docs/assets/HANOK_V1_ASSET_PROVENANCE.json` | 한옥 원장, scope `hanok_v1_assets_only` | records 27, costCredits 합 48.0, budget staticMax 600, priorDiscarded 20.6 |
| `docs/assets/A2_FURNISHING_LEDGER.json` | 장식 원장, scope `a2_decoration_furnishing_only` | records 18, costCredits 합 65.0, discarded 28.0 → 93cr |
| `assets/illustrations/chaekgado/` | 책가도 8장 | 다른 세션 소유. 4 props + 4 structure |
| `docs/assets/reference_images/ref_baekja_jubyeong.png` | Jin 백자술병 참고 2048² RGBA | F-A 실패 sat 0.0884 / val 0.9154. 면분할은 맞음 |
| `docs/assets/reference_images/ref_jagaeham.png` | Jin 자개함 참고 1024² RGBA | F-A 실패 sat 0.1543 / val 0.2776. 워터컬러 |
| `docs/assets/reference_images/ref_boseokham.png` | Jin 보석함 참고 1024² RGBA | F-A 실패 sat 0.2044 / val 0.3101. 워터컬러 |
| `assets/illustrations/decorations/decoration_jagae_mungap.png` | 이미 출시된 F-A 자개문갑 | **F-A 통과** sat 0.3456 / val 0.3588. 함/궤를 다시 그릴 때 스타일 앵커 |
| `assets/illustrations/chaekgado/chaekgado_prop_vase.png` | 책가도 청자 화병 414×480 | F-A 실패 sat 0.1968 / val 0.5202. F-A에 그냥 편입하면 게이트가 깨진다 |
| `docs/SESSION_LOG.md` | append-only 세션 로그 | 변경마다 최상단 기록 |
| `AGENTS.md` "현재 진행 중인 작업" | 게이트 체크리스트 | 한옥 항목의 "아직 main 미병합"은 stale — 이 브랜치에서 정정 |

`~/.claude/plans/swift-yawning-squirrel.md`는 **이 Cloud VM에 없다.** Mac 로컬 전용. 저장소 안의 정본은 `docs/SESSION_LOG.md` 2026-08-18 한옥 항목 2개 + `AGENTS.md` 체크리스트다.

### Key Patterns Discovered

- **핸드오프 validator는 내용 검사를 하지 않는다.** `validate_handoff.py`는 TODO 자리표시 없음·필수 섹션 50자·시크릿 정규식·경로 존재만 본다. 100/100을 사실 검증으로 쓰지 말 것.
- **참고 이미지는 반드시 저장소에 넣는다.** 프롬프트 안에서만 보면 머신(Mac→Windows→Cloud)이 바뀌는 순간 유실된다. 위치는 `docs/assets/reference_images/`.
- **파일명으로 자산을 판단하면 틀린다.** `assets/illustrations/hanok/calligraphy.png`와 `assets/illustrations/hanok/achievements.png`는 배너이지 사랑방 소품이 아니다. 이미지 자체를 연다.
- **이미 출시된 자개문갑이 있다.** `decoration_jagae_mungap`은 F-A 통과. Jin이 준 워터컬러 자개함/보석함은 "같은 물건을 우리 화풍으로 다시 그린 것"의 대상이지 스타일 레퍼런스가 아니다.
- **chaekgado 화병도 F-A가 아니다.** 청자/백자류를 F-A에 넣으면 satMean 게이트가 깨진다. 재사용하려면 F-D 신설 또는 자기 게이트가 필요하다.
- **green-rim 휴리스틱**은 연못·소나무를 despill 실패로 오판한다. F-B·F-C-estate는 면제. 청자처럼 초록 콘텐츠가 본체인 소품도 같은 함정.
- **`docs/SESSION_LOG.md`는 여러 세션이 동시에 맨 위에 붙이면 거의 항상 충돌한다.** 양쪽 항목을 유지하고 마커만 제거한다.
- **`paletteDistance`는 경고 전용**이다. 합격/불합격 단일 기준으로 쓰지 말 것.
- **`asset_recipe.py`의 `newBuilding` kind**는 이번 세션 확장이다. 별당·서고처럼 편집할 완성본이 없을 때만. 일반 소품은 `cutout`.

## Work Completed

### Tasks Finished

- [x] PR-B: 한옥 원장 소급 + `budgetCredits.staticMax` 200→600 + `personal_hanok_estate_stage_catalog.dart`로 14단계 PNG orphan 해소. 장식 93cr은 별도 `A2_FURNISHING_LEDGER.json`.
- [x] PR-C: `canDoSegmentEvidenceProgress()` + `nextGrantProgress` + map layer에 nullable `buildingId`/`stageIndex`/`grantId`(전부 null 유지). 라이브 렌더 필터는 PR-E로 미룸.
- [x] PR-D: `kRoomFurnishingPool`. A2 가구 12종이 안방·대청마루 피커에 나오던 버그 수정.
- [x] Phase 2-1~2-3: STYLE_LOCK + style_lock.py + check_style_conformance.py + ledger_append.py + asset_recipe.py. frame 4 + newBuilding DRAFT 2.
- [x] Phase 2-4 일부: `decoration_transparency_test.dart`가 `kAvailableDecorations` 36개를 순회. 등록 자동화 러너는 없음.
- [x] main 병합 `145e7928`. 이후 다른 세션의 batch14/15/16·골든·CI 수정이 main 위에 쌓였다.
- [x] 사랑방 소품 1차 감사: decorations 36 PNG + chaekgado 8 + hanok 15(소품 아님) + interiors 2(배경만).
- [x] 참고 이미지 3장 저장 + F-A 실측 (Mac 세션). 이 Cloud 세션이 같은 숫자를 재현하고, chaekgado 화병·출시 자개문갑까지 측정.

선행 핸드오프가 적은 "flutter test 4018/4018"은 **이 VM에서 재실행하지 않았다.** SESSION_LOG 실측은 한옥 작업 당시 4014, Batch 16 당시 4011 중 4010 green이었다. 테스트 총수를 현재 사실로 단정하지 말 것.

## Files Modified

한옥 코드/데이터는 이미 main (`3a2d8a6f`/`770bd48b`/`145e7928`). 이 문서가 고치는 것은 인수인계 정본과 stale 체크리스트다.

| File | Changes | Rationale |
|------|---------|-----------|
| `.claude/handoffs/2026-08-18-234800-living-hanok-verified-audit.md` | 이 문서 | 1차 핸드오프의 stale git/누락 실측을 대체 |
| `.claude/handoffs/2026-08-18-231606-living-hanok-and-decoration-audit.md` | 상단에 superseded 배너 | 이전 파일을 정본으로 오인하지 않게 |
| `docs/SESSION_LOG.md` | 최상단 항목 | AGENTS.md 기록 규칙 |
| `AGENTS.md` | 한옥 체크리스트의 "아직 main 미병합" 정정 + 소품 감사 항목 | 다음 세션이 이미 끝난 병합을 다시 하지 않게 |

## Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| PR-E / PR-F / Phase 3 생성 안 함 | 실행 / 코드만 / 보류 | 보류. grant 행은 영구 고정, cutover는 라이브 화면, Phase 3는 1장 승인 규칙(어기면 28cr 전례) |
| 별당·서고는 DRAFT 레시피만 | 생성 / 레시피만 | 레시피만. Jin 검토 후 실행 |
| chaekgado 재사용은 제안만 | 바로 등록 / 대기 | 대기. 다른 세션 소유 + 화병이 F-A 게이트 실패 |
| 워터컬러 2장은 스타일 레퍼런스 금지 | 그대로 등록 / 컨셉만 | 컨셉만. 함/궤를 그리면 `decoration_jagae_mungap`을 앵커로 |
| 다음 코드 작업은 prep 브랜치가 아니라 origin/main에서 | prep 이어받기 / main에서 분기 | prep은 `fe7f04dd`에 멈춰 있고 batch16·골든·CI가 빠짐. 핸드오프 파일은 이미 main에 있음 |
| 이 Cloud 세션은 픽셀을 새로 만들지 않음 | 재생성 / 문서만 | 문서만. Jin 승인 없이 생성 호출 금지 |

## Pending Work

## Immediate Next Steps

1. **Jin에게 제작 경로 3개 중 하나를 묻는다. 묻기 전에 생성 호출을 하지 않는다.**
   - (A) 백자술병을 같은 구도/면분할로 F-A 호두목·청자 톤에 맞춰 **재생성**.
   - (B) F-A에 백자/청자 하위 팔레트 예외를 넣고 `ref_baekja_jubyeong.png`를 살릴지 논의. 게이트를 느슨히 하면 기존 18종이 기준선이 된다 — 예외 family가 더 안전하다.
   - (C) 주병은 보류하고, 함/궤만 F-A 골격 + `decoration_jagae_mungap` 앵커로 새로 그린다. 워터컬러 2장은 형태 참고만.
2. **신규 소품 우선순위를 Jin과 확정한다.** 후보: 주병(위 1번), 함/궤, 경대, 약장, 연상, 장목비, 망건통, 병풍 변형(묵포도도). 담배 세트(담뱃대·재떨이·담배합)는 연령/문화 판단이 Jin 몫 — 임의 진행 금지.
3. **chaekgado 4 props(vase·bowl·brushpot·scroll) 재사용은 Jin + 그 폴더 소유 세션과 조율한 뒤에만.** 파일을 건드리지 말고 카탈로그 참조만. vase는 F-A 실패가 확인됐으므로 F-A 흡수보다 F-D 또는 자기 게이트가 맞다.
4. 승인된 소품마다 `docs/assets/recipes/`에 cutout 레시피 → `tool/asset_recipe.py RECIPE --check` → `--emit-work-order` → 1장 승인 → `--ingest`.
5. PR-E/PR-F/Phase 3는 실기기 검수 가능할 때. 지금 시작하지 않는다.

### Blockers/Open Questions

- [ ] 백자술병: 재생성 vs 팔레트 예외 vs 보류 — Jin.
- [ ] 자개함/보석함: F-A로 다시 그릴지, 앱에 넣을지 자체 — Jin. "그대로 등록"은 실측상 불가.
- [ ] 담배 소품 세트 적절성 — Jin. 임의 진행 금지.
- [ ] chaekgado 소유 세션과의 참조 충돌 — Jin 조율.
- [ ] `~/.claude/plans/swift-yawning-squirrel.md`는 Mac에만 있다. 필요하면 저장소로 옮기거나 SESSION_LOG를 정본으로 삼을지 — Jin.
- [x] 화병(a)을 무엇과 대조할지 — 해결. `chaekgado_prop_vase` sat 0.1968 / val 0.5202 (F-A 실패), 참고 백자술병 sat 0.0884 / val 0.9154 (F-A 실패). 둘 다 면분할이고 팔레트만 다름.
- [x] `chore/hanok-pr-e-prep`를 이을지 — 해결. 잇지 말 것. `origin/main`에서 새 브랜치.

### Deferred Items

- PR-E cutover: grant 발행 + `hanok_world_screen.dart` 실배선. 영구 고정 + 실기기 검수.
- PR-F 레벨별 발행: PR-E 종속.
- Phase 3 별당·서고 실제 생성: DRAFT 레시피만 있음. 이미지 0.
- `asset_recipe.py --ingest`의 sheet/frameEdit/overlay/newBuilding: cutout만 자동화됨.
- Phase 2-4 등록 자동화 러너: 새 자산이 생기기 전 보류.
- A2 외관 오버레이 3종(`a2_chimney_smoke`·`a2_lantern_lit`·`a2_ridge_magpie`) 승격: `assets_unused/pending_review/estate_overlays/qa/`에만 있음. pubspec 미선언. 장독 위치는 candidate A(안채 안뜰) / B(사랑마당) 미정.

## Context for Resuming Agent

## Important Context

- **한옥 코드는 이미 main에 있다.** 다시 병합하지 말 것. 다음 작업은 `origin/main`에서 새 브랜치.
- **`chore/hanok-pr-e-prep`는 쓰지 말 것.** tip `86c497a6`은 `fe7f04dd` 위 핸드오프 2개뿐이고, 같은 내용은 `2ab4c8d9`로 main에 있다. prep에는 batch16·골든·CI 수정이 없다.
- **레거시 한옥이 라이브 정본.** `publishedGrants` 릴리스 파일은 아직 없다. grant 행을 쓰면 되돌릴 수 없다.
- **생성 규칙 (STYLE_LOCK `generationFacts`):** 참조 이미지 정확히 1장, resolution 명시(기본 1K로 조용히 떨어짐), `edit_image` 출력은 항상 2400×1792, LANCZOS가 저알파 림에 청록을 되살림(재디스필). 모델은 F-A 정식 경로 GPT Image 2, Seedream V4.5 금지(그림자·매끈한 렌더).
- **크레딧 원장 (파일에서 다시 합산):** 한옥 provenance records 27 / 48.0cr + discarded 20.6. A2 가구 18 / 65.0cr + discarded 28.0. budget staticMax 600. 선행 핸드오프의 "596.2cr 잔액"은 이 VM에서 재확인 불가 — 스냅샷이지 정본이 아니다.
- **에셋 실측 목록 (이 VM에서 ls + git ls-files):**
  - 런타임 단계 PNG 14: `assets/illustrations/personal_hanok_v2/map/stages/` (pubspec 선언됨).
  - 미승격 오버레이: `assets_unused/pending_review/estate_overlays/qa/`의 chimney/lantern/magpie + 장독 후보 2 + 합성 QA.
  - decorations PNG 36 + `.gitkeep` 1.
  - chaekgado 8.
  - hanok 일러스트 15 (소품 아님).
  - interiors 2 (`anbang_empty`, `daecheong_empty`).
  - 참고 이미지 3 (`docs/assets/reference_images/`).
  - 별당·서고 이미지 0.
- **이번 Cloud 세션은 픽셀을 만들지 않았다.** 문서·재실측만.

## Assumptions Made

- Jin의 파일명(백자술병·자개함·보석함)은 **앱에 넣을 물건 후보**다. 다만 "이 파일을 그대로 쓴다"는 뜻은 아니다 — 세 장 모두 F-A 실패가 두 세션에서 재현됐다.
- chaekgado 참조 등록은 파일 미편집이라 물리 충돌은 없지만, 소유 세션이 같은 파일을 두 시스템에 거는 걸 거부할 수 있다. 미검증.
- 선행 세션의 "공유 워킹 디렉터리에서 브랜치가 4번 바뀌었다"는 Mac 환경 주장이다. 이 Cloud 세션은 재현하지 않았다. Windows/Mac으로 돌아가면 다시 유효할 수 있다.

## Potential Gotchas

- 1차 핸드오프를 그대로 따르면 **뒤처진 prep 브랜치에 커밋**하게 된다. 이 파일이 그 안내를 대체한다.
- `AGENTS.md` 한옥 항목은 이 브랜치에서 고치기 전까지 "아직 main 미병합"이라고 거짓말한다.
- F-A 게이트에 백자/청자를 억지로 넣으면 기존 18종 ShippedBaseline이 기준선 분쟁에 휘말린다.
- `check_style_conformance.py`는 기법을 보지 않는다. 워터컬러 vs 면분할은 사람이 이미지를 열어야 한다. sat/val만으로 "구조 일치"를 증명할 수 없다.
- 이 Cloud VM의 Python은 `/usr/bin/python3.12`이고, 시작 시 Pillow가 없었다. Mac 핸드오프의 `/usr/local/bin/python3.12` 고정 경로는 여기선 없다.
- Open PR은 이 작업과 무관한 `#78` (session-log rotation)만 있다. prep 브랜치 PR은 없다.

## Environment State

### Tools/Services Used

- 이 Cloud VM: `/usr/bin/python3.12` + 세션 중 설치한 Pillow/numpy. 재실측에 필요.
- Mac 선행 세션: `/usr/local/bin/python3.12`, BBANANA MCP, `gh`, `npx skills`로 session-handoff 설치.
- `session-handoff` 스킬: `.claude/skills/session-handoff/`. validator는 형식만 본다.

### Active Processes

- 없음. 전체 flutter test는 이 Cloud 세션에서 돌리지 않았다.

### Environment Variables

- 특별히 설정한 것 없음. 시크릿 없음.

## Independent Verification Log (이 Cloud 세션이 다시 본 것)

검증한 것:
- 커밋 13개 (`3541c452` … `770bd48b`, `6b600eea`, `2ab4c8d9`, `86c497a6`) 메시지 일치.
- `origin/main` = `6b600eea`가 `2ab4c8d9`를 ancestor로 가짐. `86c497a6`은 prep에만 있음.
- 참고 이미지 3장 디스크 존재·크기·RGBA·F-A 수치 재현.
- `chaekgado_prop_vase` / `decoration_jagae_mungap` F-A 신규 측정.
- decorations 36, chaekgado 8, stages 14, hanok 15, interiors 2, recipes 6, STYLE_LOCK family 4, grants draft 86, provenance 27/48.0cr, A2 ledger 18/65.0cr.
- `kAvailableDecorations` 36, `kRoomFurnishingPool`은 사랑방 12만.
- 릴리스 grant 원장 파일은 아직 없음(draft `tools/content_factory/drafts/hanok_grants.json`만 86개). 계획 파일 swift-yawning-squirrel.md 는 이 VM에 없음.

검증하지 않은 것:
- flutter test 전체 스위트 재실행 (시간/러너 비용). 총수 4018 주장은 채택하지 않음.
- BBANANA 크레딧 잔액 596.2.
- Mac 공유 디렉터리 브랜치 충돌 횟수.
- 워터컬러 판정은 사람이 이미지를 연 정성 평가. 스크립트는 기법을 측정하지 않음.

## Related Resources

- 이전 핸드오프(superseded): `.claude/handoffs/2026-08-18-231606-living-hanok-and-decoration-audit.md`
- `docs/SESSION_LOG.md` — 2026-08-18 "Phase 2-3 완성 후속" + "원장 소급 기록 + PR-C/D + Phase 2 자동화 착수"
- `docs/assets/STYLE_LOCK.json`
- `docs/assets/recipes/`
- `docs/assets/reference_images/`
- `docs/HANOK_ASSET_INVENTORY_2026-08-17.md` — F-A 원본 6종만 실측한 스냅샷. STYLE_LOCK이 우선.
- `docs/HANDOFF_LIVING_HANOK_V1_PR3_2026-08-16.md`, `docs/HANDOFF_LIVING_HANOK_V1_PR4_2026-08-17.md` — 더 이전 한옥 핸드오프. PR-B~D 이후 상태에는 이 파일이 우선.

---

**Security Reminder**: `validate_handoff.py`는 형식·시크릿만 본다. 통과해도 내용을 다시 대조해야 한다.
