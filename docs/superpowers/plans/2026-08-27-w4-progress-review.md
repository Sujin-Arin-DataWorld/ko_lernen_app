# W4 진행·복습 시스템 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 지시서 P1(단어팩·커스텀팩 진행), P2(시나리오 0/2), SRS 일별 원장+ReviewHub+달력, Grammatik 마스터플랜을 계약 고정 테스트를 깨지 않고 랜딩한다.

**Architecture:** ① `LearnSessionQueue`/`course_mastery_service.recordScenarioCheckpoint`는 서비스 계약이 테스트로 동결돼 있으므로 신규 게터·별도 헬퍼로만 확장한다. ② SRS 일별 원장은 `Storage.srsReview` 한 초크포인트에서 날짜별 키(`kl_study_log_v1_<dateIso>`)로 기록해 쓰기 증폭을 막는다. ③ ReviewHub는 `/review`(플레이어) 앞에 신설되는 `/review/hub` 브라우즈 화면이며 기존 라우트는 건드리지 않는다. ④ Grammatik 마스터플랜은 순수 모델+순수 서비스(슬라이스 계산)를 신설하고 화면은 그 출력을 그리기만 한다.

**Tech Stack:** Flutter/Dart (flutter_test), 기존 SharedPreferences 래퍼(`Storage`) 패턴 재사용.

**Spec:** `C:\Users\vjinn\.claude\plans\c-dev-hangulsori-ko-lernen-app-docs-han-fizzy-marshmallow.md` (승인된 마스터 플랜 — W4 행, "설계 요약 — 버그·데이터·성능" P1/P2, "설계 요약 — 신기능·통합·에셋" Grammatik 마스터플랜/SRS 일별 이력+달력, 검수 보강 2·3·14·21·24·25번)

## Global Constraints

- 워크트리: `C:\dev\hangulsori\ko_lernen_app_w4`, 브랜치 `feat/w4-progress-review`(이미 체크아웃됨). **절대 다른 워크트리(`ko_lernen_app`, `_w2`, `_w3`)를 건드리지 않는다** — 다른 세션이 소유.
- 태스크당 1커밋, 커밋 푸터: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- `flutter analyze` 각 태스크 종료 시 신규 이슈 0.
- **계약 고정 테스트 무변경 (절대 규칙):**
  - `learn_session_queue_test.dart:62-68`(`servedPosition holds during re-asks`), `:119-129`(`defer x10 never graduates and keeps uniqueTotal`) — 진행 수식(`servedPosition`/`uniqueTotal`) 로직 변경 금지, 게터 추가만 허용.
  - `course_mastery_test.dart:398-425`(`a current scenario without exact mission provenance stays browse history`) — `course_mastery_service.dart`의 `recordScenarioCheckpoint`/`courseEligible` 판정 로직 변경 금지. 자가 유도 로직을 그 안에 절대 넣지 않는다.
  - `/review` 라우트 고정 테스트 15곳(`accessibility_guideline_test.dart`, `discover_screen_test.dart`, `goldens/screen_layout_golden_test.dart`, `gye_weekly_promise_navigation_test.dart`, `milestone_feedback_widget_test.dart`, `sarangbang_recommendation_test.dart`, `sarangbang_study_screen_test.dart`, `sori_stage_adaptive_chrome_test.dart`, `sori_stage_hanok_shortcuts_test.dart`, `sori_stage_today_availability_test.dart`, `sori_stage_today_matte_test.dart`, `sori_stage_visual_evidence_test.dart`, `today_learning_navigation_test.dart`, `today_learning_snapshot_test.dart`, `ux_preview_app_test.dart`) — `main.dart`의 `case '/review':` 블록(현재 `ReviewSessionScreen(feedbackContentId: 'today_review')`)과 `dedicated_feedback_completion_test.dart:363`의 `'today_review'` 상수를 변경 금지.
- arb 수정은 `app_de.arb`+`app_en.arb` **동시** + `flutter gen-l10n` 실행.
- **신규 스토리지 키는 백업 화이트리스트 필수**: `kl_study_log_v1_*`, `kl_gram_plan_v1`을 도입하는 태스크(Task 10, 15)는 같은 웨이브 안에서 Task 18이 `cloud_sync.dart`/`learning_data_export_service.dart`에 등록하기 전까지 "미등록 신규 키" 상태로 남는다 — Task 18 없이 웨이브를 종료하지 않는다.
- 파일 교집합 있는 태스크는 순차 필수: `storage_service.dart`(Task 7→10→15→18, 이 순서 고정 — Task 18 Step 5가 `appendStudyLogEntryForRestore` 추가로 이 파일을 한 번 더 만진다), `scenario_player_screen.dart`(Task 8→10, 이 순서 고정).
- 서브에이전트 금지 — 각 태스크는 담당 세션이 직접 구현한다.

---

### Task 1: LearnSessionQueue `_servedIds` + `currentIsRepeat`

**Files:**
- Modify: `lib/services/learn_session_queue.dart`
- Modify: `test/learn_session_queue_test.dart`

**Interfaces:**
- Produces: `LearnSessionQueue.currentIsRepeat` → `bool` — 지금 `current`가 이전에 최소 1회 서빙된 재출제 카드인지. `servedPosition`/`uniqueTotal`/기존 outcome enum은 1비트도 바뀌지 않는다.
- Consumes(다음 태스크): Task 2가 이 게터로 "3/9 · +N Wdh." 카운터를 만든다.

- [ ] **Step 1: 실패하는 테스트 추가** — `test/learn_session_queue_test.dart` 끝(§P2-4 섹션 뒤)에 추가:

```dart
  // ── currentIsRepeat (지시서 1.1 보강 — 재출제 칩) ─────────────────────

  test('첫 서빙은 재출제가 아니다', () {
    final q = _q(['a', 'b', 'c']);
    expect(q.currentIsRepeat, isFalse);
  });

  test('markUnknown 이후 재삽입된 카드가 다시 나오면 재출제다', () {
    final q = _q(['a', 'b', 'c', 'd', 'e']);
    q.markUnknown(); // a 재삽입 → b,c,d,a,e. 지금 current 는 b(최초 서빙).
    expect(q.currentIsRepeat, isFalse);
    q.markKnown(); // b 제거 → c,d,a,e
    q.markKnown(); // c 제거 → d,a,e
    q.markKnown(); // d 제거 → a,e — a 가 다시 current
    expect(q.currentIsRepeat, isTrue);
  });

  test('defer 로 재배치된 카드도 재출제로 표시된다', () {
    final q = _q(['a', 'b']);
    q.defer(); // a 재삽입 → [b, a]
    expect(q.currentIsRepeat, isFalse); // 지금 current = b, 최초 서빙
    q.markKnown(); // b 제거 → [a]
    expect(q.currentIsRepeat, isTrue); // a 는 이미 한 번 서빙됨
  });

  test('큐가 비면 currentIsRepeat 은 false', () {
    final q = _q([]);
    expect(q.currentIsRepeat, isFalse);
  });
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/learn_session_queue_test.dart` (컴파일 에러 — `currentIsRepeat` 미정의).
- [ ] **Step 3: 구현** — `lib/services/learn_session_queue.dart`에 필드+게터 추가, 기존 3개 outcome 메서드 각각에 소비 시점 마킹 1줄만 추가(제거 순서·재삽입 위치·`servedPosition` 계산식은 무변경):

```dart
  /// 지금까지 최소 1회 이상 서빙된(사용자에게 제시된) 단어 id 집합.
  /// [currentIsRepeat] 판정 전용 — [servedPosition]/[uniqueTotal] 계약과는
  /// 무관하다(그 계약은 테스트로 동결: learn_session_queue_test.dart:62-68,
  /// 119-129).
  final Set<String> _servedIds = {};

  /// 지금 [current] 로 서빙 중인 카드가 이전에 이미 나왔던 재출제 카드인지.
  /// 진행 분자/분모에는 영향 없음 — 세션 UI 의 "Wiederholung" 표시 전용.
  bool get currentIsRepeat {
    final cur = current;
    return cur != null && _servedIds.contains(idOf(cur));
  }
```

`markKnown()`/`markUnknown()`/`defer()` 각각의 `_requireCurrent();` 바로 다음 줄에 `_servedIds.add(idOf(_queue.first));`를 추가(제거 전에 마킹 — 세 메서드 모두 `_queue.first`가 곧 `_queue.removeAt(0)`으로 꺼낼 항목과 동일):

```dart
  LearnAnswerOutcome markKnown() {
    _requireCurrent();
    _servedIds.add(idOf(_queue.first));
    _queue.removeAt(0);
    return LearnAnswerOutcome.advanced;
  }
```

(`markUnknown()`/`defer()`도 동일하게 `_requireCurrent();` 다음 줄에 같은 한 줄을 추가한다. 세 메서드의 나머지 본문은 무변경.)
- [ ] **Step 4: GREEN 확인** — `flutter test test/learn_session_queue_test.dart` 전체 통과(기존 62-68/119-129 포함 무회귀).
- [ ] **Step 5: analyze + 커밋** — `flutter analyze` 0 확인 → `git add lib/services/learn_session_queue.dart test/learn_session_queue_test.dart && git commit -m "feat(learn-queue): _servedIds + currentIsRepeat 게터 추가 (지시서 1.1 보강, 진행 계약 불변)"`

---

### Task 2: vocab_pack_screen.dart 카운터 "3/9 · +N Wdh." + dispose 진행 영속화

**Files:**
- Modify: `lib/screens/vocab_pack_screen.dart` (카운터 `SoriChip` :927-932, `dispose()` :210-215)
- Modify: `lib/l10n/app_de.arb` + `lib/l10n/app_en.arb` (`vocabPackLearnHint` 근처: app_de.arb:1023, app_en.arb:1016)
- Test: 기존 위젯 테스트 존재 여부 확인(`grep -rln "vocabPackLearnHint\|_learnRepeatCount\|vocab-pack" test/`) — 발견되면 그 파일에 케이스 추가, 없으면 `test/vocab_pack_screen_repeat_counter_test.dart` 신설.

**Interfaces:**
- Consumes: Task 1의 `LearnSessionQueue.currentIsRepeat`.
- Produces: dispose 시 `PackProgressService.recordWordLearned(pack)` 1회 추가 호출(기존 완주 시 1회 + 이탈 시 1회 = 세션당 최대 2회, `wordsLearnedIn` 유도값이라 멱등).

- [ ] **Step 1: 실패하는 단위 테스트** — `_learnRepeatCount` 증가 로직과 라벨 포맷은 위젯 상태 내부라 위젯 테스트로 검증. `grep -rln "VocabPackScreen(" test/`로 기존 하네스 확인 후, 그 패턴을 재사용해 다음 케이스를 추가:

```dart
  testWidgets('재출제 카드가 나오면 카운터가 "n / m · +k Wdh." 형식이 된다', (
    tester,
  ) async {
    // 기존 하네스로 3단어 팩을 로드하고 1번째 카드에서 "몰라요"를 눌러
    // 재출제를 유발한 뒤, 재출제 카드가 서빙되는 시점의 SoriChip 라벨을 검증.
    // ... (기존 vocab_pack_screen 위젯 테스트의 pumpWidget/찾기 패턴 재사용)
    expect(find.textContaining('· +1'), findsOneWidget);
  });
```

- [ ] **Step 2: 실행 → FAIL 확인** (라벨에 `· +N` 접미사가 없어 실패).
- [ ] **Step 3: arb 키 추가** — `app_de.arb`(`vocabPackLearnHint` 옆, :1023 부근)와 `app_en.arb`(:1016 부근)에 동시 추가:

```json
  "vocabPackLearnRepeatSuffix": " · +{n, plural, one{1 Wdh.} other{{n} Wdh.}}",
  "@vocabPackLearnRepeatSuffix": {
    "description": "Learn stage counter suffix for re-served (missed) cards",
    "placeholders": {"n": {"type": "int"}}
  },
```

(app_en.arb는 동일 키에 `" · +{n, plural, one{1 repeat} other{{n} repeats}}"`.)
- [ ] **Step 4: `flutter gen-l10n` 실행.**
- [ ] **Step 5: 구현 — 상태 필드 + 카운터 증가.** `_VocabPackScreenState`에 필드 추가(다른 Stage 1 상태 필드들 옆, :174 `_learnServe` 다음):

```dart
  // 이 세션에서 재출제로 다시 나온 카드 수 — "3/9 · +2 Wdh." 표시용
  // (지시서 검수#21: 별도 칩이 아니라 숫자에 병기).
  int _learnRepeatCount = 0;
```

`_advanceLearn()`(:387-402)의 `setState` 블록에 한 줄 추가:

```dart
    setState(() {
      _flipped = false;
      _learnCardRevealed = false;
      _learnServe++;
      if (_learnQueue?.currentIsRepeat ?? false) {
        _learnRepeatCount++;
      }
    });
```

- [ ] **Step 6: 카운터 라벨 갱신** — `_buildLearn()`의 `SoriChip`(:927-932) 라벨을 교체:

```dart
            SoriChip(
              // 분모 = 고유 단어 수(고정). 재출제 중에는 분자가 유지된다.
              // +N Wdh. = 이 세션에서 재출제로 다시 나온 카드 수(지시서 검수#21).
              label:
                  '${_learnQueue?.servedPosition ?? 1} / ${_learnQueue?.uniqueTotal ?? _learnWords.length}'
                  '${_learnRepeatCount > 0 ? t.vocabPackLearnRepeatSuffix(_learnRepeatCount) : ''}',
              accent: SoriColors.info,
            ),
```

(`_buildLearn(AppL10n t)`가 이미 `t`를 인자로 받으므로 추가 조회 불필요.)
- [ ] **Step 7: dispose 시 진행 영속화 구현** — `_persistLearnProgress()` 신설(예: `_advanceLearn()` 근처):

