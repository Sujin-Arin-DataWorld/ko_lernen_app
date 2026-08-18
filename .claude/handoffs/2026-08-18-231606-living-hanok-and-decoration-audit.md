> **SUPERSEDED (2026-08-18 밤).** 정본은
> [2026-08-18-234800-living-hanok-verified-audit.md](./2026-08-18-234800-living-hanok-verified-audit.md).
> 이 문서는 대화 맥락용으로만 남긴다. git 위상(`chore/hanok-pr-e-prep`가 빈 브랜치라는 주장),
> 테스트 수 4018/4018, chaekgado 화병 미실측이 이 파일 기준으로는 틀리거나 빠졌다.

# Handoff: 살아 있는 한옥 — 원장/PR-B~D/Phase 2 자동화 완료 + 사랑방 소품 감사(진행 중)

## Session Metadata
- Created: 2026-08-18 23:16:06
- Project: /Users/sujinpark/Developer/ko_lernen_app
- Branch: `chore/hanok-pr-e-prep` (main에서 분기, 아직 아무 hanok 커밋도 없음 — 빈 브랜치)
- Session duration: 매우 긺 (Jin이 4시간 자리 비운 전체 구간 + 복귀 후 대화)

### Recent Commits (for context)
이 브랜치(`chore/hanok-pr-e-prep`)는 지금 main(`3541c452`)에서 갈라져 나온 **빈 브랜치**다 — 아직
아무 커밋도 없다. 이번 세션의 실제 hanok 작업은 이미 **main에 병합·푸시 완료**돼 있다(아래
"Work Completed" 참고). 이 handoff 문서 자체가 이 브랜치의 첫 커밋이 될 것이다.

main 최근 히스토리(다른 세션들이 이 세션 도중에도 계속 푸시했다 — 공유 작업 디렉터리):
  - `3541c452` fix(test): regenerate stale vocab_packs golden baselines
  - `d4061faa` Merge PR #75 (hoeren-shelf-15slots)
  - `ad80baea` content(batch16): C2 6칸 24편 — 책가도 90칸 전부 완성
  - `fe7f04dd` **Merge remote-tracking branch 'origin/main' into main** ← 이 세션이 만든 마지막 병합점
  - `145e7928` **Merge branch 'chore/hanok-asset-ledger-backfill' into main** ← 이 세션의 hanok 작업 전부가 여기 들어감

## Handoff Chain

- **Continues from**: 없음 (이 세션 자체가 최초 — 이전 handoff 문서 없음)
- **Supersedes**: 없음

> 이 세션은 두 개의 뚜렷한 국면으로 이뤄졌다: (A) "살아 있는 한옥" 계획(PR-B~D + Phase 2 자동화)
> 실행 → 병합 → 푸시 완료. (B) Jin이 박물관 사진 + 참고 이미지 3장을 보내 시작된 **사랑방 소품
> 감사** — 조사·실측은 끝났지만 **무엇을 실제로 제작할지 최종 결정은 아직 Jin 몫**, 다음 세션
> (Windows)이 이어받아야 한다.

## Current State Summary

이번 세션은 원래 `docs/SESSION_LOG.md` 최상단·`AGENTS.md` "현재 진행 중인 작업" 체크리스트에
전부 기록된 "살아 있는 한옥 — 배선·자동화·세분화" 계획(정본: `~/.claude/plans/swift-yawning-squirrel.md`)
을 실행하는 것으로 시작했다. Jin이 4시간 자리를 비우며 "계획 전부 끝낼 때까지 진행, 네 브랜치에서만
작업"이라 지시했고, 그 결과 PR-B(원장 소급 기록)·PR-C(데이터 절반)·PR-D(가구 버그 수정)·
Phase 2-1~2-3(스타일 자동화 파이프라인 전체) + Phase 2-4 일부가 완성돼 **이미 main에 병합·푸시**됐다
(커밋 `145e7928`, 이후 다른 세션들의 batch14/15 콘텐츠 작업과도 무충돌 재병합해 `fe7f04dd`까지
반영). 전체 flutter test 스위트는 그 시점에 4018/4018 전부 통과했다.

