# Handoff: 한옥 자산을 스킬로 다시 실측한 인수인계

다음 세션은 이 파일만 정본으로 읽는다. 이전 두 핸드오프는 대화 맥락용이다.

## Session Metadata
- Created: 2026-08-18 23:52:00
- Project: `/workspace` (Cursor Cloud). Mac 원본 경로는 `/Users/sujinpark/Developer/ko_lernen_app`
- Branch: `cursor/hanok-asset-handoff-fb5a` from `origin/main` @ `a00fc1d1`
- Session duration: 이 Cloud 세션. 선행은 Mac PR-B~D + Phase 2 + 소품 감사, 그다음 실측 핸드오프(PR #80)

### Recent Commits (for context)

`origin/main` tip `a00fc1d1` (이 세션이 `git fetch origin main` 후 `git rev-parse --short origin/main`으로 확인):

- `a00fc1d1` docs(session-log): 3일 로테이션 규칙 + 재사용 아카이브 도구 (#78)
- `6b600eea` Merge PR #79
- `2ab4c8d9` docs(handoff): 1차 핸드오프 정정 + 참고 이미지 3장 (이미 main ancestor)
- `68c4aeef` 1차 핸드오프
- `145e7928` Merge `chore/hanok-asset-ledger-backfill` into main (한옥 코드 전부)

한옥 코드 ancestor (이미 main):

- `e50fd520` PR-B 원장
- `e2b06af1` PR-C 데이터 절반
- `7b7e5d36` PR-D 방별 가구 풀
- `3a2d8a6f` Phase 2-1~2-4 일부
- `770bd48b` `asset_recipe.py` + 레시피 6종

이 세션이 확인한 열린 draft PR (구현 착수 대상 아님):

- #80 `cursor/living-hanok-verified-handoff-fb5a` (`09094b1a`): 직전 실측 핸드오프
- #81 `cursor/hanok-pipeline-gates-fb5a` (`3c788ff9`): 레시피 러너 지출 구멍. **main ancestor 아님**
- #82 `cursor/content-ui-feed-plan-fb5a`: 콘텐츠 UI 계획. Jin이 오더를 한옥 인수로 정정함. 한옥 작업과 섞지 말 것

## Handoff Chain

- **Continues from**: [2026-08-18-234800-living-hanok-verified-audit.md](./2026-08-18-234800-living-hanok-verified-audit.md)
- **Supersedes**: 위 파일과 [2026-08-18-231606-living-hanok-and-decoration-audit.md](./2026-08-18-231606-living-hanok-and-decoration-audit.md)

234800은 git 위상·참고 이미지 숫자는 맞았다. 아래는 그 문서가 틀리거나 빠뜨린 사실이다:

1. 릴리스 원장 파일은 있다. `tools/content_factory/release_ledgers/hanok_grants_v1.json` = `{schemaVersion: 1, publishedGrants: []}`. "파일이 없다"는 오보다. 빈 리스트가 맞다.
2. 책가도 props 4장 중 vase만 F-A 실패. bowl / brushpot / scroll은 F-A **통과**. 네 장 모두 F-D가 필요하다는 안내는 과하다.
3. A1 런타임 `assets/illustrations/personal_hanok_v2/a1/states/` 16 WebP는 pubspec에 있다. `assets_unused/pending_review/a1_states/` 16장과 sha256이 **16/16 동일**하다. unused를 새 리메이크로 쓰지 말 것.
4. `origin/main` tip은 `6b600eea`가 아니라 지금 `a00fc1d1`이다.
5. 파이프라인 게이트(`3c788ff9`)는 main에 없다. main의 frameEdit 레시피는 `resolution`/`status` 키가 없다. STYLE_LOCK F-A는 Seedream을 문장으로만 금하고 `allowed: false`가 없다.

## Current State Summary

살아 있는 한옥 PR-B~D와 Phase 2 자동화는 `145e7928`로 main에 들어 있다. 사용자는 레거시 한옥만 본다. `HanokExperienceProjector` 호출은 `lib/screens/` 0건이다. 호출부는 `hanok_cutover_service.dart`와 테스트뿐이다.

사랑방 소품 감사는 조사·실측까지 끝났다. 새로 그릴지는 Jin이 고른다. 이 세션은 픽셀을 만들지 않았다. `session-handoff` CREATE, `verification-before-completion`, Vercel writing-guidelines(숫자·능동태), Anthropic frontend-design(화풍 판정), `ui-ux-pro-max` color 검색(해당 항 0건, STYLE_LOCK 게이트로 폴백)으로 자산 목록·게이트·원장·PR 위상을 다시 쟀다.

다음 코드 작업은 `origin/main`에서 새 브랜치를 딴다. `chore/hanok-pr-e-prep`와 `chore/hanok-asset-ledger-backfill`을 잇지 말 것. `AGENTS.md`의 "아직 main 미병합"은 stale이다.

## Codebase Understanding

## Architecture Overview

라이브 한옥은 `PersonalHanokProjection` / `hanok_stage_service.dart`다. dark 한옥은 `HanokExperienceProjector` + draft 86 grant (`tools/content_factory/drafts/hanok_grants.json`)다. Flutter production loader는 런타임 grant JSON을 싣지 않는다. `test/hanok_v1_source_guard_test.dart`가 그 부재를 고정한다. 릴리스 원장에 행을 넣는 순간 영구 고정이다.

STYLE_LOCK family 4개 (`docs/assets/STYLE_LOCK.json`, `python3.12`로 families 키 확인):

| Family | Members | Dirs | satMean | valMean | neonMax |
|--------|---------|------|---------|---------|---------|
| F-A 사랑방 | 18 | `decorations/` | [0.30, 0.80] | [0.25, 0.65] | 0.040 |
| F-B 마당/절기 | 18 | 같은 `decorations/`, members로만 구분 | [0.20, 0.80] | [0.25, 1.00] | 0.35 |
| F-C-estate 지도 | 21 | structures + landscape + stages | [0.24, 0.65] | [0.34, 0.70] | 0.030 |
| F-C-a1states | 16 | `a1/states/` | (lock 실측 sat 0.261–0.610대, 이 세션 `--all` 73/73 ok) | | |

main의 F-A `modelRouting`은 GPT Image 2 채택 + Seedream "쓰지 말 것" 문장이다. `allowed: true|false`는 **#81에만** 있다. F-B / F-C-a1states `modelRouting`은 main에서 `[]`다. F-C-estate는 Nano Banana Pro 문장만 있다.

책가도 8장은 다섯 번째 소품 더미이고 STYLE_LOCK 멤버가 아니다. 파일 편집 금지. pubspec은 `assets/illustrations/chaekgado/`를 이미 선언한다.

Gye의 `assets/illustrations/gye/gye_byeoldang.png`는 계 합성용이다. Phase 3 별당 레시피와 같은 이미지가 아니다.

## Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `docs/assets/STYLE_LOCK.json` | family 4 게이트·팔레트·골격 | 화풍 판정. chaekgado 미등록 |
| `tool/style_lock.py` | 리더 | `family_for_slug`는 members만 본다. 참고 이미지는 CLI `--all` 밖 |
| `tool/check_style_conformance.py` | sat/val/neon/greenRim | `--family` 플래그 없음. 비멤버는 `check(path, lock, "F-A")`로 강제 |
| `tool/asset_recipe.py` | 레시피 러너 | main은 DRAFT를 `--check`/`--emit`에서  automat으로 막지 않음. #81이 막음 |
| `docs/assets/recipes/` | 레시피 6 | frameEdit 4 (main: status/resolution 키 없음) + newBuilding DRAFT 2 (`resolution: 2K`) |
| `tool/derive_estate_building_stages.py` | `FRAME_PROMPTS` ~272행 | 레시피와 이중 SSoT |
| `lib/widgets/sori/placed_decoration.dart` | `kAvailableDecorations` 36, `kRoomFurnishingPool`은 `sarangbang` 12만 | 등록 지점 |
| `lib/data/personal_hanok_estate_stage_catalog.dart` | 14 단계 PNG | 렌더러 미사용. 주석이 `publishedGrants: []`를 가리킴 |
| `lib/services/hanok_grant_catalog.dart` | `fromJson`은 `grants` 키 요구 | 릴리스 파일의 `publishedGrants`와 스키마가 다름 |
| `tools/content_factory/drafts/hanok_grants.json` | draft 86 | 앱 asset 아님 |
| `tools/content_factory/release_ledgers/hanok_grants_v1.json` | `publishedGrants: []` | 파일은 있다. 행은 0 |
| `docs/assets/HANOK_V1_ASSET_PROVENANCE.json` | scope `hanok_v1_assets_only` | records 27, costCredits 합 48.0, priorDiscarded 20.6, staticMax 600 |
| `docs/assets/A2_FURNISHING_LEDGER.json` | scope `a2_decoration_furnishing_only` | records 18, costCredits 합 65.0, priorDiscarded 28.0 |
| `docs/assets/reference_images/ref_*.png` | Jin 참고 3장 | 아래 실측표 |
| `assets/illustrations/decorations/decoration_jagae_mungap.png` | 출시 F-A 자개문갑 | 함/궤 스타일 앵커 |
| `~/.claude/plans/swift-yawning-squirrel.md` | Mac 계획 | **이 VM에 없음** |

## Key Patterns Discovered

- `validate_handoff.py` 100점은 섹션·TODO·시크릿·경로만 본다. 내용 검사가 아니다
- `check_style_conformance.py`는 기법을 보지 않는다. 워터컬러 vs 면분할은 이미지를 연다
- pngquant P-mode(`chaekgado_prop_vase.png`는 mode P, 414×480)는 소프트에지 휴리스틱을 속인다. 이 게이트는 그걸 의도적으로 빼 두었다
- green-rim은 연못·소나무를 despill로 오판한다. `GREEN_RIM_EXEMPT_FAMILIES = {F-B, F-C-estate}`
- `paletteDistance`는 경고 전용이다. 백자술병은 pal 24.86으로 경고선(40) 아래인데 sat/val로 탈락한다
- 파일명으로 자산을 판단하지 말 것. `assets/illustrations/hanok/calligraphy.png`는 배너다
- 참고 이미지는 `docs/assets/reference_images/`에 커밋한다
- main에서 DRAFT 별당/서고 `--emit-work-order`를 돌리지 말 것. #81 병합 전엔 코드가 막지 않는다
- Anthropic `brand-guidelines`와 `ui-ux-pro-max` 기본 인디고/Claymorphism은 한옥 픽셀에 적용하지 않는다. 화풍 정본은 STYLE_LOCK > inventory > BIBLE이다

## Work Completed

## Tasks Finished

선행 Mac (이미 main):

- [x] PR-B 원장 + budget 600
- [x] PR-C `canDoSegmentEvidenceProgress()` (라이브 필터 변경 없음)
- [x] PR-D `kRoomFurnishingPool` (사랑방 12만)
- [x] Phase 2-1~2-3 STYLE_LOCK + 도구 + 레시피 6
- [x] Phase 2-4: `decoration_transparency_test.dart`가 36 slug 순회. 등록 러너 없음
- [x] 소품 1차 감사 + 참고 3장 저장 + F-A 숫자 (Mac, 234800이 재현)

이 Cloud 세션:

- [x] 참고 3장 F-A 숫자 재현
- [x] 책가도 4 props F-A 강제 측정 (bowl/brushpot/scroll 통과, vase 실패)
- [x] 출시 `decoration_jagae_mungap` 통과 재확인
- [x] 이미지를 열어 기법 판정: 함 참고=사실/워터컬러 나전, 문갑=면분할, 그릇/화병=면분할
- [x] 원장·grant·A1 해시·PR 위상·`--all` 73/73을 이 VM에서 다시 돌림
- [x] 잘못된 콘텐츠 UI 계획(#82)과 한옥 인수를 분리

flutter 전체 스위트는 돌리지 않았다. 4018 주장을 반복하지 말 것.

## Files Modified

한옥 픽셀·레시피·Dart는 이 커밋에서 안 바꾼다.

| File | Changes | Rationale |
|------|---------|-----------|
| `.claude/handoffs/2026-08-18-235200-hanok-asset-skill-audit.md` | 이 문서 | 234800의 빠진 실측을 대체 |
| `.claude/handoffs/2026-08-18-234800-*.md` | superseded 배너 | 오인 방지 |
| `.claude/handoffs/2026-08-18-231606-*.md` | superseded 배너 | 오인 방지 |
| `docs/SESSION_LOG.md` | 최상단 항목 | AGENTS 기록 규칙 |
| `AGENTS.md` | "아직 main 미병합" 정정 + 이 핸드오프 포인터 | 다음 세션이 끝난 병합을 다시 하지 않게 |

## Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| 픽셀 생성 0 | 재생성 / 문서만 | Jin 승인 전 생성 금지. 28cr 전례 |
| 책가도 3 props는 F-A 숫자 통과로 기록 | 네 장 모두 F-D / 실측대로 | 숫자는 통과. 등록은 여전히 소유 세션 + Jin |
| 함/궤 스타일 앵커는 출시 문갑 | 워터컬러 참고 / 문갑 | frontend-design: 시그니처는 면분할. 참고 함은 매체 자체가 다름 |
| 다음 작업은 origin/main에서 | prep 이어받기 / main | prep `86c497a6`은 `fe7f04dd` + 핸드오프뿐. batch16·CI 없음 |
| #81을 이 브랜치에 머지하지 않음 | 같이 올림 / 문서만 | 게이트 수정은 별 PR. 인수와 섞지 않음 |
| #82 UI 계획은 한옥과 무관 | 같이 진행 / 분리 | Jin이 오더를 정정함 |

## Pending Work

## Immediate Next Steps

1. Jin에게 주병·함/궤 경로를 묻는다. 답 없이 `--emit-work-order`를 돌리지 않는다.
   - 주병 A: 같은 구도/면분할로 F-A 호두목 또는 청자 톤 재생성
   - 주병 B: 백자/청자 하위 family (기존 18종 게이트를 느슨히 하지 말 것)
   - 주병 C: 보류
   - 함/궤: `decoration_jagae_mungap`을 참조 1장으로 F-A 골격 재생성. `ref_jagaeham.png` / `ref_boseokham.png`는 형태만
2. 나머지 후보 우선순위: 경대, 약장, 연상, 장목비, 망건통, 병풍 변형. 담배 세트는 Jin 연령/문화 판단. 임의 진행 금지
3. 책가도 재사용은 파일 미편집 + 카탈로그 참조만. vase는 F-A 실패이므로 흡수 금지. bowl/brushpot/scroll은 숫자 통과이나 소유 세션 조율 후
4. 승인된 소품만 cutout 레시피 → `--check` → `--emit-work-order` → 1장 승인 → `--ingest`. #81이 main에 오기 전에는 DRAFT emit을 수동으로도 하지 말 것
5. PR-E / PR-F / Phase 3 별당·서고 생성은 실기기 검수 후. 지금 시작하지 않는다

## Blockers/Open Questions

- [ ] 백자술병: 재생성 vs 예외 family vs 보류 (Jin)
- [ ] 함/궤를 앱에 넣을지 (Jin). 워터컬러 원본 등록은 실측상 불가
- [ ] 담배 소품 (Jin)
- [ ] 책가도 소유 세션과의 참조 (Jin)
- [ ] Mac 전용 `swift-yawning-squirrel.md`를 저장소로 옮길지 (Jin)
- [ ] #81을 main에 넣을지. 넣기 전 main 러너는 Seedream/`resolution: null`/DRAFT emit을 코드로 막지 않는다
- [x] 화병 대조 대상: vase sat 0.1968 / 참고 주병 sat 0.0884. 둘 다 면분할, 팔레트만 실패
- [x] prep 브랜치: 잇지 말 것

## Deferred Items

- PR-E cutover + `hanok_world_screen.dart` 실배선
- PR-F 레벨별 발행
- Phase 3 별당·서고 이미지 (현재 0). DRAFT 레시피만
- `asset_recipe.py --ingest`의 sheet/frameEdit/overlay/newBuilding (cutout만 자동화)
- Phase 2-4 등록 러너
- A2 오버레이 승격: `assets_unused/pending_review/estate_overlays/qa/`의 `a2_chimney_smoke` · `a2_lantern_lit` · `a2_ridge_magpie` + 장독 후보 A/B. pubspec 미선언
- FRAME_PROMPTS vs recipes 이중 SSoT
- Dart `kAvailableDecorations` ↔ STYLE_LOCK members 래칫

## Context for Resuming Agent

## Important Context

한옥 코드는 이미 main에 있다. 다시 병합하지 말 것.

레거시 한옥이 라이브 정본이다. `publishedGrants` 행은 0이다. draft 86을 Flutter asset으로 올리지 말 것.

생성 규칙 (`STYLE_LOCK.generationFacts`): 참조 정확히 1장, resolution 명시(기본 1K), `edit_image` 출력 2400×1792, LANCZOS 후 재디스필, 2K 호출 ≈ 4cr. F-A 정식 모델은 GPT Image 2. Seedream은 그림자·매끈한 렌더로 탈락.

크레딧 원장 (이 세션이 JSON에서 재합산): 한옥 27레코드 / 48.0cr + discarded 20.6. A2 18레코드 / 65.0cr + discarded 28.0. staticMax 600. "596.2 잔액"은 이 VM에서 확인 불가.

에셋 실측 (이 VM `ls` + `git merge-base` + sha256):

- decorations PNG 36, `kAvailableDecorations` 36
- chaekgado 8 (prop 4 + 구조 4). pubspec 선언됨
- map/stages PNG 14, pubspec 선언
- a1/states WebP 16, pubspec 선언. unused 사본 16장과 해시 동일
- hanok 일러스트 15 (소품 아님)
- interiors 2 (`anbang_empty`, `daecheong_empty`)
- 참고 이미지 3
- 별당·서고 생성 이미지 0
- estate overlay QA 12파일 (승격 아님)
- recipes 6
- STYLE_LOCK `--all` 73/73 passed (`python3.12 tool/check_style_conformance.py --all`)

F-A 강제 실측 (이 세션 `check(path, lock, "F-A")`):

| File | size / mode | satMean | valMean | palDist | F-A | 기법 (이미지 오픈) |
|------|-------------|---------|---------|---------|-----|-------------------|
| `ref_baekja_jubyeong.png` | 2048² RGBA | 0.0884 | 0.9154 | 24.86 | fail sat+val | 면분할 백자. 팔레트만 실패 |
| `ref_jagaeham.png` | 1024² RGBA | 0.1543 | 0.2776 | 9.68 | fail sat | 광택 나전, 워터컬러/사실. 스타일 레퍼런스 금지 |
| `ref_boseokham.png` | 1024² RGBA | 0.2044 | 0.3101 | 13.56 | fail sat | 위와 같음 |
| `chaekgado_prop_vase.png` | 414×480 P | 0.1968 | 0.5202 | 13.40 | fail sat | 면분할 청자. F-A 흡수 금지 |
| `chaekgado_prop_bowl.png` | (측정함) | 0.4730 | 0.4464 | 12.03 | pass | 면분할 사기. 숫자상 F-A 호환 |
| `chaekgado_prop_brushpot.png` | | 0.6081 | 0.4112 | 7.96 | pass | 숫자상 F-A 호환 |
| `chaekgado_prop_scroll.png` | | 0.6203 | 0.5919 | 8.91 | pass | 숫자상 F-A 호환 |
| `decoration_jagae_mungap.png` | 664×356 RGBA | 0.3456 | 0.3588 | 6.82 | pass | 면분할 자개문갑. 함/궤 앵커 |

`ui-ux-pro-max` `"watercolor vs faceted illustration palette saturation" --domain color`는 0건이었다. 색 판정은 STYLE_LOCK 게이트 + 이미지 오픈이 정본이다.

## Assumptions Made

- Jin 파일명(백자술병·자개함·보석함)은 앱에 넣을 물건 후보다. 원본 PNG를 그대로 등록한다는 뜻은 아니다
- 책가도 3 props의 F-A 숫자 통과가 곧 카탈로그 등록 허가는 아니다
- unused A1 16장이 런타임과 해시가 같으므로, AGENTS의 "05~10 계보를 새로 만든다"는 아직 런타임에 반영되지 않았거나 이미 같은 파일이 정본이다. 이 세션은 시각 리메이크 여부를 픽셀 단위로 재판정하지 않았다
- Mac 공유 디렉터리 브랜치 충돌은 이 Cloud VM에 없다. Windows/Mac으로 돌아가면 커밋 전 `git rev-parse --abbrev-ref HEAD`를 다시 한다

## Potential Gotchas

- `AGENTS.md` 한옥 항목은 이 커밋 전 "아직 main 미병합"이라고 거짓말한다
- main `asset_recipe.py`는 DRAFT·Seedream·`resolution: null`을 하드 차단하지 않는다. #81을 읽지 않고 emit 하면 크레딧이 나간다
- F-A 게이트를 백자용으로 넓히면 ShippedBaseline 18종이 기준선 분쟁에 들어간다
- `HanokGrantCatalog.fromJson`은 `grants`를 요구한다. 릴리스 파일의 `publishedGrants`를 그대로 넣으면 FormatException이다
- `gye_byeoldang.png`를 Phase 3 입력으로 쓰지 말 것
- #82는 한옥 인수와 무관하다. 그 계획대로 학습 피드를 이 브랜치에서 구현하지 말 것

## Environment State

### Tools/Services Used

- `/usr/bin/python3.12` + Pillow/numpy. Mac 핸드오프의 `/usr/local/bin/python3.12`는 여기 없다
- `session-handoff` 스크립트: `.claude/skills/session-handoff/`
- `verification-before-completion`: 위 숫자는 이 세션 명령 출력
- writing-guidelines (Vercel command.md): 능동태, 구체 숫자, easy/simple 금지
- frontend-design: 면분할 vs 워터컬러 매체 분리
- `ui-ux-pro-max` color 검색: 0건, persist 안 함
- `gh pr list`

### Active Processes

없음. 전체 `flutter test` 미실행.

### Environment Variables

설정한 시크릿 없음.

## Related Resources

- 직전 실측 핸드오프 (superseded): `.claude/handoffs/2026-08-18-234800-living-hanok-verified-audit.md`
- 초안 핸드오프 (superseded): `.claude/handoffs/2026-08-18-231606-living-hanok-and-decoration-audit.md`
- `docs/assets/STYLE_LOCK.json`
- `docs/HANOK_ASSET_INVENTORY_2026-08-17.md` (F-A 원본 6만 실측한 스냅샷. STYLE_LOCK이 우선)
- `docs/HANDOFF_LIVING_HANOK_V1_PR3_2026-08-16.md`, `docs/HANDOFF_LIVING_HANOK_V1_PR4_2026-08-17.md` (더 이전)
- `docs/ASSET_GENERATION_BIBLE.md` (일러스트 바이블. UI 바이블이 아님)
- draft PR #81: 러너 게이트. 이 인수 다음의 코드 작업이면 그 브랜치를 읽고 시작

## Independent Verification Log

검증한 것 (2026-08-18, 이 VM):

- `origin/main` = `a00fc1d1`. `2ab4c8d9` ancestor YES. `145e7928` ancestor YES. `3c788ff9` ancestor NO
- 참고 3장 크기·RGBA·F-A 숫자 재현
- 책가도 4 props + 문갑 F-A 강제 측정
- bowl/문갑/화병/함 참고 이미지 오픈
- decorations 36, chaekgado 8, stages 14, a1 states 16, hanok 15, interiors 2, recipes 6, overlay QA 12
- a1 runtime vs unused sha256 16/16 동일
- provenance 27/48.0 + 20.6, A2 18/65.0 + 28.0, budget 600
- draft grants 86, release `publishedGrants` 0, 런타임 grant JSON 부재(가드 테스트가 고정)
- `kAvailableDecorations` 36, `kRoomFurnishingPool` surfaces = sarangbang only
- projector: screens 0, cutover + 2 tests
- STYLE_LOCK `--all` 73/73
- `swift-yawning-squirrel.md` 부재
- open PR 80/81/82

검증하지 않은 것:

- flutter 전체 스위트
- BBANANA 잔액
- 워터컬러 판정의 정량 지표 (스크립트 없음)
- A1 05–10이 Codex 깨진 계보인지 시각 재판정
- #81 테스트 재실행 (이미 그 PR에서 42/42를 주장함. 이 세션은 재실행하지 않음)