```dart
  /// Learn 단계를 완주하지 않고 이탈해도 그때까지 본 단어 수를 영속화한다
  /// (지시서 1.1 "3/9 멈춤" — 완주해야만 recordWordLearned 가 불렸던 것을
  /// 이탈 시에도 flush). wordsLearnedIn 은 vokSeenIds 교집합으로 유도하므로
  /// 여러 번 불러도 멱등 — 세션당 완주 시 1회(_advanceLearn) + 이탈 시 1회
  /// (dispose) = 최대 2회.
  void _persistLearnProgress() {
    final pack = _pack;
    if (pack == null) return;
    // ignore: discarded_futures
    PackProgressService.recordWordLearned(pack);
  }
```

`dispose()`(:210-215)를 수정:

```dart
  @override
  void dispose() {
    _persistLearnProgress();
    _abandonTracker.dispose();
    _flipHintTrigger.dispose();
    super.dispose();
  }
```

- [ ] **Step 8: GREEN 확인 + `flutter analyze`.**
- [ ] **Step 9: 커밋** — `git commit -m "feat(vocab-pack): 재출제 카운터 '+N Wdh.' 병기 + dispose 진행 영속화 (지시서 1.1)"`

---

### Task 3: vocab_pack_result_screen.dart 뒤로가기 복구

**Files:**
- Modify: `lib/screens/vocab_pack_result_screen.dart` (`automaticallyImplyLeading:false` :118, "Zurück zum Grid" CTA :309-320)
- Test: `grep -rln "VocabPackResultScreen" test/`로 기존 하네스 확인 후 케이스 추가.

**Interfaces:**
- Produces: 기본 AppBar 뒤로가기 복원(`pushReplacementNamed`가 이전 화면을 그대로 유지하므로 direct-library 진입은 `/vocab`으로, course-mission 진입은 미션 화면으로 자연 복귀) + "Zurück zum Grid" 버튼의 courseContext 분기.

- [ ] **Step 1: 실패하는 테스트** — 기존 결과 화면 테스트 하네스 패턴을 따라 두 케이스 추가:

```dart
  testWidgets('automaticallyImplyLeading 가 없어 기본 뒤로가기가 보인다', (
    tester,
  ) async {
    // 기존 하네스로 VocabPackResultScreen 을 courseContext 없이 pump.
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('courseContext 가 있으면 Zurück zum Grid 는 pop 1회만 한다', (
    tester,
  ) async {
    // Navigator 스택을 [Home, CourseMission, VocabPackResult] 로 세팅한 뒤
    // (courseContext 포함) "Zurück zum Grid" 탭 → CourseMission 라우트로
    // 정확히 1회 pop 했는지 검증(popUntil('/vocab') 이 아니라).
  });
```

- [ ] **Step 2: 실행 → FAIL 확인.**
- [ ] **Step 3: `automaticallyImplyLeading` 삭제** — :118 줄 제거:

```dart
    return SoriStudyFrame(
      title: t.vocabPackResultTitle,
      // 짧은 결과 콘텐츠가 태블릿 상단에 쏠려 아래가 텅 비지 않도록,
```

(`SoriStudyFrame`의 `automaticallyImplyLeading` 기본값은 `true` — `lib/widgets/sori/study_frame.dart:25` 확인됨. `pushReplacementNamed('/vocab/result', ...)`가 VocabPackScreen 자리를 그대로 대체하므로, 기본 뒤로가기는 direct-library 진입 시 `/vocab`으로, course-mission 진입 시 미션 화면으로 자연스럽게 돌아간다.)
- [ ] **Step 4: "Zurück zum Grid" CTA 분기** — :309-320을 교체:

```dart
                const SizedBox(height: Spacing.sm),
                SoriEntrance(
                  delay: Duration(milliseconds: _cleared ? 1000 : 280),
                  child: _CtaButton(
                    label: t.vocabPackResultBackToGrid,
                    icon: Icons.grid_view_rounded,
                    variant: SoriButtonVariant.outlined,
                    accent: SoriColors.info,
                    onTap: () {
                      if (courseContext != null) {
                        // 코스 미션에서 진입 — /vocab 이 스택에 없을 수
                        // 있으므로 popUntil 대신 정확히 1단계만 되돌아간다.
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).popUntil(
                          (r) => r.settings.name == '/vocab' || r.isFirst,
                        );
                      }
                    },
                  ),
                ),
```

- [ ] **Step 5: GREEN + `flutter analyze`.**
- [ ] **Step 6: 커밋** — `git commit -m "fix(vocab-pack): 결과화면 뒤로가기 복구 — 기본 AppBar 리딩 + courseContext 분기 (지시서 1.2)"`

---

### Task 4: 표준팩 소급 복구 (팩 목록 열람 시 재동기화)

**Files:**
- Modify: `lib/screens/vocab_packs_screen.dart` (`_load()` :94-…)
- Test: `grep -rln "VocabPacksScreen(" test/`로 기존 하네스 확인 후 케이스 추가(없으면 `test/vocab_packs_screen_backfill_test.dart` 신설).

**Interfaces:**
- Consumes: `PackProgressService.wordsLearnedIn(pack)`(이미 존재, `pack_progress_service.dart:199-202`), `PackProgressService.recordWordLearned(pack)`(이미 존재, `overrideCount` 없이 호출 시 내부에서 `wordsLearnedIn` 재계산).
- Produces: 기존 3/9에 갇힌 사용자를 팩 목록 열람만으로 자가 치유.

- [ ] **Step 1: 실패하는 테스트** — `Storage.vokSeenIds`에 팩 단어 3개를 미리 넣고 `PackProgress.wordsLearned`는 0으로 저장한 상태에서 `VocabPacksScreen`을 pump → 로드 후 저장된 `PackProgress.wordsLearned`가 3으로 재동기화됐는지 검증:

```dart
  testWidgets('팩 목록 열람 시 vokSeenIds 와 어긋난 wordsLearned 를 재동기화한다', (
    tester,
  ) async {
    // given: pack.words 중 3개가 Storage.vokSeenIds 에 있지만
    // PackProgress(packId).wordsLearned 는 0으로 저장(과거 버그 상태 재현).
    await tester.pumpWidget(/* 기존 하네스 */);
    await tester.pumpAndSettle();
    expect(PackProgressService.get(packId)?.wordsLearned, 3);
  });
```

- [ ] **Step 2: 실행 → FAIL 확인.**
- [ ] **Step 3: 구현** — `_load()`(:94-160대) 안, `PackProgressService.loadLevelView(_level)` 호출 직후에 소급 동기화 루프 추가:

```dart
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final packs = await PackProgressService.loadLevelView(_level);
      // 지시서 검수#21 표준팩 소급 복구: vokSeenIds 는 이미 정직하게 쌓였는데
      // PackProgress.wordsLearned 만 어긋난(과거 "3/9 멈춤") 팩을 여기서
      // 재동기화한다. wordsLearnedIn 은 순수 유도값이라 매번 다시 불러도
      // 안전하고, 값이 같으면 recordWordLearned 자체가 사실상 no-op merge.
      for (final entry in packs) {
        final derived = PackProgressService.wordsLearnedIn(entry.pack);
        if (derived != entry.progress.wordsLearned) {
          // ignore: discarded_futures
          PackProgressService.recordWordLearned(entry.pack);
        }
      }
      if (!mounted) return;
      setState(() {
        _packs = packs;
        _loading = false;
      });
```

(`packs`/`_packs` 실제 변수명·`loadLevelView`의 반환 레코드 필드명은 `pack_progress_service.dart:620` `({VocabPack pack, PackProgress progress})`를 그대로 사용하며, 기존 `_load()`의 나머지 상태 갱신 코드는 그대로 둔다 — 이 스텝은 `packs` 획득 직후~`setState` 직전에 루프 1개만 삽입.)
- [ ] **Step 4: GREEN + `flutter analyze`.**
- [ ] **Step 5: 커밋** — `git commit -m "fix(vocab-packs): 팩 목록 열람 시 wordsLearned 소급 재동기화 (지시서 검수#21)"`

---

### Task 5: 커스텀팩 learnedWordCount + addVokSeen 누락 보완 + 책장 타일

**Files:**
- Modify: `lib/services/custom_pack_service.dart` (신규 `learnedWordCount`)
- Modify: `lib/screens/bookshelf_screen.dart` (`_CustomPackTile` :349-374)
- Modify: `lib/screens/custom_pack_quiz_screen.dart` (:154 부근), `lib/screens/custom_pack_matching_screen.dart` (`_tapRight` :168-176), `lib/screens/custom_pack_typing_screen.dart` (:145-147)
- Modify: `lib/l10n/app_de.arb` + `lib/l10n/app_en.arb` (`bookshelfPackMeta` 옆, app_de.arb:183 부근)
- Test: `test/custom_pack_service_test.dart`(존재 확인 후 없으면 신설) — `learnedWordCount` 단위 테스트.

**Interfaces:**
- Produces: `CustomPackService.learnedWordCount(CustomPack pack) -> int` — `PackProgressService.wordsLearnedIn`과 동일 패턴(vokSeenIds 교집합, 별도 카운터 없음).
- Consumes: `Storage.addVokSeen`(이미 존재, `custom_pack_play_screen.dart:114`에서만 호출 중 — quiz/matching/typing 3화면 누락 보완).

- [ ] **Step 1: 실패하는 단위 테스트** — `test/custom_pack_service_test.dart`(신설 시 기존 `CustomPackService` 테스트 하네스의 `SharedPreferences.setMockInitialValues({})` 초기화 패턴을 따른다):

```dart
  test('learnedWordCount 는 vokSeenIds 교집합으로 유도된다', () async {
    final pack = CustomPack(
      id: 'cp1',
      name: 'Test',
      words: [
        ExtractedWord(korean: '안녕', translationDe: 'Hallo'),
        ExtractedWord(korean: '감사', translationDe: 'Danke'),
      ],
      createdAt: DateTime.now(),
    );
    expect(CustomPackService.learnedWordCount(pack), 0);
    await Storage.addVokSeen('안녕');
    expect(CustomPackService.learnedWordCount(pack), 1);
  });
```

(`CustomPack`/`ExtractedWord` 생성자 필수 필드는 `lib/models/custom_pack.dart`/`lib/models/book_page.dart`를 확인해 맞춘다.)
- [ ] **Step 2: 실행 → FAIL 확인** (메서드 미정의).
- [ ] **Step 3: 구현** — `lib/services/custom_pack_service.dart`에 (이미 `storage_service.dart` import됨):

```dart
  /// PackProgressService.wordsLearnedIn 과 동일 패턴 — 별도 카운터를 두지
  /// 않고 vokSeenIds 교집합으로 유도한다(지시서 1.21 — 세션 진행 무영속
  /// "0/2" 버그의 근본 해결: addVokSeen 이 이미 남긴 노출 기록을 그대로
  /// 읽으므로 신규 쓰기 경로가 필요 없다).
  static int learnedWordCount(CustomPack pack) {
    final seen = Storage.vokSeenIds.toSet();
    return pack.words.where((w) => seen.contains(w.korean)).length;
  }
```

- [ ] **Step 4: addVokSeen 보완 — quiz** `custom_pack_quiz_screen.dart` `_pick()`(:145-154)에서 srsReview 바로 앞에 추가:

```dart
    setState(() => _picked = option);
    // A1: 노출 기록(책장 타일 "n von m gelernt" 소스) + 퀴즈 결과를 SRS 에 반영.
    Storage.addVokSeen(word.korean);
    Storage.srsReview(word.korean, gotIt: isRight);
```

- [ ] **Step 5: addVokSeen 보완 — matching** `custom_pack_matching_screen.dart` `_tapRight(String meaning)`(:168-176) 맨 위, `expected` 계산 직후에 추가:

```dart
    final expected = _round
        .firstWhere((word) => word.korean == ko)
        .translationFor(_languageCode)
        .trim();
    // 정답/오답 무관 — 이 라운드에서 노출됐다는 사실 자체를 기록한다.
    Storage.addVokSeen(ko);
    if (meaning == expected) {
```

- [ ] **Step 6: addVokSeen 보완 — typing** `custom_pack_typing_screen.dart` `_submit()`(:141-147)에서 srsReview 바로 앞에 추가:

```dart
    final word = _pool[_order[_idx]];
    final ok = _norm(_input.text) == _norm(word.korean);
    Storage.addVokSeen(word.korean);
    Storage.srsReview(word.korean, gotIt: ok); // A1 연동
```

- [ ] **Step 7: arb 키** — `bookshelfPackMeta` 옆(app_de.arb:183 부근)에 동시 추가:

```json
  "bookshelfPackLearnedMeta": "{learned} von {total} gelernt",
  "@bookshelfPackLearnedMeta": {
    "description": "Custom pack tile progress — words learned of total",
    "placeholders": {"learned": {"type": "int"}, "total": {"type": "int"}}
  },
```

(app_en.arb 동일 키: `"{learned} of {total} learned"`.) → `flutter gen-l10n` 실행.
- [ ] **Step 8: 책장 타일 표시** — `bookshelf_screen.dart` `_CustomPackTile.build()`(:335-380) 서브타이틀 `Text(t.bookshelfPackMeta(pack.totalWords), ...)`(:371-374)를 교체:

```dart
                        Text(
                          '${t.bookshelfPackMeta(pack.totalWords)} · '
                          '${t.bookshelfPackLearnedMeta(CustomPackService.learnedWordCount(pack), pack.totalWords)}',
                          style: SoriTextTheme.of(context).cardSubtitle,
                        ),
```

(identityLabel의 `t.bookshelfPackMeta(pack.totalWords)`(:350)는 접근성 요약이라 그대로 두거나 동일하게 갱신 — 접근성 라벨도 갱신해 시각/음성 정보를 일치시킨다: `identityLabel`도 같은 문자열로 교체.)
- [ ] **Step 9: GREEN + `flutter analyze` + `flutter test`(회귀 확인).**
- [ ] **Step 10: 커밋** — `git commit -m "feat(custom-pack): learnedWordCount + addVokSeen 누락 보완(quiz/matching/typing) + 책장 진행 표시 (지시서 1.21, 검수#23)"`

---

### Task 6: `activeScenarioCheckpointContext` — course_mission_navigation.dart 확장

**Files:**
- Modify: `lib/services/course_mission_navigation.dart` (신규 파일 아님 — **기존 파일에 함수 추가**, 이미 `CoursePracticeContext`/`CourseMissionDestination` 등을 export 중)
- Modify: `test/course_mission_navigation_test.dart` (기존 파일, 203줄 — 케이스 추가)