Jin이 돌아온 뒤, 화제가 **사랑방 인테리어 소품 감사**로 전환됐다. Jin이 실제 한옥 박물관(은평역사한옥박물관,
백인제가옥) 사진 다수를 보내 "이 스타일로 우리 것도 재현하자, 지금 카탈로그와 비교해 없는 걸 만들자"고
요청했다. 1차 조사에서 `assets/illustrations/decorations/`(36개, F-A+F-B)만 봤다가 Jin에게 "화병은
이미 있다"는 지적을 받았고, 재조사 결과 `assets/illustrations/chaekgado/`(책가도 서재 전용, **다른
세션 소유 영역**)에 재사용 가능한 소품 4개(화병·그릇·필통·두루마리)가 이미 존재함을 발견했다. 이후
Jin이 3장의 참고 이미지(옅은 색조 화병/술병 하나, 워터컬러 스타일의 자개함, 워터컬러 스타일의
보석함)를 보냈고 **"이 컨셉이 우리 화풍과 맞는지 확인하고, 안 맞으면 신규 제작 목록에 추가하라"**고
요청했다. 이어서 Jin이 세션을 마치겠다며(맥이 느려 Windows로 전환) 인수인계 문서 작성 + 커밋·푸시를
요청했고, `session-handoff` 스킬로 이 문서 초안을 썼다 — **그때는 이미지를 프롬프트 안에서만 보고
파일로 저장하지 않아 스타일 대조가 "판정 애매"로 미완인 채 초안을 마감했다.**

**자기 검증(같은 세션, 초안 직후)**: Jin이 "인수인계가 정확한지, 얼마나 확신하냐"고 재차 물어서
직접 재검증했다. 그 결과 `~/Downloads/`에 원본 3장(`백자술병.png`·`자개함.png`·`보석함.png`)이
실제로 남아 있는 걸 찾아 `docs/assets/reference_images/`로 복사해 저장소에 편입하고,
`tool/check_style_conformance.py`로 F-A 게이트 대비 **실측**까지 마쳤다 — 상세 결론은 아래
"Immediate Next Steps" #1. 이 발견 자체가 중요한 교훈이다: **핸드오프 문서에 이미지를 "본 것"을
프롬프트 대화 안에서만 두면 안 되고, 반드시 저장소 안의 파일로 만들어야 다른 머신(이번엔 Windows)
에서도 이어받을 수 있다** — 아래 "Related Resources"의 `docs/assets/reference_images/` 항목 참고.

## Codebase Understanding

## Architecture Overview

**두 개의 병렬 한옥 진행 시스템** (이번 세션 전체의 배경):
- **레거시(라이브)**: `PersonalHanokProjection`/`hanok_stage_service.dart` — 평생 시각 변화 7번뿐,
  C1/C2를 구조적으로 표현 못 함. 지금도 유저가 보는 화면은 전부 이 시스템이다.
- **설계된(dark)**: `HanokExperienceProjector`/`HanokGrantCatalog`(86개 grant) — 코드 완성, UI 호출자
  0개, `publishedGrants: []`. 이번 세션은 이 시스템의 데이터/자동화 절반만 진전시켰다 — **cutover
  (PR-E)는 하지 않았다.** 즉 지금도 유저가 보는 건 여전히 레거시다.

**스타일 계열(family) 4개** — `docs/assets/STYLE_LOCK.json`이 정본, 이번 세션에 신설:
- F-A: 사랑방 실내(18종, 원본 6 + A2가구 12) — `assets/illustrations/decorations/`
- F-B: 마당/절기 legacy(18종) — 같은 디렉터리, `members`로 구분(디렉터리 공유라 접두어 추론 불가)
- F-C-estate: 개인 한옥 지도 건물/조경(21개) — `map/structures/`+`map/landscape/`+`map/stages/`
- F-C-a1states: A1 16단계(결정론 합성, 사람이 안 그림)

**세 번째, 별도의 소품 계열이 방금 발견됐다**: `assets/illustrations/chaekgado/`(8개) — 책가도 서재
기능 전용, **다른 세션 소유**(session-owned territory, 손대지 말 것 원칙이 이번 세션 초반부터 계속
적용됨). 이 중 4개는 재사용 가능한 독립 소품(vase·bowl·brushpot·scroll), 4개는 서가 조립용
구조/텍스처 재료(pillar·plank·dancheong_band·rod). STYLE_LOCK.json에는 **아직 등록 안 됐다** —
family 5개(F-A/B/C-estate/C-a1states + 이 chaekgado 소품군)로 갈지, F-A에 편입할지는 미정.

