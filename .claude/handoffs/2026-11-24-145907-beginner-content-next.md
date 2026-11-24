# Handoff: 입문자 첫걸음 재구성 — 다음 입문 콘텐츠 작업 (2026-11-24)

## Session Metadata
- Created: 2026-11-24 14:59:07
- Project: ko_lernen_app (작업은 `C:\dev\hangulsori\wt\*` 워크트리, 기준 `origin/main 5dad75fc`)
- Branch: claude/handoff-beginner-content (이 문서만 담은 브랜치)
- Session duration: 약 2일(2026-11-23~24)

### Recent Commits (for context)
  - 5dad75fc8 content(a1): 첫 인사 예문을 자연스럽게, 번역은 온전하게 (입문자 PR-5) (#493)
  - b05974c37 docs(textbook): recover 1A authoring package and local grammar revisions (#485)
  - 4e70d5fd7 feat(hangul-start): 입문 트랙 콘텐츠 데이터·검증 로더·TTS 점검 (입문자 PR-3 데이터) (#492)
  - b53360ec0 feat(hangul): approved atelier layout that fits one screen on every phone (#490)
  - bd2b9a091 fix(phase): count step completion only from passed or unjudged attempts (#491)

## Handoff Chain

- **Continues from**: [2026-09-09-141500-lcp-pr-l3a-batch23-24-merge.md](./2026-09-09-141500-lcp-pr-l3a-batch23-24-merge.md) (레벨 정본화 — 직접 이어지는 작업은 아님, 스크립트가 자동 연결)
- **Supersedes**: None

## Current State Summary

입문자들이 "앱이 너무 어렵다"고 해서 세종학당 교재(입문~6B, 188개 단원)와 앱을 대조하고 설계안을 만든 뒤 Jin이 D1~D4를 승인했다. 지금까지 다섯 PR이 main에 들어갔다: #488 과제 화면 로마자·예문 듣기, #489 KP01 4단계(steps), #491 단계 완료 판정 수정, #492 입문 14수업·한글 확인(Kurztest) **데이터와 검증 로더**(화면 없음), #493 첫 인사 예문 자연화. **화면 작업은 아직 0** — Codex가 목업을 만들어 Figma에 연결하는 중이고 Jin 승인 전에는 화면을 만들지 않는다. 배포는 Codex가 하고 있으니 이 작업 흐름에서는 배포하지 않는다.

## Codebase Understanding

## Architecture Overview

- 입문 트랙 정본은 `assets/data/hangul_foundation.json`(4부분·14수업 F01~F14·Kurztest 10문항, passAt 8, maxPlays 2). 로마자는 저장하지 않고 화면에서 `romanizeKorean()`로 만든다.
- `lib/services/hangul_foundation_catalog.dart`가 로드할 때 교수 계약을 강제한다: 배운 초성·모음·받침만 사용, 현대 자모 40개를 정확히 한 번 도입, 오디오는 완성 음절만(자모 단독은 TTS가 '기역'처럼 이름으로 읽음), 같은 소리 선택지 금지(`foundationSoundKey`: ㅐ=ㅔ, ㅒ=ㅖ, ㅙ=ㅞ=ㅚ, 받침 대표음), 수업당 확인 3문항, ko/de/en 필수. 테스트 `test/hangul_foundation_catalog_test.dart`(14개).
- TTS는 `sha1("{voice}|{text}")`로 Storage(`tts/v3/...`)를 찾고, 기본 'auto' 음성은 `TtsVoicePolicy.resolve`가 문장별로 남/여를 정한다. **입문 화면은 반드시 voice 'auto'로 재생**해야 기존 음성을 재사용한다.
- 학습 단계: `assets/data/learning_phases.json`의 phase에 `steps`(KP01만) — 편집 원본 `tools/content_factory/cefr_matrix/phase_steps.json`, 생성 `tool/build_learning_phase_catalog.py --check`. 단계 완료는 `lib/widgets/phase_task_panel.dart`의 `phaseTaskDone`(평가 통과 또는 score==null 제출, 전체 시도 기준). 잠금 없음.

## Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `assets/data/hangul_foundation.json` | 입문 14수업·Kurztest 정본 | 화면 구현 시 유일한 콘텐츠 원천 |
| `lib/services/hangul_foundation_catalog.dart` | 로더·계약 검증 | 화면이 `HangulFoundationCatalog.load()`로 읽는다 |
| `tool/audit_hangul_foundation_tts.py` | 입문 음성 Storage 점검 | 현재 137개 중 63개 미합성 |
| `lib/features/onboarding_v2/onboarding_learning_start.dart` | `shouldOfferHangul`(한글 권유 1회성) | PR-4에서 '한글 확인 통과 전까지 유지'로 변경 |
| `lib/widgets/sori/today_learning_card.dart` | Heute의 한글 진입(`HangulIntroPick`) | 새 카드 만들지 말고 이 카드 상태 확장 |
| `lib/screens/phase_task_screen.dart` | 과제 화면(로마자 토글·예문 듣기) | 이미 구현, C 스타일 재입힘 대상 |
| `C:/dev/hangulsori/_codex_artifacts/hangul-start-mockups-20261124/CODEX_PROMPT.md` | Codex 목업·Figma 프롬프트 | 화면 S1~S5 정의, 승인 산출물이 여기로 온다 |
| `docs/learning/lernpfad-v2/curriculum/FOUNDATION.psv` | 옛 입문 28수업 설계 | 콘텐츠 명세 참고(런타임 아님) |

### Key Patterns Discovered

- 화면 작업은 **이미지 목업 → Jin 승인 → 편집 가능한 Figma → Flutter** 순서(`docs/design/IMAGE_FIRST_DESIGN_APPROVAL_20261104.md`). 승인 C 스타일: 녹청 상단 띠+금색 "HANGUL SORI", 한지 바탕, 화면당 금색 주 버튼 하나, 청자 자모 오브제, 청동 징 듣기 소품. 글꼴: DE Belgrano+Encode Sans Condensed, EN Chubbo+Supreme, 한글 Noto Sans KR(`SoriLocaleFonts`).
- 캐스트 이름 규칙: 교재 이름(민수·철수·영희·안나, 010-1234-5678) 금지(`test/learner_copy_scan_test.dart`). 남자 NPC=현우(Hyunwoo), 학습자=레나(Lena).

## Work Completed

### Tasks Finished

- [x] 세종 교재 188단원 ↔ 앱 대조표: https://claude.ai/artifact/FcNwxgGMW9PJCK31jj2NBd
- [x] 설계안(D1~D4 승인): https://claude.ai/artifact/LdRwqZqKrf3SZD845Jc5p1
- [x] #488 로마자·예문 듣기, #489 KP01 steps, #491 단계 완료 판정
- [x] #492 입문 데이터·로더·TTS 점검 도구, #493 첫 인사 예문 8개(+satz 5·cloze 3) 자연화·TTS 업로드
- [x] Codex 목업 프롬프트 작성

## Files Modified

| File | Changes | Rationale |
|------|---------|-----------|
| `.claude/handoffs/2026-11-24-145907-beginner-content-next.md` | 인수인계(이 브랜치의 유일한 변경) | 다음 세션 이어받기 |
| `assets/data/hangul_foundation.json` 외(#492) | 입문 데이터·로더·테스트·TTS 도구 | main 병합 완료 |
| `assets/data/korean_vocab.csv` 외(#493) | 첫 인사 예문·원장·커버리지 | main 병합 완료 |

## Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| D1 입문 트랙은 현재 main 위에 새로 | Lernpfad v2 런타임 포팅 / 새로 | v2 브랜치 225커밋 뒤처짐, 수업 1개뿐, 기기 전용 저장 |
| D2 권장 + Kurztest로 건너뛰기 | 필수 관문 / 권장만 | 이미 읽는 학습자를 막지 않음 |
| D3 로마자 입문~KP02 기본 켬 | 항상 끔 / A1 전체 | 로마자 의존 방지 |
| D4 KP01 steps(기존 task ID 유지) | 새 Phase ID | 학습자 기록 보존 |
| A1 1단원 확인 장면 `airport_arrival` 유지 | 교실 장면으로 교체 | 실제 4줄이 단원 목표와 맞고 교체 파급(can-do·한옥 보상)이 큼 |
| KP01 과제 예문 미수정 | "누구 것이에요"→"누구 거예요" 등 | 바꾸면 contentHash가 바뀌어 학습자 완료 기록 무효 |

## Pending Work

## Immediate Next Steps

1. **입문 TTS 63개 합성**(화면 없이 지금 가능): `hangul_foundation.json`을 캐노니컬 TTS 소스에 추가(`functions/tts/build_canonical_manifest.py` — CI "TTS function security"가 허용 목록을 검사하니 함께 갱신) → `PYTHONIOENCODING=utf-8 .venv\Scripts\python.exe tool/generate_tts.py --missing-from-storage --workers 8` → `--verify-storage` missing 0 확인 → `tool/audit_hangul_foundation_tts.py --check` 0.
2. **Codex 목업 승인 확인** 후 PR-3 화면: 새 화면 hangul_foundation_screen.dart(가르치기→조립→듣고 고르기→확인 3문항, voice 'auto', 입문은 로마자 표시) + 한글 지도(S2) + Kurztest(S4, 로마자·힌트 없음). 진행 저장 키 `kl_hangul_foundation_v1`(완료 수업 ID·Kurztest 점수·통과 시각).
3. **PR-4 진입 경로**: `shouldOfferHangul`을 'Kurztest 통과 전까지 유지'로, 온보딩에 "Ich kann Hangul schon lesen → Kurztest", `HangulIntroPick` 카드 3상태(0/14·진행 중·통과 후 사라짐). 기존 학습자는 자동으로 막지 않는다.
4. Analytics 이벤트 `hangul_foundation_lesson`·`hangul_check_passed`·`phase_step_completed` 추가.

### Blockers/Open Questions

- [ ] Codex 목업과 Figma 연결 승인 대기(화면 작업 전제).
- [ ] Play 공개 테스트가 기본 다운로드 727.7MB > 490MB 상한으로 막혀 있었음(11-03 이후 c_listening +122.6MB, approved_games +39.7, dokkaebi_intro +32.4, video/introductions +15.7, concept_c +11.2). 배포는 Codex 담당 — 입문 화면을 넣을 때 새 그림 에셋이 이 상한을 더 키우지 않게 할 것.
- [ ] iOS TestFlight는 맥 전용(CI 미지원, `docs/store/APPSTORE_UPLOAD_KO.md`).

### Deferred Items

- KP01 과제 문장 자연화(완료 기록 무효화 비용 때문에 Jin 결정 필요).
- 세종 대조에서 B1·B2 문법 앱 전무 16개(`-을 테니(까)`, `-지 그래(요)?`, `-게 하다/만들다`, `-고 말다`, `마저` 등) — 입문 범위 밖.
- A2 단원 보강(8개, 세종 2권 20과), C1·C2 단원 순서 정리 — 범위 밖.

## Context for Resuming Agent

## Important Context

- **콘텐츠 문장을 바꾸면 따라와야 하는 것**(이번에 CI가 세 번 막은 이유): ① `functions/tts/build_canonical_manifest.py`(두 사본) ② `tool/refresh_can_do_vocab_fingerprints.py` + `tools/content_factory/build_can_do_segments.py --check` ③ `tool/generate_tts.py --missing-from-storage` ④ `test/learner_copy_scan_test.dart`(교재 이름 금지) ⑤ 번역 쌍 R3(표제어가 예문에 붙어 있어야 함)·R4(DE/EN 단어 수 ≤ KO 어절×2.5) ⑥ Batch 승격 행이면 `tools/content_factory/review/promoted_copy_revisions_20260822.json` 원장 항목 + 해시 사슬 재고정(amendments_20261003 → followups_20261003 → followups_20261119) ⑦ `global_localization_coverage_20261006.json`의 ko/de/en 사본 동기화 → content_factory 전체 테스트 후 CI가 `git diff --exit-code`로 재생성 리포트를 비교.
- CI 콘텐츠 잡과 같은 로컬 검증: `.venv\Scripts\python.exe tools/content_factory/validate_content.py --json` 후 `python -B -m unittest discover -s tools/content_factory -p 'test_*.py' -t .`(약 10분, 리포트를 제자리에서 다시 씀).
- 원장 항목은 손으로 해시를 계산하지 말고 `validate_promoted_batch.validate()`가 비교하는 투영을 받아 쓰는 방식이 안전했다.

## Assumptions Made

- 입문 화면은 기존 부품(`lib/data/hangul_data.dart`, `lib/services/tts_recorded_jamo.dart`, `lib/services/hangul_composer.dart`, `lib/screens/quest_engines/batchim_drop_quest.dart`)을 재사용할 수 있다고 봤다(화면 구현 시 확인).
- Kurztest 문항 은행 10개는 초안 — 실제 TTS로 들어서 구별되는지 검수 필요.

## Potential Gotchas

- `C:\Users\vjinn\OneDrive\...` 사본은 git 손상 — 쓰지 말 것. `C:\dev\hangulsori\ko_lernen_app`의 공유 .git에서 워크트리를 만든다.
- 로컬 Flutter 기본(3.44.8)은 낮다. CI와 같은 `C:\dev\_tools\flutter-3.47.8\bin\flutter.bat` 사용.
- 새 워크트리는 gitignore된 폰트(Chubbo, Supreme 등 6개)를 기존 워크트리에서 복사해야 `flutter test`가 돈다.
- C: 여유 공간이 1~6GB로 매우 적다. 워크트리 하나가 수 GB라 새로 만들기 전에 공간 확인. 머지 끝난 `wt/kp01-steps`·`wt/phase-task-reading-aid` 정리는 Jin 확인 후(`.agents/skills/` 미추적 폴더가 있음).
- 같은 PR에서 learner_copy_scan을 먼저 로컬 실행하면 이름 위반을 미리 잡는다.

## Environment State

### Tools/Services Used

- gh(활성 계정 Sujin-Arin-DataWorld), gcloud(TTS 합성·업로드 계정은 `tool/generate_tts.py`가 지정), `.venv\Scripts\python.exe`, Flutter 3.47.8.

### Active Processes

- 없음(이 세션의 백그라운드 감시는 모두 종료).

### Environment Variables

- `PYTHONIOENCODING` (Windows 콘솔에서 TTS 도구 실행 시), GitHub 변수 `PLAY_INTERNAL_RELEASE_ENABLED`(false 유지).

## Related Resources

- 설계안: https://claude.ai/artifact/LdRwqZqKrf3SZD845Jc5p1 · 대조표: https://claude.ai/artifact/FcNwxgGMW9PJCK31jj2NBd
- PR: #488 #489 #491 #492 #493 (모두 main 병합)
- 메모리: `beginner-path-redesign-2026-11-23`, `content-edit-followup-checklist`, `tts-verify-missing-runbook`

---

**Security Reminder**: Before finalizing, run `validate_handoff.py` to check for accidental secret exposure.