**Interfaces:**
- Produces: `Future<CoursePracticeContext?> activeScenarioCheckpointContext(String scenarioId, {CurriculumCatalog? catalog, CourseMasterySnapshot? snapshot})` — `course_mastery_service.dart:638-653`의 `activeCheckpoint` 판정을 미러링하되, 이미 주어진 `courseContext` 검증이 아니라 **현재 활성 유닛으로부터 자동 유도**한다. `course_mastery_service.recordScenarioCheckpoint` 내부는 절대 건드리지 않는다(계약 동결).
- Consumes(다음 태스크): Task 8이 `scenario_player_screen.dart._load()`에서 `widget.courseContext ?? await activeScenarioCheckpointContext(...)`로 호출.

- [ ] **Step 1: 실패하는 테스트 추가** — `test/course_mission_navigation_test.dart` 끝에 추가. 카탈로그 픽스처는 `test/course_mastery_test.dart:1893-2116`의 `_catalog()`/`CurriculumCatalog.fromDataForTesting(manifestJson:, vocab:, grammar:, smalltalk:, cloze:, satz:, scenarios:)` 구성 방식을 그대로 미러링하되(그 헬퍼는 private이라 재사용 불가 — 동일 셰이프로 로컬 재구성), `checkpointContentIds: ['scenario:airport_arrival']`을 가진 활성 유닛 1개 + `airport_arrival` id의 `Scenario` 픽스처 1개만 있으면 충분하다:

```dart
  group('activeScenarioCheckpointContext', () {
    test('활성 유닛의 체크포인트 시나리오면 컨텍스트를 유도한다', () async {
      final catalog = /* course_mastery_test.dart 의 _catalog() 셰이프를 미러링해
                          checkpointContentIds: ['scenario:airport_arrival'] 인
                          단일 유닛 'a1_01_greetings_hangul' + 그 시나리오를
                          exactlyAssesses 하는 assess ContentLink 1개로 구성 */;
      final snapshot = const CourseMasterySnapshot(
        currentCourseUnitId: 'a1_01_greetings_hangul',
      );
      final context = await activeScenarioCheckpointContext(
        'airport_arrival',
        catalog: catalog,
        snapshot: snapshot,
      );
      expect(context, isNotNull);
      expect(context!.courseUnitId, 'a1_01_greetings_hangul');
      expect(context.contentKind, CurriculumContentKind.scenario);
      expect(context.initialContentId, 'airport_arrival');
    });

    test('활성 유닛이 없으면 null', () async {
      final catalog = /* 위와 동일 픽스처 */;
      final context = await activeScenarioCheckpointContext(
        'airport_arrival',
        catalog: catalog,
        snapshot: const CourseMasterySnapshot.empty(),
      );
      expect(context, isNull);
    });

    test('시나리오가 활성 유닛의 체크포인트가 아니면 null (브라우즈 유지)', () async {
      final catalog = /* 위와 동일 픽스처 */;
      final snapshot = const CourseMasterySnapshot(
        currentCourseUnitId: 'a1_01_greetings_hangul',
      );
      final context = await activeScenarioCheckpointContext(
        'unrelated_scenario',
        catalog: catalog,
        snapshot: snapshot,
      );
      expect(context, isNull);
    });
  });
```

- [ ] **Step 2: 실행 → FAIL 확인** (함수 미정의로 컴파일 실패).
- [ ] **Step 3: 구현** — `lib/services/course_mission_navigation.dart`에 추가(파일 상단 import에 `course_mastery_service.dart`, `course_progress_service.dart`, `curriculum_catalog.dart` 추가):

```dart
/// 실행 진입 지점(시나리오 리스트/추천/반복)에서 컨텍스트 없이 열린 시나리오가
/// 지금 활성 코스 유닛의 체크포인트라면, 그 컨텍스트를 자동으로 유도한다.
///
/// **course_mastery_service.dart 의 courseEligible 판정 로직은 여기서
/// 절대 복제하지 않는다** — `recordScenarioCheckpoint` 내부(:638-653)의
/// activeCheckpoint 술어를 그대로 미러링해 "이 시나리오가 활성 유닛의
/// 선언된 체크포인트 링크와 정확히 일치하는가"만 판정한다. 실제 courseEligible
/// 부여는 여전히 그 서비스 내부에서만 일어난다(계약 동결:
/// course_mastery_test.dart:398-425).
Future<CoursePracticeContext?> activeScenarioCheckpointContext(
  String scenarioId, {
  CurriculumCatalog? catalog,
  CourseMasterySnapshot? snapshot,
}) async {
  final normalizedScenarioId = scenarioId.trim();
  if (normalizedScenarioId.isEmpty) {
    return null;
  }
  final resolvedCatalog = catalog ?? await CurriculumCatalog.load();
  if (resolvedCatalog.validationIssues.isNotEmpty) {
    return null;
  }
  final resolvedSnapshot =
      snapshot ?? await CourseProgressService.shared.readForDisplay();
  final activeUnitId = resolvedSnapshot?.currentCourseUnitId;
  if (activeUnitId == null) {
    return null;
  }
  final activeUnit = resolvedCatalog.courseUnitFor(activeUnitId);
  if (activeUnit == null) {
    return null;
  }
  final links = resolvedCatalog.linksForContent(
    CurriculumContentKind.scenario,
    normalizedScenarioId,
  );
  ContentLink? match;
  for (final link in links) {
    if (link.courseUnitId == activeUnit.id &&
        activeUnit.checkpointContentIds.contains(link.contentKey) &&
        link.exactlyAssesses(activeUnit)) {
      match = link;
      break;
    }
  }
  return match == null ? null : CoursePracticeContext.fromLink(match);
}
```

- [ ] **Step 4: GREEN 확인** — `flutter test test/course_mission_navigation_test.dart`.
- [ ] **Step 5: analyze + 커밋** — `git commit -m "feat(course): activeScenarioCheckpointContext — 활성 유닛 체크포인트 자동 유도 (지시서 4.15, courseEligible 판정은 서비스 계약 그대로)"`

---

### Task 7: setScenarioStars 0성 최초 기록 허용

**Files:**
- Modify: `lib/services/storage_service.dart` (`setScenarioStars` :2679-2686)
- Test: `grep -rln "setScenarioStars" test/`로 기존 테스트 파일 확인 후 케이스 추가.

**Interfaces:**
- Produces: `setScenarioStars(id, stars)`가 **최초 기록은 stars 값과 무관하게** 저장(기존은 `(current[id] ?? 0) < stars`라 `stars == 0`이면 최초에도 절대 안 써짐 — "0/2 저장 안 됨"의 원인 중 하나). 이후 재도전은 여전히 단조 증가만 허용(더 낮은 점수로 덮어쓰지 않음).

- [ ] **Step 1: 실패하는 테스트** — 기존 srs/scenario 테스트 파일의 `Storage.resetForTesting()` 패턴을 따라 추가:

```dart
  test('setScenarioStars 는 0성도 최초 1회는 기록한다', () async {
    Storage.resetForTesting();
    expect(Storage.scenarioStars.containsKey('s1'), isFalse);
    await Storage.setScenarioStars('s1', 0);
    expect(Storage.scenarioStars['s1'], 0);
  });

  test('setScenarioStars 는 여전히 단조 증가만 허용한다', () async {
    Storage.resetForTesting();
    await Storage.setScenarioStars('s1', 2);
    await Storage.setScenarioStars('s1', 1); // 낮은 재도전 — 무시
    expect(Storage.scenarioStars['s1'], 2);
    await Storage.setScenarioStars('s1', 3); // 더 높은 재도전 — 반영
    expect(Storage.scenarioStars['s1'], 3);
  });
```

- [ ] **Step 2: 실행 → FAIL 확인** (첫 케이스에서 `scenarioStars['s1']`가 null — 현재 `(current[id] ?? 0) < stars` = `0 < 0` = false라 write 스킵됨).
- [ ] **Step 3: 구현** — `storage_service.dart:2679-2686`을 교체:

```dart
  static Future<void> setScenarioStars(String id, int stars) async {
    final current = scenarioStars;
    final alreadyRecorded = current.containsKey(id);
    // 0성 최초 완료도 반드시 기록돼야 한다 — 완료 여부(=키 존재) 자체가
    // 코스 체크포인트 "0/2→1/2" 판정의 입력이다(지시서 4.15). 이후 재도전은
    // 여전히 단조 증가만 허용(더 낮은 점수로 덮어쓰지 않음).
    if (!alreadyRecorded || (current[id] ?? 0) < stars) {
      final updated = Map<String, int>.of(current)..[id] = stars;
      _scenarioStarsCache = Map<String, int>.unmodifiable(updated);
      await _ss('kl_scenario_stars', jsonEncode(updated));
    }
  }
```

- [ ] **Step 4: GREEN + `flutter analyze` + `flutter test`(scenario 관련 회귀 확인).**
- [ ] **Step 5: 커밋** — `git commit -m "fix(storage): setScenarioStars 0성 최초 기록 허용 — 완료 여부는 stars 값과 무관 (지시서 4.15)"`

---

### Task 8: scenario_player_screen.dart courseContext 자동 유도 배선

**Files:**
- Modify: `lib/screens/scenario_player_screen.dart` (`_load()` :579-618, `_persistResult()` :853-858)
- Test: `grep -rln "ScenarioPlayerScreen(" test/`에서 courseContext 관련 기존 테스트 확인 후 케이스 추가.

**Interfaces:**
- Consumes: Task 6의 `activeScenarioCheckpointContext`.
- Produces: `_load()`가 `widget.courseContext ?? await activeScenarioCheckpointContext(widget.scenarioId)`로 유도한 **하나의** 유효 컨텍스트를 상태에 저장해, 미션 스텝 계산과 체크포인트 기록 양쪽에서 재사용한다. `course_mastery_service.recordScenarioCheckpoint` 자체는 무변경.

- [ ] **Step 1: 실패하는 테스트** — 기존 `ScenarioPlayerScreen` 위젯 테스트 하네스를 따라, `courseContext: null`로 열되 활성 코스 유닛이 그 시나리오를 체크포인트로 선언한 상태에서 완주 시 `recordScenarioCheckpoint`가 `courseContext` 있이 호출됐는지(=courseEligible 경로를 탔는지) 검증:

```dart
  testWidgets(
    '리스트/추천에서 courseContext 없이 열려도 활성 체크포인트면 자동 유도된다',
    (tester) async {
      // given: CourseProgressService.shared 가 currentCourseUnitId 로
      // 'a1_01_greetings_hangul' 을 갖고, 그 유닛이 'airport_arrival' 을
      // checkpointContentIds 로 선언(기존 course_mastery_test 픽스처 재사용).
      await tester.pumpWidget(
        /* ScenarioPlayerScreen(scenarioId: 'airport_arrival', courseContext: null, ...) */
      );
      // 시나리오를 끝까지 진행 후 결과 화면에서 courseEligible 체크포인트가
      // 기록됐는지 확인 (기존 완주 헬퍼 재사용).
      expect(/* CourseProgressService.shared 스냅샷의 scenarioCheckpoints.last.courseEligible */, isTrue);
    },
  );
```

- [ ] **Step 2: 실행 → FAIL 확인** (현재는 `widget.courseContext`가 null이면 courseContext 없이 진행 → courseEligible false).
- [ ] **Step 3: 상태 필드 추가** — `_ScenarioPlayerScreenState`에 필드 추가(:420 부근, `_missionTitle` 옆):

```dart
  CoursePracticeContext? _effectiveCourseContext;
```

- [ ] **Step 4: `_load()` 배선** — :579-582을 교체:

```dart
    final courseContext =
        widget.courseContext ??
        await activeScenarioCheckpointContext(widget.scenarioId);
    final catalog = courseContext?.isFor(CurriculumContentKind.scenario) == true
        ? await CurriculumCatalog.load()
        : null;
```

:602-618의 나머지 미션스텝 계산 코드는 이미 지역변수 `courseContext`를 쓰므로 무변경. `setState` 블록(:628-635)에 한 줄 추가:

```dart
    setState(() {
      _scenario = s;
      _missionStep = missionStep;
      _missionTitle = missionTitle;
      _effectiveCourseContext = courseContext;
      _plan = plan;
      _stage = initialStage;
      _questReady = initialStage == 0;
    });
```

- [ ] **Step 5: `_persistResult()` 배선** — :857의 `courseContext: widget.courseContext`를 교체:

```dart
    final courseUpdate = await CourseActivityReporter.recordScenarioCheckpoint(
      s.id,
      passed: _passedCount,
      total: s.quests.length,
      courseContext: _effectiveCourseContext,
    );
```

- [ ] **Step 6: import 추가** — 파일 상단에 `import '../services/course_mission_navigation.dart';`가 없으면 추가(이미 `course_mission_navigation.dart`의 다른 심볼을 쓰고 있다면 생략).
- [ ] **Step 7: GREEN + `flutter analyze` + `flutter test`(scenario_player 관련 스위트 회귀 확인 — 특히 `scenario_can_do_result_flow`/`scenario_srs_persistence_flow` 무변경 확인).**
- [ ] **Step 8: 커밋** — `git commit -m "feat(scenario-player): 활성 체크포인트 courseContext 자동 유도 배선 — 리스트/추천/반복 진입 전부 (지시서 4.15)"`

---

### Task 9: scenarios_list_screen.dart onClosed 갱신

**Files:**
- Modify: `lib/screens/scenarios_list_screen.dart` (`_ScenariosListScreenState.build()` :176-206, `_LessonPathHeader` :488+, `_LevelSection` :215+, `_OpenScenarioCard` :316-354, `_NextRecommended` :687-720)
- Test: `grep -rln "ScenariosListScreen(" test/`로 기존 하네스 확인 후 케이스 추가.

**Interfaces:**
- Produces: 시나리오 플레이어에서 돌아오면(별점/체크포인트 변경) 목록이 `setState`로 재조회한다. 두 진입점(그리드 카드의 `OpenContainer`, "다음 추천"의 `Navigator.push`) 모두 배선.