**환경 위험**: 이 프로젝트는 **여러 Claude 세션이 같은 물리 작업 디렉터리를 공유**한다. 한 세션이
`git checkout`하면 다른 모든 세션의 체크아웃도 말없이 따라 바뀐다. 이번 세션 중 최소 4번 발생했다
(main으로, `feat/hoeren-shelf-...`로, 다시 main으로, 그리고 이 handoff를 쓰는 도중에도 한 번 더).
매번 데이터 손실 없이 복구했지만(git reflog로 정확한 커밋 확인 후 `git branch -f`), **다음 세션도
매 커밋 직전에 반드시 `git rev-parse --abbrev-ref HEAD`로 브랜치를 재확인해야 한다.**

## Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `~/.claude/plans/swift-yawning-squirrel.md` | "살아 있는 한옥" 계획 정본(PR-A~F, Phase 0~3) | 이번 세션 전반부 전체가 이 계획 실행 |
| `docs/assets/STYLE_LOCK.json` | 스타일 정본(신설) — family 4개 실측 게이트·팔레트·프롬프트 골격 | 소품 감사의 "우리 화풍" 판단 기준. chaekgado 소품군 미등록 |
| `tool/style_lock.py`, `tool/check_style_conformance.py` | STYLE_LOCK.json 리더 + family별 게이트 | 신규 이미지 승인 전 이걸로 자동 검증 |
| `tool/asset_recipe.py` | 레시피 러너(`--check\|--plan\|--emit-work-order\|--ingest`) | 신규 소품 만들 때 이 도구로 레시피 작성 → 작업지시서 생성 |
| `docs/assets/recipes/*.json` | 실제 레시피 6개(건물 4 + 신규건물 2 DRAFT) | 새 소품 레시피도 이 디렉터리에 같은 패턴으로 추가 |
| `lib/widgets/sori/placed_decoration.dart` | `kDecorCategory`·`kDecorScale`·`decorName()`·`kAvailableDecorations`·`kRoomFurnishingPool` | 신규 소품 슬러그 등록 지점(6곳 중 4곳) |
| `assets/illustrations/chaekgado/` | 책가도 서재 소품 8개(4 재사용가능+4 구조재) | **다른 세션 소유** — 파일 자체를 편집하지 말 것, 참조 등록만 고려 |
| `docs/assets/reference_images/ref_baekja_jubyeong.png` | Jin이 준 백자술병 참고(원본: `~/Downloads/백자술병.png`) | F-A 게이트 실패(satMean 0.088/valMean 0.915) but 기법은 일치 — 재생성 또는 팔레트 보정 후보 |
| `docs/assets/reference_images/ref_jagaeham.png`, `ref_boseokham.png` | Jin이 준 함/궤 참고(원본: `~/Downloads/자개함.png`·`보석함.png`) | 워터컬러 렌더링, F-A 게이트 실패 — 레퍼런스로 못 씀, 개념만 가져와 새로 생성 |
| `docs/SESSION_LOG.md` | append-only 세션 로그(최상단이 최신) | 매 변경마다 기록 필수(AGENTS.md 규칙) — 이번 세션은 3개 항목 남김 |
| `AGENTS.md:277` 부근 "현재 진행 중인 작업" | 프로젝트 상태 체크리스트 | 이번 세션 항목 추가함, 완료 시 갱신 필요 |

### Key Patterns Discovered

- **`git commit -m "$(cat <<'EOF' ... EOF)"` 헤레독 패턴이 세션 후반부에 갑자기 깨졌다**(원인 불명,
  이전엔 여러 번 성공). 일반 멀티라인 `-m "..."` 문자열로 우회해 해결 — 다음 세션에서 헤레독이 또
  깨지면 이 우회법을 바로 쓸 것.
