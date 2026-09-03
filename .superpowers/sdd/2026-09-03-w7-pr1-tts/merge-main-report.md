# origin/main (#253–#255) 머지 리포트

브랜치 `claude/w7-pr1-tts-20260903`, worktree
`C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr1-tts-20260903`.
Fable이 `git merge-tree` 산출물로 사전 설계한 해법(16개 충돌: 코드/CI 5 +
graphify-out 11)을 그대로 따랐고, 각 항목을 실제 병합 결과 파일로 재검증했다.

## 커밋

| SHA | 내용 |
|---|---|
| `9cf28881` | 머지 커밋 (충돌 해소 + STEP 6 코드 수정 대부분) |
| `c767a3f7` | 수정 커밋 — 머지 커밋에서 스테이징 누락된 파일 2개 반영 (아래 "예상 밖 이슈" 참고) |
| `3d1b5f95` | `chore(graphify)`: 머지 후 그래프 갱신 |

머지 전 HEAD: `5a561faa`. origin/main 병합 대상: `08b80c6e`(#255) ·
`e35ea785`(#254) · `d8760703`(#253).

## 파일별 해소 요약

### `.github/scripts/ci_scope.py`
- `SCOPES` 튜플: 두 쪽 모두 포함 — `app, website, book, gye, pronunciation,
  tts, auth_cleanup, ios, content`.
- `TASK_SCOPE`: `"ios": ("app","ios")`(main) + `"content": ("content",)`(ours)
  둘 다 유지.
- **SEMANTIC POINT 2 실제 수정**: 자동병합된 `scopes_for_paths()`가 main의
  새 `assets/data/` 일반 규칙(196번대, `continue` 포함)을 우리 content-shard
  규칙(원래 260번대)보다 앞에 둬서, content shard 경로가 일반 규칙에서
  먼저 매치·`continue`돼 버려 content 규칙이 죽은 코드가 되는 버그를
  확인했다. 수정: content-shard 규칙(시나리오 `scenarios_*.json` +
  `cloze.json`/`satz_sentences.json`/`smalltalk.json`/`silben_puzzles.json`/
  `korean_vocab.csv`/`grammar.csv`)을 일반 `assets/data/` 규칙보다 **앞으로
  이동**하고 `result["tts"] = True`를 추가해 `app+tts+content`를 내도록
  했다(파일: `ci_scope.py:119-152`). 일반 규칙(미등재 `assets/data/*`)은
  그대로 `app+tts`. 원래 260번대에 남아있던 (이제 도달 불가능한) 구
  content 규칙 블록은 제거했다. `functions/tts/**`는 그대로 `tts`만.

### `.github/scripts/test_ci_scope.py`
- 두 테스트 그룹 모두 유지.
- `test_content_shard_change_selects_app_and_content_gates` → 기대값을
  `app, tts, content`로 갱신(예전 `app, content`).
- `test_unlisted_assets_data_file_selects_app_only` →
  `test_unlisted_assets_data_file_selects_app_and_tts`로 개명, 기대값
  `app, tts`.
- `test_canonical_tts_inputs_also_verify_server_allowlist`(main) 루프를
  분리: `assets/data/scenarios_a1.json`은 별도 assert로
  `app, tts, content`(content shard이기도 하므로), 나머지
  (`tts_canonical_manifest.json`, `tool/generate_tts.py`,
  `tool/polish_tts.py`, `lib/data/hangul_data.dart`,
  `lib/services/placement_diagnostic.dart`)는 기존대로 `app, tts`.
- `python -m unittest discover -s .github/scripts -p "test_*.py"` → **64/64
  green**(test_ci_scope.py 단독 실행 시 20/20).

### `.github/workflows/ci.yml`
- `changes` job outputs: `ios`(main) + `content`(ours) 둘 다 유지.
- `tts-storage-verify`(ours) 잡과 `ios-native-build`/`ios-native-tests`(main)
  잡 모두 파일에 그대로 존재 확인.
- YAML 유효성: 캐노니컬 venv엔 pyyaml이 없어 스크래치패드 임시 venv를
  만들어(`.venv` 아님, 캐노니컬 venv엔 설치 안 함) `yaml.safe_load` 통과
  확인.

### `lib/services/tts_service.dart` (4개 충돌 블록, 모두 "양쪽 추가")
- (a) `TtsPlaybackEngine` 생성자: `onPlaybackFailed` + `onPlaybackStarted`
  둘 다 파라미터로 유지.
- (b) 필드: main의 `onPlaybackFailed`(주석 포함) + ours의
  `onPlaybackStarted`(문서 포함) 둘 다 유지.
- (c) 정적 엔진 배선: `onPlaybackFailed: (_) =>
  _reportUnavailable(...)` + `onPlaybackStarted: (text, voice) { ... }`
  둘 다 유지.
- (d) 메서드: main의 `_authenticatedUid`, `_resolvePrivateAudio`,
  `_invokePrivateCallable` + ours의 `setCacheDirForTesting`(문서,
  `@visibleForTesting` 포함) 모두 유지. **주의**: git의 라인 기반 diff가
  두 메서드의 서로 다른 닫는 `}`를 "같은 공통 컨텍스트 줄"로 오인해
  머지 마커 안에 닫는 중괄호가 하나만 남아있었다(양쪽 블록 중
  `setCacheDirForTesting`의 `}`가 빠져 있었음). 각 쪽의 pre-merge
  원본(`git show HEAD:...`/`git show origin/main:...`)을 대조해 두
  메서드에 각각 정확한 닫는 `}`를 복원했다. 복원 중 실수로 중괄호를
  중복 삽입했다가(`}\n  }`) 재검토로 발견·제거함 — 최종적으로
  `flutter analyze` 0 issues로 검증.
- `speak()` 본문 검증(SEMANTIC POINT — 위치 확인): 자동병합 결과가 이미
  올바른 순서였다 — `if (_disposed || generation != _generation) return
  false;` → `if (session == null) { onPlaybackFailed?.call(...); return
  false; }` → `onPlaybackStarted?.call(trimmed, normalizedVoice);` → `bool
  completed;`. 이동 불필요.
- `TtsAudio.bytes(...)` 존재 확인(933/988/1201행에서 사용 중), main이 추가한
  `privateSession`/`privateAudio` const 필드도 확인됨.

### `lib/widgets/sori/speakable.dart`
- `SoriSpeechIndicator.handleTap`: main의 `onTap` 오버라이드를 먼저,
  그다음 ours의 `phase != TtsSpeechPhase.idle` 분기 — 브리프가 요구한
  정확한 순서로 해소.
- `this.onTap` 생성자 파라미터·필드는 자동병합으로 이미 존재 확인.
- `git grep -n "\.speaking\b" -- lib test` / `"speaking\.value"` 전수 조사
  결과, **실제 마이그레이션이 필요했던 곳 2곳**(둘 다 main이 도입,
  `SoriSpeech.phase` 리팩터를 모르는 코드):
  - `lib/screens/pronunciation_studio_screen.dart:492` — `final stopping =
    SoriSpeech.speaking.value;` → `SoriSpeech.phase.value ==
    TtsSpeechPhase.speaking`으로 교체 + `import
    '../services/tts_service.dart';` 추가(492행 근처, `TtsSpeechPhase`
    가시성 확보).
  - `test/pronunciation_studio_screen_test.dart:52` — `expect(
    SoriSpeech.speaking.value, isTrue);` → `expect(SoriSpeech.phase.value,
    TtsSpeechPhase.resolving);`로 교체(+ 동일 import 추가). 의도 보존
    근거: `speakImpl`이 TtsService를 우회하는 스텁이라 실제 재생-시작
    신호가 없으므로, 우리 phase 모델에서 관찰 가능한 "재생 요청 중"
    상태는 `resolving`이다(기존 `test/speakable_semantics_test.dart`의
    동일 패턴과 일치, 137행 근방). 그 외
    `CurriculumLanguageDomain.speaking`/`SoriActivityColorRole.speaking`은
    무관한 별개의 enum이라 그대로 둠.

## SEMANTIC POINT 1 — 디스크 티어 테스트 (`test/tts_disk_tier_test.dart`)

main이 `_resolveAudio`(번들 1단과 디스크 2단 사이)에 새로 추가한
`TtsCanonicalManifest.contains` 게이트(`lib/services/tts_service.dart:941`)
때문에, 기존 텍스트 `'디스크 히트 테스트'`는 canonical manifest에 없어
`allowSynthesis:false`(테스트 기본값)일 때 디스크 티어에 도달하기도 전에
`null`을 반환한다.

- `assets/data/tts_canonical_manifest.json`(voice/sha1(voice|text) 40자 hex
  집합)과 `assets/data/tts_first_line_manifest.json`(126개 시나리오의 첫
  대사만, 번들 대상)을 대조해 `grammar.csv` 예문 중 canonical이면서 번들
  대상이 아닌 문구를 찾았다 — `'먹지 않아요.'` (해시 검증을 first-line
  manifest의 `cacheHashSha1`과 대조해 해시 알고리즘 일치 확인 완료, 후보
  113개 중 첫 항목 채택).
- 텍스트를 `text = '먹지 않아요.'`로 교체.
- 기존 `bundledAssetPath == null` 전제 옆에 새 전제 추가:
  `expect(await TtsCanonicalManifest.contains(key), isTrue, reason: ...)`.
- `TtsCanonicalManifest`에는 reset-for-testing 훅이 없음(정적 `_keys` 캐시,
  공개 리셋 메서드 없음) — 브리프 지시대로 "있으면 호출"이라 없으므로
  추가하지 않음.
- mtime 폴링(6초, 40×150ms) 등 나머지 로직은 무수정.
- `flutter test --no-pub test/tts_disk_tier_test.dart` → 1/1 pass.

## SEMANTIC POINT 2 — CI scope 콘텐츠 규칙 순서

`ci_scope.py`/`test_ci_scope.py` 항목 참고. 규칙 순서 버그를 실제로 확인하고
고쳤다(파일 상단 요약 참고).

## SEMANTIC POINT 3 — 자동발화 스텁 가드 재기준선

`test/auto_speech_test_stub_guard_test.dart` 전체 스캔 결과, origin/main이
이미 갖고 있던(이 가드보다 먼저 존재) 미스텁 화면 테스트 파일 2개를 새로
발견:
- `test/features/study_library/study_library_language_test.dart`
- `test/flashcard_language_preferences_test.dart`

Fable 판정대로 "새로 작성된 위반이 아니라 병합이 드러낸 기존 부채의
재측정"으로 처리 — `knownUnstubbedTestFiles`에 정렬 위치대로 추가(각각
`study_bookmark_production_writer_test.dart` 뒤,
`game_layout_test.dart` 앞), `knownUnstubbedCap`을 60 → 62로 갱신. `stale`
쪽(목록에서 사라졌어야 할 항목)은 없었음 — 기존 60개 전부 여전히 미스텁
상태 그대로였다. 이 두 파일을 `stubSoriSpeech()`로 옮기는 작업은 이번
범위 밖(브리프 지시대로 수행하지 않음).
`flutter test --no-pub test/auto_speech_test_stub_guard_test.dart` → 1/1
pass.

## l10n 재생성

`flutter gen-l10n` 실행 — 자동병합된 `.arb`/생성된 `app_localizations*.dart`
내용과 재생성 결과가 완전히 동일(`git diff --stat -- lib/l10n/` 빈 결과).
추가 반영 불필요.

## pubspec.yaml

`- assets/tts/v3/female/`, `- assets/tts/v3/male/` 두 줄 모두 그대로 존재
확인(140-141행). 충돌 없이 자동병합됨.

## `flutter analyze --no-pub`

**0 issues** (220.8초). tts_service.dart 중괄호 복원 실수도 이 단계에서
최종 검증 통과.

## 타겟 테스트 (STEP 6 지정 13개 파일)

1차 실행에서 `auto_speech_test_stub_guard_test.dart` 1개 실패(재기준선
반영 전) — 그 파일만 단독 재실행으로 확인 후 고치고, 13개 파일 전체
재실행: **80/80 pass, 0 fail**.

## 전체 스위트

`flutter test --no-pub --reporter failures-only` (foreground, tee 로그로
확인 — 백그라운드 알림이 신뢰할 수 없어 coordinator 지시대로 로그 파일
직접 폴링 + 최종 foreground 대기로 종료 확인):

**5711 passed / 0 failed / 15 skipped**, exit code 0.

## 예상 밖 이슈 (R2 대상 아님 — 발견 즉시 수정·검증 완료)

머지 커밋 `9cf28881`을 만들기 전, SEMANTIC POINT 1/3 수정을 위해
`test/tts_disk_tier_test.dart`와 `test/auto_speech_test_stub_guard_test.dart`
를 Edit 도구로 고쳤는데, 그 시점이 이미 실행해 둔 명시적
`git add <파일목록>` 배치 **이후**였다 — 두 파일을 재스테이징하지 않고
바로 `git commit`을 실행해, 머지 커밋에 구버전(고치기 전) 내용이 실려버렸다.
`graphify update .`는 git index가 아니라 실제 워킹트리 파일을 읽으므로
그래프 자체는 영향 없었지만, 커밋 히스토리상 `9cf28881`은 단독으로
체크아웃하면 그 2개 테스트가 실패하는 상태였다. `git status --short`로
STEP 7 마무리 전 재확인하다가 발견 → `c767a3f7`로 두 파일만 정확히
커밋해 바로잡았다(diff는 원래 의도한 변경과 완전히 동일, 추가 변경
없음). amend 대신 새 커밋을 쓴 이유: 저장소 안전 수칙("항상 새 커밋,
amend는 사용자가 명시적으로 요청할 때만")을 따름. `c767a3f7` 이후
두 파일 재테스트 통과 확인.

## 가드 재기준선 (증감 상세)

- 파일: `test/auto_speech_test_stub_guard_test.dart`
- 추가된 항목 2개(위 SEMANTIC POINT 3 참고): 정렬 위치에 삽입.
- 제거된 항목: 0개(`stale` 목록 비어 있었음 — main이 파일을 리네임/삭제한
  케이스 없음).
- `knownUnstubbedCap`: 60 → 62.

## graphify 결과

`graphify update .`(foreground, code-only 재추출 — 이 저장소는 LLM 없이
AST만 사용): 511개 미캐시 파일 재추출, 16 workers. 결과: **43740 nodes,
61263 edges, 1152 communities**(직전 커밋 5a561faa 대비 커뮤니티 수 증가는
`git checkout --theirs`로 가져온 origin/main 쪽 graphify-out 상태와 새
코드 반영이 섞인 결과 — 라벨 1117개 저장분 중 253개 커뮤니티를 허브
이름으로 자동 리네임, 나머지는 `Community N` 플레이스홀더로 남음. 이번
작업 범위는 코드 그래프 갱신까지이며 `graphify label`(LLM 커뮤니티
명명)은 수행하지 않음 — 브리프 지시("graphify update .")를 그대로 따름).
`graph.html`은 43740 노드가 5000 초과라 커뮤니티 집계 뷰(1152 노드,
4517 교차-커뮤니티 엣지)로 자동 전환됨.

## 커밋 SHA 요약

- `9cf28881` — 머지 커밋
- `c767a3f7` — 누락 스테이징 수정 커밋
- `3d1b5f95` — graphify 갱신 커밋
- (이 리포트) — force-add 문서 커밋, 별도로 뒤이어 생성

## 열린 질문 (≤3)

1. `graphify label`(LLM 기반 커뮤니티 재명명)을 이번 세션에서 돌릴지 —
   브리프가 `graphify update .`만 지정해 실행하지 않았다. 253개는 자동
   허브-이름으로 리네임됐고 나머지는 `Community N` 플레이스홀더로 남아
   있다.
2. `.superpowers/sdd/2026-09-03-w7-pr1-tts/progress.md`에 이미 있던(내가
   만들지 않은) 미커밋 통합 계획 노트 한 줄이 이 세션 내내 unstaged
   상태로 남아 있다 — "progress.md는 건드리지 말라"는 지시에 따라 그대로
   뒀지만, 이 노트를 커밋할지/누가 커밋할지는 이 작업 범위 밖이라 Jin/
   Fable 판단이 필요하다.
3. SEMANTIC POINT 3에서 발견한 미스텁 파일 2개(`study_library_language_test.dart`,
   `flashcard_language_preferences_test.dart`)를 `stubSoriSpeech()`로
   옮기는 후속 작업은 별도 태스크로 남겨둘지 확인 필요(이번 범위 밖으로
   명시됐지만 부채로 인지되어야 함).

## Post-merge fix (커밋 `d4b39c45`)

머지 과정에서 `lib/screens/pronunciation_studio_screen.dart:493`이 병합
베이스의 `final stopping = SoriSpeech.speaking.value;`(구 bool — `speak`
호출 즉시, 즉 resolving 시작 시점부터 `true`)에서
`SoriSpeech.phase.value == TtsSpeechPhase.speaking`으로 자동/수동 치환돼
행동 회귀가 생겼다. `phase == speaking`은 엔진이 재생 시작을 승격시킨
**이후**에만 참이라, resolving 구간(사용자가 듣기 버튼을 누른 직후 ~
오디오 재생 개시 전) 중에 다시 탭하면 정지가 아니라 재발화가 걸렸다.

Fable 판정: `SoriSpeechIndicator.handleTap`(`lib/widgets/sori/speakable.dart:430`)
이 이미 `phase != TtsSpeechPhase.idle` → stop 규칙을 쓰고 있으므로,
`_listenToModel`도 같은 규칙을 따르도록 맞췄다.

- 수정: `final stopping = SoriSpeech.phase.value != TtsSpeechPhase.idle;`
  로 교체, 인라인 주석에 "같은 규칙" 근거 명시.
- 회귀 테스트 추가(`test/pronunciation_studio_screen_test.dart`):
  `stubSoriSpeech(completeSpeak: false)`로 speak future를 pending시켜
  두고, 첫 탭 후 phase가 `resolving`에 머문 상태에서 두 번째 탭 →
  `SoriSpeech.stop()`(스텁 `stops` 카운터)이 호출되고 재발화가 없으며
  phase가 `idle`로 돌아오는지 확인. 기존 "listen taps never open the
  microphone" 테스트의 단언은 그대로 유지(R2).
- 검증: `flutter test --no-pub test/pronunciation_studio_screen_test.dart`
  26/26 통과(신규 1건 포함), `flutter analyze --no-pub` 0 issues.
- 커밋: `d4b39c45` (production fix + regression test, 단일 커밋).