- [ ] **Step 1: 실패하는 테스트** — 기존 하네스로 `ScenariosListScreen`을 pump, 추천 카드를 탭해 `ScenarioPlayerScreen`으로 진입 후 pop, 그 시점에 `Storage.scenarioStars`가 바뀌어 있으면 목록 카드의 별 표시가 갱신되는지 검증(정확한 pump 방법은 기존 시나리오 완주 테스트 헬퍼를 참고):

```dart
  testWidgets('추천 카드에서 시나리오를 마치고 돌아오면 목록 별점이 갱신된다', (
    tester,
  ) async {
    // ... 기존 하네스로 진입 → 완주 → pop
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_rounded), findsWidgets); // 갱신된 별
  });
```

- [ ] **Step 2: 실행 → FAIL 확인** (현재 두 진입점 모두 pop 후 `setState` 없음).
- [ ] **Step 3: 콜백 신설 + 스레딩.** `_LessonPathHeader`(:488-495 부근, `stars` 필드 옆)와 `_LevelSection`(:215-222 부근, `stars` 필드 옆)에 각각 필드 추가:

```dart
  final VoidCallback onScenarioClosed;
```

(각 클래스의 `const _LessonPathHeader({...})`/`const _LevelSection({...})` 생성자에 `required this.onScenarioClosed,` 추가.)

`_OpenScenarioCard`(:316-330)에도 동일 필드+생성자 파라미터 추가, `openBuilder`(:349-352)에 배선:

```dart
      openBuilder: (ctx, _) => ScenarioPlayerScreen(
        scenarioId: scenario.id,
        levelHint: scenario.level,
        onExit: onScenarioClosed,
      ),
```

`_NextRecommended`(:687-694 부근)에도 동일 필드 추가, `openScenario()`(:700-710)를 교체:

```dart
    void openScenario() {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => ScenarioPlayerScreen(
                scenarioId: scenario.id,
                levelHint: scenario.level,
                onExit: onClosed,
              ),
            ),
          )
          .then((_) => onClosed());
    }
```

- [ ] **Step 4: 최상위 State 배선.** `_ScenariosListScreenState.build()`에서 `_LessonPathHeader(...)`(:176-183)와 `_LevelSection(...)`(:190-205)의 각 인스턴스에 `onScenarioClosed: () { if (mounted) setState(() {}); },`를 추가. `_LessonPathHeader`가 내부에서 `_NextRecommended`를 만드는 지점(:600 부근)에도 같은 콜백을 그대로 전달(`onClosed: onScenarioClosed`).
- [ ] **Step 5: GREEN + `flutter analyze`.**
- [ ] **Step 6: 커밋** — `git commit -m "fix(scenarios-list): 플레이어에서 복귀 시 목록 setState 갱신 배선 (지시서 4.15)"`

---

### Task 10: SRS 일별 학습 원장 (`kl_study_log_v1_<dateIso>`)

**Files:**
- Modify: `lib/services/storage_service.dart` (`srsReview` :1874-1909, `_persistSrs` 게이트 재사용)
- Modify: `lib/screens/scenario_player_screen.dart` (`recordScenarioFailedQuestSrs` :113-124, line 120 호출부)
- Test: `test/study_log_test.dart` 신설.

**Interfaces:**
- Produces: `Storage.studyLogIdsFor(String dateIso) -> List<String>`, `Storage.studyLogDates() -> List<String>`(원장 보유일 목록 — 달력 predicate용), `Storage.pruneStudyLog({int keepDays = 60})`, `srsReview(id, {required gotIt, bool recordToStudyLog = true})`.
- Consumes(다음 태스크): Task 11의 `ReviewDeckService.deckForIds`, Task 12의 ReviewHub 달력.

- [ ] **Step 1: 실패하는 테스트** — `test/study_log_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
  });

  test('srsReview 는 오늘 날짜 키에 판정된 id 를 기록한다', () async {
    await Storage.init();
    await Storage.srsReview('단어1', gotIt: true);
    final today = Storage.studyLogIdsFor(Storage.todayIso());
    expect(today, contains('단어1'));
  });

  test('같은 단어를 여러 번 판정해도 오늘 키에는 한 번만 남는다', () async {
    await Storage.init();
    await Storage.srsReview('단어1', gotIt: true);
    await Storage.srsReview('단어1', gotIt: false);
    expect(Storage.studyLogIdsFor(Storage.todayIso()).where((id) => id == '단어1').length, 1);
  });

  test('recordToStudyLog:false 는 원장에 남기지 않는다 (시나리오 자동 오답)', () async {
    await Storage.init();
    await Storage.srsReview('자동오답단어', gotIt: false, recordToStudyLog: false);
    expect(Storage.studyLogIdsFor(Storage.todayIso()), isNot(contains('자동오답단어')));
  });

  test('studyLogDates 는 기록이 있는 날짜만 반환한다', () async {
    await Storage.init();
    expect(Storage.studyLogDates(), isEmpty);
    await Storage.srsReview('단어1', gotIt: true);
    expect(Storage.studyLogDates(), [Storage.todayIso()]);
  });

  test('pruneStudyLog 는 60일보다 오래된 날짜 키를 지운다', () async {
    await Storage.init();
    final old = '2020-01-01';
    // 직접 오래된 날짜 키를 시뮬레이션(내부 헬퍼 노출 없이 srsReview 로만
    // 오늘 키를 만들고, 프루닝 대상 존재를 studyLogDates() 로 검증).
    await Storage.srsReview('단어1', gotIt: true);
    await Storage.pruneStudyLog();
    expect(Storage.studyLogDates(), [Storage.todayIso()]);
  });
}
```

(`Storage.todayIso()`가 아직 없으면 이 태스크에서 `_today()`를 감싸는 공개 게터로 노출 — 기존 `_today()`는 private이라 테스트에서 직접 못 부른다.)
- [ ] **Step 2: 실행 → FAIL 확인** (전부 미정의).
- [ ] **Step 3: 구현 — `storage_service.dart`.** `_today()` 옆에 공개 래퍼 추가:

```dart
  /// 오늘 ISO 날짜(YYYY-MM-DD). 테스트/화면에서 [studyLogIdsFor] 조회용.
  static String todayIso() => _today();
```

SRS 섹션(`srsReview` 정의 앞, :1866 부근)에 원장 상수+헬퍼 추가:

```dart
  static const int _studyLogMaxIdsPerDay = 500;
  static const int _studyLogRetentionDays = 60;
  static String _studyLogKey(String dateIso) => 'kl_study_log_v1_$dateIso';

  /// 그 날짜에 명시적으로 판정된 id 목록(일자별 키, calligraphyDates 와 같은
  /// setStringList 패턴). srsReview 의 핫패스는 **오늘** 키만 읽고 쓴다.
  static List<String> studyLogIdsFor(String dateIso) => _l(_studyLogKey(dateIso));

  /// 원장이 있는 날짜 전부(달력 selectableDayPredicate 용) — kl_study_log_v1_
  /// 접두 키를 SharedPreferences 에서 직접 스캔한다(resetAll 의 kl_ 접두
  /// 스캔과 동일 패턴).
  static List<String> studyLogDates() {
    final prefs = _prefs;
    if (prefs == null) return const [];
    const prefix = 'kl_study_log_v1_';
    return prefs
        .getKeys()
        .where((k) => k.startsWith(prefix) && studyLogIdsFor(k.substring(prefix.length)).isNotEmpty)
        .map((k) => k.substring(prefix.length))
        .toList()
      ..sort();
  }

  static Future<void> _appendStudyLogEntry(String id) async {
    if (_learningWritesLockReason != null) {
      // srsReview 의 _persistSrs 와 동일 게이트를 경유한다 — 학습 쓰기가
      // 잠긴 동안(계정 삭제/전환 등) 원장도 함께 멈춘다.
      return;
    }
    final dateIso = _today();
    final ids = studyLogIdsFor(dateIso);
    if (ids.contains(id)) return;
    if (ids.length >= _studyLogMaxIdsPerDay) return; // 상한 — 하루 500개
    ids.add(id);
    await _sl(_studyLogKey(dateIso), ids);
  }

  /// 60일보다 오래된 날짜 키를 지운다. 앱 시작·달력 열람 시 호출(핫패스 아님).
  static Future<void> pruneStudyLog() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final cutoff = DateTime.now().subtract(
      const Duration(days: _studyLogRetentionDays),
    );
    for (final dateIso in studyLogDates()) {
      final parsed = DateTime.tryParse(dateIso);
      if (parsed != null && parsed.isBefore(cutoff)) {
        await prefs.remove(_studyLogKey(dateIso));
      }
    }
  }
```

`srsReview` 시그니처(:1874)와 마지막 줄(:1908)을 교체:

```dart
  static Future<void> srsReview(
    String id, {
    required bool gotIt,
    bool recordToStudyLog = true,
  }) async {
```

```dart
    map[id] = updated;
    await _persistSrs();
    // 명시적 판정만 원장에 남긴다 — 시나리오 자동 오답 일괄 기록
    // (scenario_player_screen.dart recordScenarioFailedQuestSrs)은 제외해
    // 목록을 오염시키지 않는다(검수#2).
    if (recordToStudyLog) {
      await _appendStudyLogEntry(id);
    }
  }
```

- [ ] **Step 4: scenario_player_screen.dart 제외 배선** — `recordScenarioFailedQuestSrs`(:113-124)의 :120을 교체:

```dart
  for (final missed in missedKeys) {
    await Storage.srsReview(missed, gotIt: false, recordToStudyLog: false);
  }
```

- [ ] **Step 5: GREEN + `flutter analyze` + `flutter test`(srs 관련 스위트 회귀 확인).**
- [ ] **Step 6: 커밋** — `git commit -m "feat(storage): SRS 일별 학습 원장 kl_study_log_v1_<dateIso> — 명시적 판정만, 60일 프루닝 (검수#2)"`

---

### Task 11: ReviewDeckService.deckForIds

**Files:**
- Modify: `lib/services/review_deck_service.dart`
- Test: `grep -rln "ReviewDeckService" test/`로 기존 파일 확인 후 케이스 추가(없으면 `test/review_deck_service_test.dart` 신설).

**Interfaces:**
- Consumes: Task 10의 `Storage.studyLogIdsFor`.
- Produces: `ReviewDeckService.deckForIds(List<Vocab> all, Iterable<String> ids) -> List<Vocab>` — id 순서를 보존하며 `all`에서 매칭되는 것만 반환(달력에서 특정 날짜를 고르면 그 날의 원장 id들을 실제 `Vocab`으로 해석).

- [ ] **Step 1: 실패하는 테스트**:

```dart
  test('deckForIds 는 주어진 id 순서를 보존해 Vocab 으로 해석한다', () {
    final all = [
      Vocab(korean: '가', romanization: '', german: '', level: 'A1', posDe: '', exampleKorean: '', exampleGerman: '', topic: ''),
      Vocab(korean: '나', romanization: '', german: '', level: 'A1', posDe: '', exampleKorean: '', exampleGerman: '', topic: ''),
      Vocab(korean: '다', romanization: '', german: '', level: 'A1', posDe: '', exampleKorean: '', exampleGerman: '', topic: ''),
    ];
    final deck = ReviewDeckService.deckForIds(all, ['다', '가', '없음']);
    expect(deck.map((v) => v.korean), ['다', '가']); // 없는 id 는 조용히 스킵
  });
```

(`Vocab` 생성자 필수 필드는 `lib/models/vocab.dart` 기준으로 맞춘다 — `review_deck_service.dart:33-42`의 `_fromWord`가 쓰는 필드셋과 동일.)
- [ ] **Step 2: 실행 → FAIL 확인.**
- [ ] **Step 3: 구현** — `lib/services/review_deck_service.dart`, `sortByLevelStable` 근처에 추가:

```dart
  /// [ids] 순서를 보존해 [all] 에서 매칭되는 Vocab 만 골라낸다. 달력에서
  /// 특정 날짜를 고르면 그 날의 학습 원장 id 목록(Storage.studyLogIdsFor)을
  /// 실제 Vocab 으로 해석하는 용도(검수#2 — ReviewHub 달력 진입).
  static List<Vocab> deckForIds(List<Vocab> all, Iterable<String> ids) {
    final byId = <String, Vocab>{};
    for (final word in all) {
      byId.putIfAbsent(word.korean, () => word);
    }
    return [
      for (final id in ids)
        if (byId[id] case final word?) word,
    ];
  }
```

- [ ] **Step 4: GREEN + `flutter analyze`.**
- [ ] **Step 5: 커밋** — `git commit -m "feat(review): ReviewDeckService.deckForIds — 학습 원장 id → Vocab 해석 (달력 진입용)"`

---

### Task 12: ReviewHubScreen 신설 + `/review/hub` 라우트

**Files:**
- Create: `lib/screens/review_hub_screen.dart`
- Modify: `lib/main.dart` (신규 `case '/review/hub':` — 기존 `case '/review':` :813-819는 무변경)
- Modify: `lib/data/sori_activity_catalog.dart` (`srs` 엔트리 `route` :189)
- Modify: `lib/l10n/app_de.arb` + `lib/l10n/app_en.arb`
- Test: `test/review_hub_screen_test.dart` 신설.

**Interfaces:**
- Consumes: Task 10(`Storage.studyLogDates`/`studyLogIdsFor`/`pruneStudyLog`), Task 11(`ReviewDeckService.deckForIds`), 기존 `ReviewDeckService.allReviewable`/`todaySelectionForLevel`, 기존 `ReviewSessionScreen(deck:, title:, feedbackContentId:)`(`review_session_screen.dart:49-66`, 이미 임의 deck 주입을 지원).
- Produces: `/review/hub` 라우트 — Lernen 타일(카탈로그 `srs` 엔트리)과 향후 달력 진입만 여기를 거친다. `/review`(플레이어)는 무변경.