- **`docs/SESSION_LOG.md`는 append-only라 여러 세션이 동시에 맨 위에 항목을 추가하면 병합 충돌이
  거의 항상 난다** — 해결법은 항상 "양쪽 다 유지, 마커만 제거"(내용 손실 없이).
  단, git의 'ort' 전략이 가끔 이걸 충돌 없이 자동 처리하기도 한다(케이스별로 다름).
- **파일명만으로 자산을 판단하면 틀린다** — `assets/illustrations/hanok/calligraphy.png`·
  `achievements.png`는 이름과 달리 사랑방 소품이 아니라 완전히 다른 화면의 배너 일러스트였다.
  반드시 `Read` 도구로 이미지 자체를 열어 확인할 것.
- **`check_decoration_cutouts.py`/`check_style_conformance.py`의 "green rim" 휴리스틱은 진짜
  초록색 콘텐츠(연못·소나무 등)를 despill 실패로 오판한다** — F-B·F-C-estate는 이미 이 체크에서
  면제돼 있다(`GREEN_RIM_EXEMPT_FAMILIES`). 신규 소품이 초록 계열(예: 청자)이면 이 함정을 기억할 것.

## Work Completed

### Tasks Finished

- [x] **PR-B 마무리**: 원장 소급 기록 24cr(한옥) — 나중에 발견: 장식 스코프는 계획서의 "44cr" 추정이
      틀렸고 실제로는 93cr(65 기록 + 28 폐기)이라 `docs/assets/A2_FURNISHING_LEDGER.json` 신설해
      정확한 수치로 기록. 크레딧 상한 200→600.
- [x] **PR-C(데이터 절반)**: `canDoSegmentEvidenceProgress()` 등 알파 램프 진행도 계산 로직. **실제
      렌더 필터 변경(라이브 위젯)은 의도적으로 PR-E로 미룸** — 골든 테스트 있는 라이브 컴포넌트라
      실기기 검수 없이 건드리면 안 된다고 판단.
- [x] **PR-D**: 방별 가구 풀(`kRoomFurnishingPool`). **실버그 수정**: A2 가구 12종이 모든 방(안방·
      대청마루 포함) 피커에 노출되던 것 — 회귀 테스트로 정확한 시나리오 검증.
- [x] **Phase 2-1**: `docs/assets/STYLE_LOCK.json`(family 4개 전량 실측) + `tool/style_lock.py`.
- [x] **Phase 2-2**: `tool/check_style_conformance.py` — ShippedBaselineTest(73/73) + 합성 드리프트
      테스트. 보정 중 green-rim 오판 문제 발견·수정(위 "Key Patterns" 참고).
- [x] **Phase 2-3**: `tool/ledger_append.py`(--validate가 기존 27레코드 전량 통과) +
      `tool/asset_recipe.py`(레시피 러너, cutout 경로는 합성 이미지로 end-to-end 검증) + 기존 4개
      건물 프롬프트를 레시피로 이관(해시가 실제 역사 기록과 정확히 일치함을 테스트로 증명).
- [x] **Phase 2-4(일부)**: `decoration_transparency_test.dart`의 하드코딩 17개 목록을
      `kAvailableDecorations`(36개) 순회로 교체 — 등록 자동화 러너는 미착수.
- [x] main 병합 + 푸시(`fe7f04dd`) — 다른 세션의 batch14/15 콘텐츠 작업과 2회 재병합, 매번
      전체 스위트 재검증(4018/4018).
- [x] **사랑방 소품 1차 감사**: `assets/illustrations/decorations/`(36개) + `chaekgado/`(8개, 4개
      재사용가능) + `hanok/`(15개, 소품 아님 확인) + `personal_hanok_v2/interiors/`(2개, 배경뿐)
      전수 확인. Jin에게 결과 보고 완료.
- [x] **3장 참고 이미지 스타일 대조**: 실측 완료(satMean/valMean, `tool/check_style_conformance.py`)
      — 셋 다 F-A 게이트 실패, 백자술병은 기법 일치/팔레트만 안 맞음, 자개함·보석함은 기법 자체가
      워터컬러라 안 맞음. **최종 제작 방향은 여전히 Jin 결정 대기** — 아래 "Immediate Next Steps" 참고.

## Files Modified

전체 diff는 `git log 3a2d8a6f..fe7f04dd`(main 히스토리) 참고. 요약(52개 파일, +4779/-153줄, 7개
hanok 커밋):

| File | Changes | Rationale |
|------|---------|-----------|
| `docs/assets/HANOK_V1_ASSET_PROVENANCE.json` | 생성 레코드 18건 추가, budgetCredits 200→600 | 원장 소급 기록 |
| `docs/assets/A2_FURNISHING_LEDGER.json` | 신설, 93cr 기록 | 장식 스코프 별도 원장(hanok_v1_assets_only 스코프와 다름) |
| `lib/services/productive_assessment_service.dart` | `canDoSegmentEvidenceProgress()` 신설 | PR-C 알파 램프 진행도 |
| `lib/models/hanok_growth.dart` | `nextGrantProgress` 필드 | PR-C |
| `lib/data/personal_hanok_catalog.dart` | `PersonalHanokMapLayer`에 buildingId/stageIndex/grantId 추가(전부 null 유지) | PR-C, 아직 어떤 렌더러도 안 씀 |
| `lib/widgets/sori/placed_decoration.dart` | `kRoomFurnishingPool` 신설, `furnishedDecorSlugs()` 시그니처 변경 | PR-D 버그 수정 |
| `docs/assets/STYLE_LOCK.json` | 신설(대형 파일) | Phase 2-1 |
| `tool/style_lock.py`, `check_style_conformance.py`, `ledger_append.py`, `asset_recipe.py` + 각 test | 신설 | Phase 2-1~2-3 |
| `docs/assets/recipes/*.json` | 신설 6개 | 기존 건물 4개 프롬프트 이관 + Phase 3 신규건물 2개 DRAFT |
| `test/decoration_transparency_test.dart` | 하드코딩 목록 → kAvailableDecorations 순회 | Phase 2-4 구멍 폐쇄 |
| `skills-lock.json`, `.agents/skills/session-handoff/`, `.claude/skills/session-handoff` | session-handoff 스킬 설치 | 이 handoff 작성용 |
| `.claude/handoffs/2026-08-18-*.md` | 이 문서 | 세션 종료 인수인계 |

## Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| PR-E(cutover)·PR-F(레벨별 발행)·Phase 3 실제 생성 전부 착수 안 함 | (a) 전부 실행 (b) 코드만 준비하고 미배선 (c) 완전 보류 | (c) 선택 — grant 발행은 계획서 자체가 "영구 고정"이라 명시한 지점이고, cutover는 라이브 유저 화면 실배선이라 Jin의 실기기 검수 없이 진행 불가. Phase 3는 "1장 생성→승인→배치" 규칙(어겨서 28cr 태운 전례 있음) 때문에 Jin 부재 중 생성 자체를 안 함 |
| 별당·서고 레시피 2개는 DRAFT로 작성만 하고 미실행 | (a) 지금 생성 (b) 레시피만 준비 | (b) — 프롬프트·배치 좌표·subjectGuards 다 채워서 Jin이 검토만 하면 바로 돌릴 수 있는 상태로 대기 |
| green-rim 게이트에서 F-B·F-C-estate 면제 | (a) 임계값만 완화 (b) 완전 면제 + 근거 기록 | (b) — F-B 최대 69.8%(연못)까지 나와서 임계값 완화로는 해결 불가, 애초에 그 family엔 안 맞는 측정 |
| chaekgado/ 소품 재사용은 제안만 하고 실행 안 함 | (a) 바로 등록 (b) 발견만 보고, 승인 대기 | (b) — 다른 세션 소유 영역 파일을 다른 시스템에 걸치는 건 그 세션과의 소유권 경계 문제라 Jin 확인 필요 |
| main 병합·푸시 실행 | (a) 계속 보류 (b) Jin 지시대로 즉시 실행 | (b) — Jin이 명시적으로 "커밋푸쉬, 메인으로 병합" 지시(고위험 작업의 명시적 승인 요건 충족) |

## Pending Work

## Immediate Next Steps