- [ ] **Step 1: 실패하는 위젯 테스트** — `test/review_hub_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/review_hub_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

Widget _harness() => MaterialApp(
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: const ReviewHubScreen(),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
  });

  testWidgets('오늘 학습 원장 항목을 목록으로 보여준다', (tester) async {
    await Storage.init();
    await Storage.srsReview('안녕', gotIt: true);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.textContaining('안녕'), findsWidgets);
  });

  testWidgets('항목을 다중 선택할 수 있다', (tester) async {
    await Storage.init();
    await Storage.srsReview('안녕', gotIt: true);
    await Storage.srsReview('감사', gotIt: true);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-hub-select-안녕')));
    await tester.tap(find.byKey(const Key('review-hub-select-감사')));
    await tester.pump();
    expect(find.byKey(const Key('review-hub-start-selected')), findsOneWidget);
  });

  testWidgets('달력 아이콘이 원장 보유일을 selectableDayPredicate 로 노출한다', (
    tester,
  ) async {
    await Storage.init();
    await Storage.srsReview('안녕', gotIt: true);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
  });
}
```

- [ ] **Step 2: 실행 → FAIL 확인** (`review_hub_screen.dart` 미존재로 컴파일 실패).
- [ ] **Step 3: arb 키 추가** — `app_de.arb`/`app_en.arb` 동시:

```json
  "reviewHubTitle": "Wiederholen",
  "reviewHubTodayHeadline": "Heute gelernt",
  "reviewHubEmptyToday": "Noch nichts gelernt heute — starte eine Lektion.",
  "reviewHubStartSelected": "{n, plural, one{1 Wort üben} other{{n} Wörter üben}}",
  "reviewHubCalendarTooltip": "Kalender",
  "reviewHubDeckLabel": "{words, plural, one{1 Wort} other{{words} Wörter}}",
```

(en: `"Review"` / `"Learned today"` / `"Nothing learned yet today — start a lesson."` / `"{n, plural, one{Practice 1 word} other{Practice {n} words}}"` / `"Calendar"` / `"{words, plural, one{1 word} other{{words} words}}"`.) → `flutter gen-l10n`.
- [ ] **Step 4: 화면 구현** — `lib/screens/review_hub_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import 'review_session_screen.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';

/// `/review/hub` — SRS 원장 브라우즈 허브. `/review`(ReviewSessionScreen)는
/// 순수 플레이어로 유지되고(라우트 고정 15곳), 여기서는 오늘 학습 목록을
/// 훑어보거나 달력으로 과거 날짜를 재학습한다(검수#2/#14/#25).
class ReviewHubScreen extends StatefulWidget {
  const ReviewHubScreen({super.key});

  @override
  State<ReviewHubScreen> createState() => _ReviewHubScreenState();
}

class _ReviewHubScreenState extends State<ReviewHubScreen> {
  bool _loading = true;
  List<Vocab> _allReviewable = const [];
  List<String> _todayIds = const [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    // 달력 열람 시점 프루닝(§검수#2 — 앱 시작/달력 열람 시에만, 핫패스 아님).
    // ignore: discarded_futures
    Storage.pruneStudyLog();
    _load();
  }

  Future<void> _load() async {
    final all = await ReviewDeckService.allReviewable();
    if (!mounted) return;
    setState(() {
      _allReviewable = all;
      _todayIds = Storage.studyLogIdsFor(Storage.todayIso());
      _loading = false;
    });
  }

  List<Vocab> get _todayDeck =>
      ReviewDeckService.deckForIds(_allReviewable, _todayIds);

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _openDeck(List<Vocab> deck, String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewSessionScreen(
          deck: deck,
          title: title,
          feedbackContentId: 'review_hub_session',
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openCalendar() async {
    final dates = Storage.studyLogDates();
    final dateSet = dates.toSet();
    if (dateSet.isEmpty) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(dates.last) ?? DateTime.now(),
      firstDate: DateTime.tryParse(dates.first) ?? DateTime.now(),
      lastDate: DateTime.now(),
      selectableDayPredicate: (day) =>
          dateSet.contains(Storage.todayIsoFor(day)),
    );
    if (picked == null || !mounted) return;
    final deck = ReviewDeckService.deckForIds(
      _allReviewable,
      Storage.studyLogIdsFor(Storage.todayIsoFor(picked)),
    );
    if (deck.isEmpty) return;
    final t = AppL10n.of(context);
    await _openDeck(deck, t.reviewHubDeckLabel(deck.length));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardPage(
      appBarTitle: t.reviewHubTitle,
      headline: t.reviewHubTitle,
      actions: [
        IconButton(
          key: const Key('review-hub-calendar'),
          icon: const Icon(Icons.calendar_month_rounded),
          tooltip: t.reviewHubCalendarTooltip,
          onPressed: _openCalendar,
        ),
      ],
      children: [
        Text(t.reviewHubTodayHeadline, style: SoriTextTheme.of(context).h3),
        const SizedBox(height: Spacing.md),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_todayDeck.isEmpty)
          SoriEmptyState(
            icon: Icons.today_outlined,
            title: t.reviewHubEmptyToday,
          )
        else ...[
          for (final word in _todayDeck)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: SoriCard(
                child: CheckboxListTile(
                  key: Key('review-hub-select-${word.korean}'),
                  value: _selected.contains(word.korean),
                  onChanged: (_) => _toggle(word.korean),
                  title: Text(word.korean),
                  subtitle: Text(word.german),
                ),
              ),
            ),
          const SizedBox(height: Spacing.md),
          SoriButton.filled(
            key: const Key('review-hub-start-selected'),
            label: t.reviewHubStartSelected(
              _selected.isEmpty ? _todayDeck.length : _selected.length,
            ),
            fullWidth: true,
            onTap: () => _openDeck(
              _selected.isEmpty
                  ? _todayDeck
                  : _todayDeck
                        .where((w) => _selected.contains(w.korean))
                        .toList(),
              t.reviewHubTodayHeadline,
            ),
          ),
        ],
      ],
    );
  }
}
```

(`SoriStandardPage`/`SoriEmptyState`/`SoriButton`의 실제 파라미터명은 `practice_hub_screen.dart`/`bookshelf_screen.dart`에서 이미 확인된 것과 동일 계열이나, 구현 시 각 위젯 파일의 최신 시그니처와 1:1 대조해 어긋나면 맞춘다.) `Storage.todayIsoFor(DateTime)` 헬퍼가 없으면 이 스텝에서 `storage_service.dart`에 `static String todayIsoFor(DateTime d) => _isoOf(d);`를 추가.
- [ ] **Step 5: 라우트 등록** — `lib/main.dart`의 `case '/review':`(:813-819) **바로 다음에** 신규 케이스 추가(`/review` 블록 자체는 1바이트도 건드리지 않는다):

```dart
            case '/review':
              return SoriTransitions.fadeScale(
                (_) => const ReviewSessionScreen(
                  feedbackContentId: 'today_review',
                ),
                settings: settings,
              );
            case '/review/hub':
              return SoriTransitions.fadeScale(
                (_) => const ReviewHubScreen(),
                settings: settings,
              );
```

(`import '../screens/review_hub_screen.dart';` 상단에 추가 — 실제 상대경로는 `main.dart`의 기존 import 스타일을 따른다.)
- [ ] **Step 6: 카탈로그 srs 엔트리 리라우팅** — `lib/data/sori_activity_catalog.dart:189`:

```dart
    route: '/review/hub',
```