1. ~~Jin이 보낸 3장의 참고 이미지 스타일 대조를 마무리한다.~~ **완료(2026-08-18 밤, 같은 세션 내
   후속 정정).** 최초 작성 때는 이미지를 프롬프트 안에서만 보고 파일로 저장하지 않아서 판정이
   "애매"로 남았었다 — Jin이 "확신하냐"고 재차 묻자 재검증했고, `~/Downloads/`에 원본 3장이
   실제로 남아 있는 걸 찾아 `docs/assets/reference_images/`로 복사해 저장소에 편입했다(그래야
   Windows로 옮겨도 접근 가능). `tool/check_style_conformance.py`로 F-A 게이트 대비 **실측**했다:
   - `docs/assets/reference_images/ref_baekja_jubyeong.png`(백자 술병/주병, 옅은 크림·민트톤
     faceted moon jar) — **satMean 0.088**(범위 [0.30,0.80] 미달) / **valMean 0.915**(범위
     [0.25,0.65] 초과) → **게이트 실패, but 구조는 일치**. 면분할·아웃라인 없음·hanji grain·매트
     마감은 우리 스타일 그대로다 — 다만 팔레트가 백자 특성상 우리 F-A 호두목 팔레트보다 훨씬 옅고
     채도가 낮다. **결론**: 이 파일을 그대로 쓰지 말고, 같은 구도/기법으로 팔레트만 F-A 톤(또는
     청자 계열이면 별도 하위 팔레트)에 맞춰 재생성하거나, F-A 게이트에 "백자/청자류"용 별도
     팔레트 예외를 추가할지 Jin과 정할 것.
   - `docs/assets/reference_images/ref_jagaeham.png`(자개함, 검은 옻칠+자개 상감 작은 함,
     걸쇠 있음) — **satMean 0.154**(미달) + **워터컬러/사실적 렌더링**(광택·그라데이션 음영·
     세밀한 붓터치) — 색상·기법 둘 다 실패.
   - `docs/assets/reference_images/ref_boseokham.png`(보석함, 자개 상감 2서랍 낮은 콘솔/문갑형) —
     **satMean 0.204**(미달) + 워터컬러 — 마찬가지로 색상·기법 둘 다 실패.
   **최종 결론**: 자개함·보석함(함/궤 컨셉)은 레퍼런스 이미지 자체를 쓰지 말고 F-A 프롬프트 골격으로
   처음부터 새로 생성해야 한다. 백자술병은 구조/기법은 맞지만 팔레트 재작업이 필요 — "그대로 채택"은
   아니고 "재생성 또는 게이트 예외 논의" 둘 중 하나다. **다음 세션의 첫 실제 액션은 이 셋 중 어느
   경로로 갈지 Jin과 정하는 것** — 새로 생성할지, 백자술병만 팔레트 보정해서 살릴지.
2. **Jin과 신규 소품 우선순위를 확정한다.** 후보: **주병은 위에서 처리 완료**(재생성 or 팔레트 보정
   대상으로 확정), 나머지 — 경대(거울)·약장·함/궤(자개함·보석함 레퍼런스 활용, 위 참고)·연상·
   장목비·망건통·병풍 디자인 변형(묵포도도). 담배 소품 세트는 문화적/연령 적절성 판단을 Jin에게
   별도로 물어야 한다(임의 결정 금지).
3. **chaekgado/ 소품 4개(vase·bowl·brushpot·scroll) 재사용 여부를 Jin에게 확인**한다 — 승인되면
   `kAvailableDecorations`/`kDecorCategory`/`kRoomFurnishingPool`에 등록(파일 자체는 건드리지 않음,
   참조만 추가). STYLE_LOCK.json에 family로 편입할지(F-A 흡수 vs 신규 F-D)도 같이 정할 것.
4. (우선순위 낮음, Jin이 승인하는 시점에) 확정된 신규 소품마다 `docs/assets/recipes/`에 `cutout`
   레시피 작성 → `tool/asset_recipe.py RECIPE --check` → `--emit-work-order` → 실제 생성(Jin
   1장씩 승인) → `--ingest`.
5. (더 미룰 수 있음) PR-E/PR-F/Phase 3 — Jin이 실기기(이제 Windows) 검수 가능해지면 재개.

### Blockers/Open Questions

- [x] ~~3장 참고 이미지의 화병(a)이 정확히 어떤 것과 대조해야 "일치"로 볼지~~ 해결됨 — 위 "Immediate
      Next Steps" #1 참고, 실측 완료(satMean 0.088/valMean 0.915, F-A 게이트 실패, 구조는 일치).
- [ ] 백자술병(`ref_baekja_jubyeong.png`)을 재생성할지 팔레트만 보정해서 살릴지 — Jin 결정 필요.
- [ ] 담배 소품 세트(담뱃대·재떨이·담배합) — 학습 앱에 적절한지 Jin 판단 필요, 임의 진행 금지.
- [ ] chaekgado/ 소품 재사용이 그 폴더를 소유한 다른 세션과 충돌하는지 — 파일을 안 건드려도 "같은
      파일을 두 시스템이 참조"하는 게 그 세션 입장에서 문제가 될지는 불확실, Jin이 조율 필요.
- [ ] main이 이 세션 도중에도 계속 움직여서(batch14/15/16 + golden baseline fix) 이 브랜치
      (`chore/hanok-pr-e-prep`)가 main보다 몇 커밋 뒤처져 있다 — 다음 세션 시작 시 `git fetch`로
      최신 상태부터 확인할 것.

### Deferred Items

- **PR-E(cutover)**: grant 발행 + `hanok_world_screen.dart` 실배선. 계획서가 "영구 고정 지점"이라
  명시 + 실기기 검수 필요라 미룸.
- **PR-F(레벨별 발행)**: PR-E 종속이라 자동 연기.
- **Phase 3 실제 생성**(별당·서고): "1장 승인 후 배치" 규칙 + Jin 부재로 미룸. 레시피는 DRAFT로 준비됨.
- **Phase 2-3 `asset_recipe.py --ingest`의 sheet/frameEdit/overlay/newBuilding 경로**: 실제 생성
  결과물이 없어 검증 못 함, cutout만 자동화. 다음에 진짜 생성 결과가 생기면 마저 구현할 것.
- **Phase 2-4 등록 자동화 러너**(6개 등록 지점 패치 블록 생성): 새 자산이 실제로 생길 때까지 미룸.

## Context for Resuming Agent

## Important Context

- **main은 이미 안전하다** — 이번 세션의 hanok 작업 전부가 병합·푸시·전체 테스트 검증까지 끝났다
  (`fe7f04dd`). 다음 세션이 급하게 뭔가를 다시 병합할 필요는 없다.
- **지금부터는 반드시 별도 브랜치에서 작업한다** — Jin이 명시적으로 "이제부터 다른 브랜치 써줘"라고
  지시했다. main에서 직접 커밋하지 말 것. 이 handoff 자체도 `chore/hanok-pr-e-prep`(main 기준
  빈 브랜치)에 커밋된다.
- **공유 작업 디렉터리 위험**: 매 커밋 직전에 `git rev-parse --abbrev-ref HEAD`로 브랜치를 재확인할
  것 — 이번 세션에 최소 4번 다른 세션이 브랜치를 바꿔놨다. 데이터 손실은 없었지만(커밋은 안 사라짐,
  브랜치 포인터만 옮겨감) 잘못된 브랜치에 커밋하면 다시 옮겨야 하는 수고가 든다.
- **크레딧 잔액**: 세션 중반 596.2cr 확인(다른 세션과 공유되는 계정이라 정확한 소비 추적은 원장
  기록에 의존할 것, check_credits 스냅샷은 참고용일 뿐).
- **BBANANA 자산 생성 규칙**(전부 `docs/assets/STYLE_LOCK.json` `generationFacts`에 기록됨):
  참조 이미지 정확히 1장만, resolution 명시 필수(기본값 1K로 조용히 떨어짐), aspect_ratio 지정해도
  edit_image 출력은 항상 2400x1792로 돌아옴(정렬은 출력 자체 알파 bbox로), LANCZOS 리스케일이
  저알파 림에 청록 기미를 되살림(재디스필 필요).

## Assumptions Made