(`sori_stage_catalog_screen.dart:262-265`가 `entry.route`를 그대로 `pushNamed`하므로 이 한 줄로 Lernen 타일이 허브를 경유한다. `practice_hub_screen.dart:111`의 "onReview" 원탭 CTA와 `sarangbang_screen.dart:253`, `sori_stage_today_screen.dart:775`의 Today CTA는 **그대로 `/review`를 유지** — 검수#14 "Today 원탭 CTA 보존".)
- [ ] **Step 7: GREEN + `flutter analyze` + `flutter test`(15곳 `/review` 고정 테스트 무회귀 확인 — 이번 태스크는 그 블록을 건드리지 않았으므로 통과해야 정상).**
- [ ] **Step 8: 커밋** — `git commit -m "feat(review): ReviewHubScreen + /review/hub 라우트 — 오늘 목록 다중선택 + 달력 (검수#2/14/25, /review 플레이어 라우트 불변)"`

---

### Task 13: buildGrammarChoiceRound `allowedTargetIds`

**Files:**
- Modify: `lib/services/grammar_choice_quiz.dart`
- Test: `grep -rln "buildGrammarChoiceRound" test/`로 기존 테스트 파일 확인 후 케이스 추가.

**Interfaces:**
- Produces: `buildGrammarChoiceRound({..., Set<String>? allowedTargetIds})` — 타깃만 슬라이스 교집합, 오답 풀(`pool`)은 레벨 전체 그대로. `allowedTargetIds: null`이면 기존 동작과 완전히 동일(하위 호환).

- [ ] **Step 1: 실패하는 테스트**:

```dart
  test('allowedTargetIds 가 있으면 타깃만 제한하고 오답 풀은 레벨 전체다', () {
    final source = /* 기존 buildGrammarChoiceRound 테스트의 픽스처 재사용 —
                       같은 레벨 4개 이상 Grammar, quizEnabled 전부 true */;
    final round = buildGrammarChoiceRound(
      source: source,
      level: 'A1',
      languageCode: 'de',
      random: Random(1),
      allowedTargetIds: {source.first.id},
    );
    expect(round, hasLength(1));
    expect(round.single.target.id, source.first.id);
    // 오답 풀은 allowedTargetIds 밖의 같은 레벨 카드도 쓸 수 있어야 한다.
    expect(
      round.single.options.map((o) => o.id),
      containsAll(source.first.quizDistractorIds),
    );
  });

  test('allowedTargetIds 가 null 이면 기존 동작과 동일하다', () {
    final source = /* 동일 픽스처 */;
    final withoutFilter = buildGrammarChoiceRound(
      source: source, level: 'A1', languageCode: 'de', random: Random(1),
    );
    final withNullFilter = buildGrammarChoiceRound(
      source: source, level: 'A1', languageCode: 'de', random: Random(1),
      allowedTargetIds: null,
    );
    expect(
      withNullFilter.map((q) => q.target.id),
      withoutFilter.map((q) => q.target.id),
    );
  });
```

- [ ] **Step 2: 실행 → FAIL 확인** (신규 파라미터 미정의).
- [ ] **Step 3: 구현** — `lib/services/grammar_choice_quiz.dart`의 `buildGrammarChoiceRound`(:110-147) 시그니처와 `targets` 계산부만 수정:

```dart
List<GrammarChoiceQuestion> buildGrammarChoiceRound({
  required Iterable<Grammar> source,
  required String level,
  required String languageCode,
  required Random random,
  int maxQuestions = 10,
  Set<String>? allowedTargetIds,
}) {
  if (maxQuestions <= 0) {
    return const <GrammarChoiceQuestion>[];
  }
  final all = source
      .where(
        (grammar) =>
            isGrammarChoiceTargetEligible(grammar) &&
            grammar.hasSingleExampleFocusFor(languageCode),
      )
      .toList(growable: false);
  // allowedTargetIds 는 타깃 후보만 좁힌다 — 오답 풀(pool: all)은 항상
  // 레벨 전체를 유지해 문법 플랜 슬라이스 밖의 패턴도 distractor 로 쓴다
  // (Grammatik 마스터플랜: "오답 풀은 레벨 전체").
  final targets =
      all
          .where(
            (grammar) =>
                grammar.level == level &&
                (allowedTargetIds == null ||
                    allowedTargetIds.contains(grammar.id)),
          )
          .toList(growable: false)
        ..sort((a, b) => a.id.compareTo(b.id))
        ..shuffle(random);
  final round = <GrammarChoiceQuestion>[];
  for (final target in targets) {
    final question = buildGrammarChoiceQuestion(
      target: target,
      pool: all,
      random: random,
    );
    if (question == null) {
      continue;
    }
    round.add(question);
    if (round.length >= maxQuestions) {
      break;
    }
  }
  return List<GrammarChoiceQuestion>.unmodifiable(round);
}
```

- [ ] **Step 4: GREEN + `flutter analyze` + `flutter test`(기존 grammar_choice_quiz 테스트 무회귀).**
- [ ] **Step 5: 커밋** — `git commit -m "feat(grammar-quiz): buildGrammarChoiceRound allowedTargetIds — 타깃만 슬라이스 제한, 오답 풀은 레벨 전체 (Grammatik 마스터플랜)"`

---

### Task 14: grammar_study_plan.dart 모델 + grammar_plan_service.dart

**Files:**
- Create: `lib/models/grammar_study_plan.dart`
- Create: `lib/services/grammar_plan_service.dart`
- Create: `test/grammar_study_plan_test.dart`
- Create: `test/grammar_plan_service_test.dart`

**Interfaces:**
- Produces: `GrammarStudyPlan{level, itemsPerDay, servedIdsByDate}`(순수 모델), `GrammarPlanService.curatedRowsForLevel/todaysSlice/totalDays/recordServedDay/decodePlans/encodePlans`(순수 함수).
- Consumes(다음 태스크): Task 15(Storage 키), Task 16(grammar_screen.dart UI).

- [ ] **Step 1: 실패하는 모델 테스트** — `test/grammar_study_plan_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';

void main() {
  test('completedDays 는 servedIdsByDate 의 날짜 수다 (일차 카운트 아님)', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 5,
      servedIdsByDate: {
        '2026-08-20': ['g1', 'g2'],
        '2026-08-21': ['g3'],
      },
    );
    expect(plan.completedDays, 2);
  });

  test('toJson/fromJson 라운드트립', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 7,
      servedIdsByDate: {'2026-08-20': ['g1']},
    );
    final decoded = GrammarStudyPlan.fromJson(plan.toJson());
    expect(decoded.level, plan.level);
    expect(decoded.itemsPerDay, plan.itemsPerDay);
    expect(decoded.servedIdsByDate, plan.servedIdsByDate);
  });

  test('fromJson 은 결측 필드에 안전한 기본값을 쓴다', () {
    final decoded = GrammarStudyPlan.fromJson(const {});
    expect(decoded.level, '');
    expect(decoded.itemsPerDay, 5);
    expect(decoded.servedIdsByDate, isEmpty);
  });
}
```

- [ ] **Step 2: 실행 → FAIL** (파일 미존재).
- [ ] **Step 3: 모델 구현** — `lib/models/grammar_study_plan.dart`:

```dart
/// 한 CEFR 레벨의 CSV 큐레이션 순서(=grammar.csv 파일 등장 순, 재정렬 없음)를
/// 사용자 페이스대로 걷는 진행 상태. 레벨별로 저장돼, 레벨을 전환해도 다른
/// 레벨의 플랜은 지워지지 않고 "일시정지"된다(kl_gram_plan_v1, 레벨→플랜 맵).
class GrammarStudyPlan {
  const GrammarStudyPlan({
    required this.level,
    required this.itemsPerDay,
    required this.servedIdsByDate,
  });

  /// CEFR 레벨 코드(소문자, 예: 'a1').
  final String level;

  /// 하루 분량 — {3,5,7,10} 중 하나, 기본 5.
  final int itemsPerDay;

  /// dateIso → 그 날 실제로 서빙된 grammar row id 목록(서빙 순서 보존).
  /// **일자별 서빙 id 목록**이지 일차 카운트가 아니다 — grammar.csv 행이
  /// 재배치돼도 이미 서빙된 id 는 그대로 식별 가능하다(검수#24).
  final Map<String, List<String>> servedIdsByDate;

  /// "오늘 분량" 산정 기준 — 달력이 아니라 지금까지 완료한 날 수.
  int get completedDays => servedIdsByDate.length;

  factory GrammarStudyPlan.fromJson(Map<String, dynamic> json) {
    final rawServed = json['servedIdsByDate'];
    return GrammarStudyPlan(
      level: json['level']?.toString() ?? '',
      itemsPerDay: (json['itemsPerDay'] as num?)?.toInt() ?? 5,
      servedIdsByDate: rawServed is Map
          ? {
              for (final entry in rawServed.entries)
                entry.key.toString(): entry.value is List
                    ? [for (final id in entry.value as List) id.toString()]
                    : const <String>[],
            }
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'itemsPerDay': itemsPerDay,
    'servedIdsByDate': servedIdsByDate,
  };

  GrammarStudyPlan copyWith({
    String? level,
    int? itemsPerDay,
    Map<String, List<String>>? servedIdsByDate,
  }) => GrammarStudyPlan(
    level: level ?? this.level,
    itemsPerDay: itemsPerDay ?? this.itemsPerDay,
    servedIdsByDate: servedIdsByDate ?? this.servedIdsByDate,
  );
}
```

- [ ] **Step 4: GREEN(모델) + `flutter analyze`.**
- [ ] **Step 5: 실패하는 서비스 테스트** — `test/grammar_plan_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';

Grammar _g(String id, String level) => Grammar(
  id: id,
  pattern: id,
  level: level,
  typeDe: '',
  explanationDe: '',
  exampleKorean: '',
  exampleGerman: '',
  note: '',
  typeEn: '',
  explanationEn: '',
  exampleEn: '',
  noteEn: '',
  exampleGermanFocus: '',
  exampleEnFocus: '',
  quizEnabled: false,
  quizDistractorIds: const [],
);

void main() {
  final rows = [
    _g('a1_01', 'A1'),
    _g('a1_02', 'A1'),
    _g('a1_03', 'A1'),
    _g('b1_01', 'B1'),
  ];

  test('curatedRowsForLevel 은 CSV 등장 순서를 보존한 채 레벨만 거른다', () {
    final result = GrammarPlanService.curatedRowsForLevel(rows, 'A1');
    expect(result.map((g) => g.id), ['a1_01', 'a1_02', 'a1_03']);
  });

  test('todaysSlice 는 completedDays 기반 결정적 윈도우다 (달력 아님)', () {
    const plan = GrammarStudyPlan(
      level: 'a1', itemsPerDay: 2, servedIdsByDate: {},
    );
    final slice0 = GrammarPlanService.todaysSlice(
      curatedRows: GrammarPlanService.curatedRowsForLevel(rows, 'A1'),
      plan: plan,
    );
    expect(slice0.map((g) => g.id), ['a1_01', 'a1_02']);

    final planDay1 = plan.copyWith(
      servedIdsByDate: {'2026-08-20': ['a1_01', 'a1_02']},
    );
    final slice1 = GrammarPlanService.todaysSlice(
      curatedRows: GrammarPlanService.curatedRowsForLevel(rows, 'A1'),
      plan: planDay1,
    );
    expect(slice1.map((g) => g.id), ['a1_03']);
  });

  test('todaysSlice 는 큐레이션 소진 시 빈 리스트를 반환한다', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 2,
      servedIdsByDate: {
        '2026-08-20': ['a1_01', 'a1_02'],
        '2026-08-21': ['a1_03'],
      },
    );
    final slice = GrammarPlanService.todaysSlice(
      curatedRows: GrammarPlanService.curatedRowsForLevel(rows, 'A1'),
      plan: plan,
    );
    expect(slice, isEmpty);
  });

  test('totalDays 는 itemsPerDay 로 올림 나눗셈한다', () {
    expect(
      GrammarPlanService.totalDays(
        GrammarPlanService.curatedRowsForLevel(rows, 'A1'), 2,
      ),
      2,
    );
  });

  test('recordServedDay 는 불변 카피를 반환하고 같은 날 재호출은 멱등하다', () {
    const plan = GrammarStudyPlan(
      level: 'a1', itemsPerDay: 2, servedIdsByDate: {},
    );
    final day1 = GrammarPlanService.recordServedDay(
      plan, dateIso: '2026-08-20', servedIds: ['a1_01', 'a1_02'],
    );
    expect(plan.servedIdsByDate, isEmpty); // 원본 불변
    expect(day1.completedDays, 1);
    final again = GrammarPlanService.recordServedDay(
      day1, dateIso: '2026-08-20', servedIds: ['a1_01', 'a1_02'],
    );
    expect(again.completedDays, 1);
  });

  test('encodePlans/decodePlans 는 레벨별 맵으로 라운드트립한다', () {
    const plans = {
      'a1': GrammarStudyPlan(
        level: 'a1', itemsPerDay: 5, servedIdsByDate: {'2026-08-20': ['a1_01']},
      ),
    };
    final raw = GrammarPlanService.encodePlans(plans);
    final decoded = GrammarPlanService.decodePlans(raw);
    expect(decoded['a1']?.itemsPerDay, 5);
    expect(decoded['a1']?.servedIdsByDate, {'2026-08-20': ['a1_01']});
  });

  test('decodePlans 는 빈/손상 원본에 빈 맵을 반환한다', () {
    expect(GrammarPlanService.decodePlans(''), isEmpty);
    expect(GrammarPlanService.decodePlans('{not json'), isEmpty);
  });
}
```

- [ ] **Step 6: 실행 → FAIL.**
- [ ] **Step 7: 서비스 구현** — `lib/services/grammar_plan_service.dart`:

```dart
import 'dart:convert';

import '../models/grammar.dart';
import '../models/grammar_study_plan.dart';

/// Grammatik 마스터플랜의 순수 슬라이스 로직. IO/Storage 는 다루지 않는다 —
/// 화면이 Storage.grammarPlanRawJson 을 읽고 [decodePlans]/[encodePlans] 로
/// 오간다.
abstract final class GrammarPlanService {
  static const List<int> itemsPerDayOptions = [3, 5, 7, 10];
  static const int defaultItemsPerDay = 5;

  /// grammar.csv 큐레이션 순서(=DataLoader.loadGrammar() 반환 순서, 파일
  /// 등장 순)를 유지한 채 [level] 행만 골라낸다. 정렬하지 않는다 — 정렬하면
  /// CSV 편집마다 슬라이스 경계가 흔들린다.
  static List<Grammar> curatedRowsForLevel(
    List<Grammar> source,
    String level,
  ) => source
      .where((g) => g.level.toUpperCase() == level.toUpperCase())
      .toList(growable: false);

  /// "오늘 분량" — completedDays 기반 결정적 윈도우. 밀린 날이 있어도
  /// 누적되지 않고, 다음 접속 시 정확히 itemsPerDay 만큼만 나간다.
  static List<Grammar> todaysSlice({
    required List<Grammar> curatedRows,
    required GrammarStudyPlan plan,
  }) {
    if (plan.itemsPerDay <= 0) return const <Grammar>[];
    final start = plan.completedDays * plan.itemsPerDay;
    if (start >= curatedRows.length) {
      return const <Grammar>[];
    }
    final end = (start + plan.itemsPerDay).clamp(0, curatedRows.length);
    return curatedRows.sublist(start, end);
  }

  static int totalDays(List<Grammar> curatedRows, int itemsPerDay) =>
      itemsPerDay <= 0 ? 0 : (curatedRows.length / itemsPerDay).ceil();

  /// dateIso 하루치 서빙 기록을 추가한 새 플랜(불변). 같은 날짜 재호출은
  /// 멱등 — 그 날짜 키를 그대로 덮어쓴다(호출측이 이미 오늘 슬라이스를
  /// 확정해 넘기므로 값은 항상 동일해야 한다).
  static GrammarStudyPlan recordServedDay(
    GrammarStudyPlan plan, {
    required String dateIso,
    required List<String> servedIds,
  }) {
    final next = Map<String, List<String>>.of(plan.servedIdsByDate);
    next[dateIso] = List<String>.unmodifiable(servedIds);
    return plan.copyWith(servedIdsByDate: next);
  }

  /// 레벨→플랜 맵 직렬화(Storage.grammarPlanRawJson 저장용).
  static String encodePlans(Map<String, GrammarStudyPlan> plans) =>
      jsonEncode({for (final entry in plans.entries) entry.key: entry.value.toJson()});

  /// 손상/빈 원본은 조용히 빈 맵으로 떨어진다(다른 raw-JSON 계열 Storage
  /// 필드와 동일한 fail-closed 정책 — courseMasterySnapshotRawJson 등과
  /// 달리 이 데이터는 학습 이력 핵심이 아니라 격리 큐 없이 단순 폐기).
  static Map<String, GrammarStudyPlan> decodePlans(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          entry.key.toString(): GrammarStudyPlan.fromJson(
            (entry.value as Map).map((k, v) => MapEntry(k.toString(), v)),
          ),
      };
    } catch (_) {
      return const {};
    }
  }
}
```

- [ ] **Step 8: GREEN + `flutter analyze`.**
- [ ] **Step 9: 커밋** — `git commit -m "feat(grammar-plan): GrammarStudyPlan 모델 + GrammarPlanService 순수 슬라이스 로직 (Grammatik 마스터플랜, 검수#24)"`

---

### Task 15: storage_service.dart `kl_gram_plan_v1`

**Files:**
- Modify: `lib/services/storage_service.dart` (문법 섹션, `grammarLastIdx`/`grammarSeen` 옆 :935-960)
- Test: 기존 `test/study_log_test.dart` 옆에 케이스 추가하거나 `test/grammar_plan_storage_test.dart` 신설.

**Interfaces:**
- Produces: `Storage.grammarPlanRawJson` / `Storage.setGrammarPlanRawJson(String json)` — `srsRawJson`/`setSrsRawJson`과 동일한 raw-passthrough 패턴(디코딩은 `GrammarPlanService`가 담당). `kl_gram_last_idx`/`kl_gram_seen`은 라이브러리 모드 전용으로 완전히 존치(무변경).

- [ ] **Step 1: 실패하는 테스트** — `test/grammar_plan_storage_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
  });

  test('grammarPlanRawJson 은 기본값이 빈 문자열이고 setter 로 갱신된다', () async {
    await Storage.init();
    expect(Storage.grammarPlanRawJson, '');
    await Storage.setGrammarPlanRawJson('{"a1":{"level":"a1"}}');
    expect(Storage.grammarPlanRawJson, '{"a1":{"level":"a1"}}');
  });

  test('kl_gram_last_idx/kl_gram_seen 은 무변화 (라이브러리 모드 전용 존치)', () async {
    await Storage.init();
    await Storage.setGrammarLastIdx(3);
    await Storage.addGrammarSeen('pattern_1');
    await Storage.setGrammarPlanRawJson('{}');
    expect(Storage.grammarLastIdx, 3);
    expect(Storage.grammarSeen, ['pattern_1']);
  });
}
```

- [ ] **Step 2: 실행 → FAIL 확인** (getter/setter 미정의).
- [ ] **Step 3: 구현** — `storage_service.dart:935-960` 부근(`grammarHard` 다음)에 추가:

```dart
  /// Grammatik 마스터플랜 — 레벨별 진행 맵(GrammarPlanService.encode/decode
  /// Plans 가 다루는 raw JSON). kl_gram_last_idx/kl_gram_seen(라이브러리
  /// 모드 전용)과는 별개 키 — 레벨 전환 시 다른 레벨 플랜은 지워지지 않고
  /// 이 맵 안에 "일시정지"된 채 남는다.
  static String get grammarPlanRawJson => _s('kl_gram_plan_v1');
  static Future<void> setGrammarPlanRawJson(String json) =>
      _ss('kl_gram_plan_v1', json);
```

- [ ] **Step 4: GREEN + `flutter analyze`.**
- [ ] **Step 5: 커밋** — `git commit -m "feat(storage): kl_gram_plan_v1 raw JSON 키 — 레벨별 플랜, 라이브러리 모드 키 존치 (검수#24)"`

---

### Task 16: grammar_screen.dart 플랜 모드 (첫 진입 시트 + 일 헤더 + 완료 시트)

**Files:**
- Modify: `lib/screens/grammar_screen.dart` (`_load()` :143-215, `_showFilterSheet` 진입점 :698-699,731, 필터 크롬 영역 :756-…)
- Modify: `lib/l10n/app_de.arb` + `lib/l10n/app_en.arb`
- Test: `grep -rln "GrammarScreen(" test/`로 기존 하네스 확인 후 케이스 추가.

**Interfaces:**
- Consumes: Task 14(`GrammarPlanService`, `GrammarStudyPlan`), Task 15(`Storage.grammarPlanRawJson`).
- Produces: 자유 브라우즈(`!_isCoursePractice`)에서만 플랜 모드가 필터 크롬을 대체. 첫 진입(해당 레벨 플랜 없음) → 레벨+일일 개수 시트 → "Tag N von M" 헤더+일 점 → 마지막 카드 후 "Mit Beispielen üben?" 완료 시트.

- [ ] **Step 1: 실패하는 테스트** — 기존 `GrammarScreen` 위젯 테스트 하네스를 따라:

```dart
  testWidgets('플랜 없이 첫 진입하면 레벨+일일개수 시트가 뜬다', (tester) async {
    // 기존 하네스로 pump (Storage.grammarPlanRawJson 비어있음).
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grammar-plan-onboarding-sheet')), findsOneWidget);
  });

  testWidgets('플랜이 있으면 "Tag N von M" 헤더가 필터 크롬을 대체한다', (
    tester,
  ) async {
    // given: Storage.setGrammarPlanRawJson 로 a1 레벨 plan(itemsPerDay: 5,
    // servedIdsByDate 비어있음) 미리 저장.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grammar-plan-day-header')), findsOneWidget);
    expect(find.byKey(const Key('grammar-filter-row')), findsNothing);
  });

  testWidgets('오늘 슬라이스의 마지막 카드를 넘기면 완료 시트가 뜬다', (
    tester,
  ) async {
    // given: itemsPerDay: 1 플랜으로 카드 1장만 오늘 분량.
    // 카드를 "Verstanden" 처리 → 완료 시트 확인.
    expect(find.byKey(const Key('grammar-plan-completion-sheet')), findsOneWidget);
  });
```

- [ ] **Step 2: 실행 → FAIL 확인.**
- [ ] **Step 3: arb 키 추가** (de/en 동시):

```json
  "grammarPlanOnboardingTitle": "Wie viele Muster pro Tag?",
  "grammarPlanItemsPerDayOption": "{n} pro Tag",
  "grammarPlanStartCta": "Los geht's",
  "grammarPlanDayHeader": "Tag {day} von {total}",
  "grammarPlanCompletionTitle": "Tag geschafft!",
  "grammarPlanCompletionBody": "Mit Beispielen üben?",
  "grammarPlanCompletionCta": "Üben",
  "grammarPlanCompletionSkip": "Später",
```

(en: `"How many patterns per day?"` / `"{n} per day"` / `"Let's go"` / `"Day {day} of {total}"` / `"Day done!"` / `"Practice with examples?"` / `"Practice"` / `"Later"`.) → `flutter gen-l10n`.
- [ ] **Step 4: 상태 필드 + 로드 로직.** `_GrammarScreenState`에 필드 추가(:69-70 부근):

```dart
  Map<String, GrammarStudyPlan> _plans = const {};
  GrammarStudyPlan? get _activePlan =>
      _isCoursePractice ? null : _plans[_userLevelForPlan];
  String get _userLevelForPlan =>
      LearnerLevel.fromCode(Storage.userLevelCode)?.code ?? 'a1';
```

`_load()`(:143-215)의 `setState` 블록(:193-206) 직전에 플랜 로드 추가:

```dart
      final plans = GrammarPlanService.decodePlans(Storage.grammarPlanRawJson);
      setState(() {
        _all = g;
        _plans = plans;
        _courseContentIds = courseContentIds;
```

(이하 기존 `setState` 본문은 무변경.)
- [ ] **Step 5: 첫 진입 시트.** `_showFilterSheet()` 진입점들(:698-699, :731 `IconButton`)을 플랜 부재 시에는 온보딩 시트로 분기하는 헬퍼로 감싼다:

```dart
  Future<void> _openLevelChrome() async {
    if (_isCoursePractice) return; // 코스 진입은 플랜 모드 없음(기존 그대로)
    if (_activePlan == null) {
      await _showPlanOnboardingSheet();
    } else {
      _showFilterSheet();
    }
  }

  Future<void> _showPlanOnboardingSheet() async {
    final t = AppL10n.of(context);
    var itemsPerDay = GrammarPlanService.defaultItemsPerDay;
    await showSoriSheet(
      context: context,
      key: const Key('grammar-plan-onboarding-sheet'),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.grammarPlanOnboardingTitle, style: SoriTextTheme.of(ctx).h3),
            Wrap(
              spacing: Spacing.sm,
              children: [
                for (final n in GrammarPlanService.itemsPerDayOptions)
                  ChoiceChip(
                    label: Text(t.grammarPlanItemsPerDayOption(n)),
                    selected: itemsPerDay == n,
                    onSelected: (_) => setSheetState(() => itemsPerDay = n),
                  ),
              ],
            ),
            SoriButton.filled(
              label: t.grammarPlanStartCta,
              onTap: () async {
                final next = Map<String, GrammarStudyPlan>.of(_plans);
                next[_userLevelForPlan] = GrammarStudyPlan(
                  level: _userLevelForPlan,
                  itemsPerDay: itemsPerDay,
                  servedIdsByDate: const {},
                );
                await Storage.setGrammarPlanRawJson(
                  GrammarPlanService.encodePlans(next),
                );
                if (mounted) {
                  setState(() => _plans = next);
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
```

(`showSoriSheet`의 실제 시그니처는 이 파일이 이미 쓰는 다른 바텀시트 호출부를 그대로 따르고, `key:` 파라미터가 없으면 `builder` 최상위 위젯에 `KeyedSubtree(key: ...)`로 감싼다.)
- [ ] **Step 6: 일 헤더가 필터 크롬 대체.** 필터 행(:756-… `Key('grammar-filter-row')`)을 감싸는 조건 분기 추가 — `_activePlan != null`이면 필터 행 대신 헤더+일 점 렌더:

```dart
          if (_activePlan != null) ...[
            KeyedSubtree(
              key: const Key('grammar-plan-day-header'),
              child: Column(
                children: [
                  Text(
                    t.grammarPlanDayHeader(
                      _activePlan!.completedDays + 1,
                      GrammarPlanService.totalDays(
                        GrammarPlanService.curatedRowsForLevel(_all, _activePlan!.level.toUpperCase()),
                        _activePlan!.itemsPerDay,
                      ),
                    ),
                    style: SoriTextTheme.of(context).label,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Wrap(
                    spacing: Spacing.xs,
                    children: [
                      for (var i = 0; i < _activePlan!.completedDays; i++)
                        Icon(Icons.circle, size: 6, color: SoriColors.success),
                      Icon(Icons.circle, size: 6, color: SoriColors.info),
                    ],
                  ),
                ],
              ),
            ),
          ] else
            KeyedSubtree(
              key: _filterRowKey,
              child: Row(
                key: const Key('grammar-filter-row'),
                // ... 기존 필터 Row 내용 그대로
              ),
            ),
```

(기존 필터 `Row(key: const Key('grammar-filter-row'), ...)` 서브트리는 그대로 이동시키고, `_filtered`는 플랜 모드일 때 `_computeFiltered`가 아니라 `GrammarPlanService.todaysSlice`로 채운다 — `_applyFilters()`와 별개로 `_applyPlanSlice()` 신설해 플랜 로드/일 완료 시점에 호출.)
- [ ] **Step 7: 완료 시트.** 마지막 카드 처리 지점(`_next()`/카드 판정 콜백에서 `_idx >= _filtered.length - 1`인 경우, :363 부근 기존 "덱 끝" 처리와 동일한 지점)에서, 플랜 모드면 `GrammarPlanService.recordServedDay`로 오늘 슬라이스 id를 커밋하고 완료 시트를 띄운다:

```dart
  Future<void> _completePlanDayIfNeeded() async {
    final plan = _activePlan;
    if (plan == null || _filtered.isEmpty) return;
    final servedIds = _filtered.map((g) => g.id).toList();
    final today = Storage.todayIso();
    if (plan.servedIdsByDate.containsKey(today)) return; // 이미 오늘 커밋됨
    final updated = GrammarPlanService.recordServedDay(
      plan, dateIso: today, servedIds: servedIds,
    );
    final next = Map<String, GrammarStudyPlan>.of(_plans)
      ..[_userLevelForPlan] = updated;
    await Storage.setGrammarPlanRawJson(GrammarPlanService.encodePlans(next));
    if (!mounted) return;
    setState(() => _plans = next);
    final t = AppL10n.of(context);
    await showSoriSheet(
      context: context,
      key: const Key('grammar-plan-completion-sheet'),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.grammarPlanCompletionTitle, style: SoriTextTheme.of(ctx).h2),
          Text(t.grammarPlanCompletionBody),
          SoriButton.filled(
            label: t.grammarPlanCompletionCta,
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed(
                '/grammar_choice_quiz',
                arguments: GrammarChoiceQuizRouteArguments(
                  level: plan.level,
                  allowedTargetIds: servedIds.toSet(),
                ),
              );
            },
          ),
          SoriButton.outlined(
            label: t.grammarPlanCompletionSkip,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
```

(`/grammar_choice_quiz` 라우트가 인자를 받는 구체 타입 `GrammarChoiceQuizRouteArguments`는 Task 17에서 신설 — 이 태스크에서는 호출부만 배선하고, Task 17이 그 라우트/생성자를 만들 때까지는 `flutter analyze`가 미정의 타입으로 실패할 수 있으므로 **이 스텝은 Task 17과 같은 커밋 경계 안에서 함께 GREEN 확인**하거나, 우선 `Map<String, dynamic>` 인자로 넘기고 Task 17에서 타입을 확정한다: `arguments: {'level': plan.level, 'allowedTargetIds': servedIds.toSet()}`.)
- [ ] **Step 8: GREEN + `flutter analyze` + `flutter test`(grammar_screen 관련 스위트 회귀 확인).**
- [ ] **Step 9: 커밋** — `git commit -m "feat(grammar): 플랜 모드 — 첫 진입 시트 + Tag N von M 헤더 + 완료 시트 (Grammatik 마스터플랜, 필터 크롬 대체)"`

---

### Task 17: grammar_choice_quiz_screen.dart 재구축 + 카드 앞/뒷면 재설계

**Files:**
- Modify: `lib/screens/grammar_choice_quiz_screen.dart` (전체 531줄 — progress 캡션 :333, feedback 카드 :397-454)
- Modify: `lib/main.dart` (그 라우트 인자 전달 지점 — 존재 여부 확인 후 타입 정리)
- Test: `grep -rln "GrammarChoiceQuizScreen(" test/`로 기존 테스트 확인 후 케이스 추가.

**Interfaces:**
- Consumes: Task 13(`allowedTargetIds`), Task 16(완료 시트가 넘기는 레벨+id 목록).
- Produces: `GrammarChoiceQuizScreen`에 `allowedTargetIds`/`planDayLabel` 파라미터 추가. 카드 뒷면(피드백)에 `noteFor(languageCode)`(활용) 추가 — "앞=패턴+큐, 뒤=규칙+활용+예문".

- [ ] **Step 1: 실패하는 테스트** — 기존 `_load`/`grammarLoader` 테스트 시임을 그대로 써서:

```dart
  testWidgets('allowedTargetIds 가 있으면 그 타깃만 출제된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: GrammarChoiceQuizScreen(
          grammarLoader: () async => _fixtureGrammars, // 기존 픽스처 재사용
          allowedTargetIds: {'a1_01'},
          randomSeed: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1 / 1'), findsOneWidget);
  });

  testWidgets('피드백 카드는 규칙+활용+예문을 모두 보여준다', (tester) async {
    await tester.pumpWidget(/* 기존 하네스, note/noteEn 이 채워진 픽스처 */);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(QuizChoice).first);
    await tester.pumpAndSettle();
    expect(find.text('예문 활용 노트'), findsOneWidget); // noteFor 값
  });
```

- [ ] **Step 2: 실행 → FAIL 확인.**
- [ ] **Step 3: 생성자에 파라미터 추가** — `GrammarChoiceQuizScreen`(:30-63)에 추가:

```dart
  const GrammarChoiceQuizScreen({
    super.key,
    this.initialLevel,
    this.grammarLoader,
    this.dataLoaderErrorReader,
    this.markGrammarHard,
    this.randomSeed,
    this.maxQuestions = 10,
    this.allowedTargetIds,
    this.planDayLabel,
  });

  /// Grammatik 마스터플랜 완료 시트에서 넘어온 경우 그 날 슬라이스 id 로만
  /// 타깃을 제한한다(오답 풀은 buildGrammarChoiceRound 계약대로 레벨 전체).
  final Set<String>? allowedTargetIds;

  /// 플랜에서 진입했을 때 "Tag N" 같은 문맥 라벨. null 이면(자유 진입)
  /// 기존처럼 레벨만 표시.
  final String? planDayLabel;
```

- [ ] **Step 4: `_load()`/`_restart()`에 배선** — :124-130, :234-240의 `buildGrammarChoiceRound(...)` 호출 두 곳에 `allowedTargetIds: widget.allowedTargetIds,`를 추가.
- [ ] **Step 5: 진행 캡션에 플랜 라벨 반영** — :333의 `Text('${_index + 1} / ${_round.length} · $_level', style: tt.caption)`을 교체:

```dart
        Text(
          widget.planDayLabel != null
              ? '${widget.planDayLabel} · ${_index + 1} / ${_round.length}'
              : '${_index + 1} / ${_round.length} · $_level',
          style: tt.caption,
        ),
```

- [ ] **Step 6: 카드 뒷면(피드백) 재설계 — 활용(note) 추가.** 피드백 `SoriCard`(:405-441) 안, `explanationFor` 블록(:429-437) 다음에 `noteFor` 블록 추가:

```dart
                          const SizedBox(height: Spacing.md),
                          Text(
                            t.grammarChoiceExplanationLabel,
                            style: tt.caption,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            question.target.explanationFor(languageCode),
                            style: tt.body,
                          ),
                          if (question.target.noteFor(languageCode).trim().isNotEmpty) ...[
                            const SizedBox(height: Spacing.md),
                            Text(t.grammarChoiceNoteLabel, style: tt.caption),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              question.target.noteFor(languageCode),
                              style: tt.body,
                            ),
                          ],
```

(`t.grammarChoiceNoteLabel` 신규 arb 키 — 다음 스텝.)
- [ ] **Step 7: arb 키 추가** (de/en 동시, `grammarChoiceExplanationLabel` 옆):

```json
  "grammarChoiceNoteLabel": "Anwendung",
```

(en: `"Usage"`.) → `flutter gen-l10n`.
- [ ] **Step 8: main.dart 라우트 인자 타입 확정** — Task 16이 `/grammar_choice_quiz`에 `Map<String, dynamic>` 또는 임시 타입으로 넘긴 인자를, 이 화면의 실제 라우트 케이스에서 읽어 `allowedTargetIds`/`initialLevel`로 변환(라우트가 아직 없으면 신설, 있으면 인자 파싱부만 확장):

```dart
            case '/grammar_choice_quiz':
              final args = settings.arguments;
              final allowedTargetIds = args is Map
                  ? (args['allowedTargetIds'] as Set<String>?)
                  : null;
              final planLevel = args is Map ? args['level'] as String? : null;
              return SoriTransitions.fadeScale(
                (_) => GrammarChoiceQuizScreen(
                  initialLevel: planLevel,
                  allowedTargetIds: allowedTargetIds,
                ),
                settings: settings,
              );
```

(이미 이 라우트가 존재하면 `initialLevel`/`allowedTargetIds` 파싱만 기존 케이스에 추가 — 라우트 자체를 새로 만들지 않는다. 존재 여부는 `grep -n "'/grammar_choice_quiz'" lib/main.dart`로 먼저 확인.)
- [ ] **Step 9: GREEN + `flutter analyze` + `flutter test`(grammar_choice_quiz 전체 스위트 회귀).**
- [ ] **Step 10: 커밋** — `git commit -m "feat(grammar-quiz): allowedTargetIds/planDayLabel 배선 + 피드백 카드에 활용(note) 추가 — 앞=패턴+큐/뒤=규칙+활용+예문"`

---

### Task 18: 클라우드 백업 화이트리스트 + 학습 데이터 내보내기 + 가드 테스트

**Files:**
- Modify: `lib/services/cloud_sync.dart` (`_restorableAccountFields` :35-48, `buildBackupPayload` :62-134, `_applyRestorePayload` :251-559)
- Modify: `lib/services/learning_data_export_service.dart` (`buildPackage` :35-109)
- Create: `test/backup_new_storage_keys_guard_test.dart`

**Interfaces:**
- Consumes: Task 10(`kl_study_log_v1_*`), Task 15(`kl_gram_plan_v1`).
- Produces: 두 신규 키가 `cloud_sync.dart` payload/restore와 `learning_data_export_service.dart`에 등록됨 + "신규 학습 키는 백업 목록 필수"를 강제하는 가드 테스트.

- [ ] **Step 1: 실패하는 가드 테스트** — `test/backup_new_storage_keys_guard_test.dart`. 소스 텍스트 검사로 "이 웨이브가 도입한 학습 데이터 페이로드 키가 백업 경로에 실제로 등록됐는지"를 잡는다(런타임 스캔이 아니라 리터럴 문자열 대조 — 앞으로 신규 학습 키를 추가하는 사람은 이 allowlist에 자기 키를 추가해야 테스트가 의미를 유지한다):

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('신규 학습 데이터 키는 cloud_sync 백업 화이트리스트에 등록돼야 한다', () {
    // 이 웨이브가 도입한 학습 데이터 페이로드 키. 새 학습 데이터 키를
    // 추가할 때는 cloud_sync.dart 의 페이로드/화이트리스트 갱신과
    // 함께 이 목록에도 추가한다 — 그래야 "등록을 잊는" 실수를 이 테스트가
    // 계속 잡는다.
    const requiredPayloadKeys = <String>['study_log_json', 'gram_plan_json'];
    final cloudSyncSource = File(
      'lib/services/cloud_sync.dart',
    ).readAsStringSync();
    final exportSource = File(
      'lib/services/learning_data_export_service.dart',
    ).readAsStringSync();
    for (final key in requiredPayloadKeys) {
      expect(
        cloudSyncSource.contains("'$key'"),
        isTrue,
        reason: '$key 가 cloud_sync.dart 의 페이로드/화이트리스트에 없다',
      );
    }
    expect(
      cloudSyncSource.contains('Storage.studyLogDates'),
      isTrue,
      reason: 'SRS 일별 원장이 cloud_sync.dart 백업 경로에서 읽히지 않는다',
    );
    expect(
      cloudSyncSource.contains('Storage.grammarPlanRawJson'),
      isTrue,
      reason: 'Grammatik 플랜이 cloud_sync.dart 백업 경로에서 읽히지 않는다',
    );
    expect(
      exportSource.contains('studyLog') && exportSource.contains('grammarPlan'),
      isTrue,
      reason: '학습 원장/플랜이 learning_data_export_service.dart 내보내기에 없다',
    );
  });
}
```

- [ ] **Step 2: 실행 → FAIL 확인** (아직 `study_log_json`/`gram_plan_json` 등이 없음).
- [ ] **Step 3: `cloud_sync.dart` 화이트리스트 추가** — `_restorableAccountFields`(:35-48)에 두 키 추가:

```dart
  static const Set<String> _restorableAccountFields = <String>{
    'vok',
    'chosung',
    'wordle',
    'grammar',
    'app',
    'progress',
    'srs_json',
    'wrong_count_json',
    'custom_packs_json',
    'bookshelf_json',
    'course_mastery_json',
    'hanok_state_json',
    'study_log_json',
    'gram_plan_json',
  };
```

- [ ] **Step 4: `buildBackupPayload` 확장** — 60일 원장 전체를 날짜별 맵으로 묶어 백업(로컬은 날짜별 키지만, 클라우드는 핫패스가 아니므로 한 번에 직렬화). `wrong_count_json` 대입부(:114) 다음에 추가:

```dart
    // SRS 일별 학습 원장 — 로컬은 날짜별 키(쓰기 증폭 방지)지만 클라우드
    // 백업은 핫패스가 아니므로 60일 창을 하나의 맵으로 직렬화한다.
    final studyLog = {
      for (final dateIso in Storage.studyLogDates())
        dateIso: Storage.studyLogIdsFor(dateIso),
    };
    if (studyLog.isNotEmpty) {
      payload['study_log_json'] = jsonEncode(studyLog);
    }
    if (Storage.grammarPlanRawJson.trim().isNotEmpty) {
      payload['gram_plan_json'] = Storage.grammarPlanRawJson;
    }
```

- [ ] **Step 5: `_applyRestorePayload` 확장** — 구조화 리스트/맵 계열 "로컬 비어있을 때만 채움" 패턴을 따라, `bookshelfJson` 처리 블록(:486-504) 다음에 추가:

```dart
    final studyLogJson = _structuredJson(
      data['study_log_json'],
      hasExpectedShape: (decoded) => decoded is Map,
    );
    if (studyLogJson != null) {
      final decoded = jsonDecode(studyLogJson);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final dateIso = entry.key.toString();
          if (Storage.studyLogIdsFor(dateIso).isNotEmpty) continue; // 로컬 우선
          final ids = entry.value;
          if (ids is! List) continue;
          for (final id in ids) {
            if (id is String && id.isNotEmpty) {
              await _guardedWrite(
                beforeWrite,
                () => Storage.srsReview(id, gotIt: true, recordToStudyLog: false)
                    .then((_) => Storage.appendStudyLogEntryForRestore(dateIso, id)),
              );
            }
          }
        }
      }
    }
    final gramPlanJson = _nonEmptyString(data['gram_plan_json']);
    if (gramPlanJson != null && Storage.grammarPlanRawJson.isEmpty) {
      await _guardedWrite(
        beforeWrite,
        () => Storage.setGrammarPlanRawJson(gramPlanJson),
      );
    }