- Jin이 보낸 3장의 참고 이미지가 **우리 앱에 넣을 컨셉 후보**라고 가정했다(단순 스타일 무드보드가
  아니라) — `~/Downloads/자개함.png`·`백자술병.png`·`보석함.png`라는 파일명 자체가 "이 물건을
  우리 앱에 넣고 싶다"는 의도를 뒷받침해 이 가정은 근거가 꽤 탄탄해졌다. 다만 "이 이미지를 그대로
  쓰고 싶다"인지 "이 물건을 우리 화풍으로 다시 그려달라"인지는 여전히 Jin 확인이 필요 —
  이번 정정에서 실측(satMean/valMean)으로 세 파일 다 F-A 게이트를 통과 못 한다는 것까지는
  밝혔으니, 최소한 "그대로 등록"은 아니라는 것만은 확실하다.
- chaekgado/ 소품 재사용 제안이 그 폴더를 소유한 세션의 작업과 물리적으로 충돌하지 않는다고 가정
  (파일 자체를 편집하지 않고 다른 카탈로그에서 "참조"만 추가하는 것이므로) — 이 가정은 검증 안 됨.

## Potential Gotchas

- `docs/HANOK_ASSET_INVENTORY_2026-08-17.md`는 **F-A 6종(원본)만 실측한 스냅샷**이다 —
  STYLE_LOCK.json이 4 family 전체를 실측한 정본이니 그쪽을 우선할 것(이미 배너로 문서화됨).
- `check_style_conformance.py`의 paletteDistance는 **경고 전용**이다(실패로 못 씀, 아직 선례 없음) —
  스타일 대조 판단에 이 숫자 하나만으로 합격/불합격을 가르면 안 된다.
- `asset_recipe.py`의 `newBuilding` kind는 계획 원안에 없던 **이번 세션의 신규 확장**이다 — 별당·
  서고처럼 "편집할 기존 완성 이미지가 없는" 경우에만 쓸 것, 일반 소품(cutout)엔 안 맞는다.
- 헤레독(`<<'EOF'`) 기반 `git commit -m "$(cat <<'EOF' ...)"` 패턴이 세션 후반에 알 수 없는 이유로
  깨졌다 — 재현되면 일반 멀티라인 `-m "..."` 문자열로 즉시 우회할 것(디버깅에 시간 쓰지 말 것).

## Environment State

### Tools/Services Used

- `/usr/local/bin/python3.12` — 이 프로젝트의 Pillow/numpy 작업용 고정 인터프리터(`python3` 기본은
  3.14.6이라 다를 수 있음, 반드시 3.12 절대경로 사용).
- BBANANA MCP(`mcp__ad5dcbd9-...`) — 이미지 생성/편집. 이번 세션엔 새 생성 호출 안 함(Jin 부재로
  전부 보류), 크레딧 확인만 함.
- `gh` CLI — CI 상태 확인용(`gh run list --branch main`).
- `npx skills` — 이번 handoff 작성에 `softaworks/agent-toolkit@session-handoff`(4K 설치) 스킬 설치.

### Active Processes

- 없음 — 이 세션이 시작한 백그라운드 프로세스(전체 flutter test 스위트 등)는 전부 완료 후 종료됨.
  다음 세션 시작 시 새로 실행해야 한다.

### Environment Variables

- 특별히 설정한 것 없음.

## Related Resources

- `~/.claude/plans/swift-yawning-squirrel.md` — 살아 있는 한옥 계획 정본
- `docs/SESSION_LOG.md` 최상단 3개 항목 — 이번 세션 상세 기록(2026-08-18, "Phase 2-3 완성 후속" +
  "원장 소급 기록 + PR-C/D + Phase 2 자동화 착수" 두 항목)
- `AGENTS.md` "현재 진행 중인 작업" 섹션 — 살아 있는 한옥 체크리스트 항목 추가됨
- `docs/assets/STYLE_LOCK.json` — 스타일 정본
- `docs/assets/recipes/` — 레시피 6개(신규 소품도 같은 패턴으로 추가할 것)
- `docs/assets/reference_images/` — Jin이 준 참고 이미지 3장(실측 완료, 위 "Critical Files" 참고).
  **이 폴더는 이번 세션에서 신설했다** — 앞으로 Jin이 참고 이미지를 주면 프롬프트 안에서만 보고
  끝내지 말고 항상 여기 저장해서 커밋할 것(머신을 옮기면 접근이 끊긴다).

---

**Security Reminder**: Before finalizing, run `validate_handoff.py` to check for accidental secret exposure.