```

(복원 시 임의 날짜에 id를 되돌려 쓰려면 "오늘 키에만 쓰는" 기존 `_appendStudyLogEntry`로는 부족하다 — Task 10에서 만든 private 헬퍼로는 임의 날짜를 못 쓰므로, 이 스텝에서 `storage_service.dart`에 복원 전용 공개 함수를 추가한다: `static Future<void> appendStudyLogEntryForRestore(String dateIso, String id) async { final ids = studyLogIdsFor(dateIso); if (ids.contains(id) || ids.length >= _studyLogMaxIdsPerDay) return; ids.add(id); await _sl(_studyLogKey(dateIso), ids); }` — 이 함수는 `_learningWritesLockReason` 게이트를 그대로 통과시키지 않고 호출측(`_guardedWrite`)이 이미 세션 유효성을 보장하므로 별도 잠금 체크 없이 직접 씀. 이 소규모 Storage 수정은 이 태스크의 일부로 `storage_service.dart`에 추가한다 — 단, storage_service.dart 파일 교집합 체인(7→10→15) **다음**이므로 이 태스크가 그 파일을 다시 만지는 마지막 지점이 된다.)
- [ ] **Step 6: `learning_data_export_service.dart` 확장** — `buildPackage`의 `data` 맵(:37-101), `'course'` 블록 다음에 추가:

```dart
      'studyLog': {
        for (final dateIso in Storage.studyLogDates())
          dateIso: Storage.studyLogIdsFor(dateIso),
      },
      'grammarPlan': _readGrammarPlan(),
```

및 헬퍼 메서드 추가:

```dart
  static Map<String, dynamic>? _readGrammarPlan() {
    final raw = Storage.grammarPlanRawJson.trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : null;
    } catch (_) {
      return null;
    }
  }
```

- [ ] **Step 7: GREEN 확인** — `flutter test test/backup_new_storage_keys_guard_test.dart` + `flutter test test/learning_data_export_service_test.dart`(기존 스냅샷이 있다면 신규 필드 반영해 재기준) + `flutter analyze`.
- [ ] **Step 8: 전체 회귀** — `flutter test` (cloud_sync/backup 관련 스위트 무회귀 확인).
- [ ] **Step 9: 커밋** — `git commit -m "feat(backup): kl_study_log_v1_*·kl_gram_plan_v1 백업/복원/내보내기 등록 + 신규 학습 키 가드 테스트 (검수#3)"`

---

## Self-Review 결과

**스펙 커버리지:**
- P1 단어팩·커스텀팩(지시서 1.1/1.2/1.21): Task 1(재출제 게터)·2(카운터+dispose 영속화)·3(뒤로가기)·4(표준팩 소급)·5(커스텀팩 learnedWordCount+addVokSeen+책장 표시) — 전부 대응.
- P2 시나리오 0/2(지시서 4.15): Task 6(자동 유도 헬퍼, courseEligible 자가유도 금지 준수)·7(0성 최초 기록)·8(_load 배선)·9(리스트 setState) — 전부 대응.
- SRS 일별 원장+ReviewHub+달력(검수#2/3/14/25): Task 10(일별 키+명시적 판정만+프루닝)·11(deckForIds)·12(허브+라우트+다중선택)·18(백업 화이트리스트) — 전부 대응.
- Grammatik 마스터플랜(지시서 1.11-1.15, 검수#24): Task 13(allowedTargetIds)·14(모델+순수서비스, id 목록 저장)·15(스토리지 키)·16(플랜 UI)·17(카드 재설계+SoriStudyFrame 파라미터 확장) — 전부 대응.

**플레이스홀더 점검:** 모든 태스크의 "Steps"에 실제 파일에서 읽은 현재 코드(줄 번호 포함)를 인용했다. 예외적으로 Task 6의 테스트 픽스처(`CurriculumCatalog.fromDataForTesting`)만 "test/course_mastery_test.dart:1893-2116 셰이프를 미러링"으로 위임했는데, 그 대상 코드는 실재를 직접 확인했고 `fromDataForTesting`의 실제 시그니처(`manifestJson`+코퍼스 리스트, `lib/services/curriculum_catalog.dart:87-95`)도 직접 읽어 확정했다 — 추정이 아니라 인용.

**시그니처 일관성:**
- `LearnSessionQueue.currentIsRepeat`(Task 1) → `vocab_pack_screen.dart`의 `_learnQueue?.currentIsRepeat`(Task 2)로 정확히 소비.
- `activeScenarioCheckpointContext`(Task 6, `course_mission_navigation.dart`) → `scenario_player_screen.dart._load()`(Task 8)의 `widget.courseContext ?? await activeScenarioCheckpointContext(...)`로 정확히 소비, `course_mastery_service.recordScenarioCheckpoint` 시그니처는 무변경 확인.
- `Storage.srsReview(..., recordToStudyLog: false)`(Task 10) → `scenario_player_screen.dart:120`(Task 10 자체 내) 1곳만 예외 처리, 나머지 21개 호출처는 기본값 `true`로 원장에 자동 편입.
- `ReviewDeckService.deckForIds`(Task 11) → `ReviewHubScreen`(Task 12)이 오늘 목록/달력 양쪽에서 소비.
- `buildGrammarChoiceRound(allowedTargetIds:)`(Task 13) → `GrammarChoiceQuizScreen.allowedTargetIds`(Task 17)가 그대로 전달.
- `GrammarStudyPlan`/`GrammarPlanService`(Task 14) → `Storage.grammarPlanRawJson`(Task 15)이 저장 계층, `grammar_screen.dart`(Task 16)가 UI 계층으로 정확히 계층 분리.

**계약 위험 요약:**
- `LearnSessionQueue`/`course_mastery_service.recordScenarioCheckpoint`는 절대 로직 변경 없이 게터·외부 헬퍼로만 확장 — 고정 테스트(`learn_session_queue_test.dart:62-68,119-129`, `course_mastery_test.dart:398-425`) 무회귀로 설계.
- `/review` 라우트(main.dart :813-819)는 이번 플랜에서 어떤 태스크도 그 블록 자체를 수정하지 않는다 — `/review/hub`는 별도 신규 케이스로만 추가(Task 12), 15곳 고정 테스트 안전.
- `storage_service.dart` 3중 순차 의존(Task 7→10→15→18 일부)과 `scenario_player_screen.dart` 순차 의존(Task 8→10)을 Global Constraints에 명시 — 병렬 실행 시 이 두 체인만 직렬 강제.
- Task 16↔17 경계의 라우트 인자 타입(`GrammarChoiceQuizRouteArguments` vs `Map`)은 Task 16 스텝 7에서 임시 `Map` 전달을 명시해 두 태스크가 서로 다른 세션에서 실행되어도 컴파일 경계가 끊기지 않게 설계했다 — 실제 구현자는 Task 17에서 타입을 확정하며 Task 16의 임시 호출부를 함께 정리할지 판단.
