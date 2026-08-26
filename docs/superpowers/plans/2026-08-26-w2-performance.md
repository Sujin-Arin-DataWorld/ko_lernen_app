# W2 성능 웨이브 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 지시서 성능 즉효 5건(P4) + 구조 3건(P5, 스플래시 아이콘 제작 포함)을 콜드스타트 계측 전/후와 함께 랜딩한다.

**Architecture:** 즉효(P4)는 각 화면/서비스의 국소 핫패스(빌드 경로 파싱, 불필요한 탭 로드, 순차 대기)를 제거한다. 구조(P5)는 `ScenarioLoader` 파싱을 isolate(`compute()`)로 옮기고, pre-runApp 초기화를 병렬화하고, Android 12+ 네이티브 스플래시의 아이콘-세이프존 자산을 다시 만든다. 두 계층 모두 기존 가드/계약 테스트를 건드리지 않거나, 건드릴 경우 먼저 계약을 재작성하는 별도 태스크로 분리한다.

**Tech Stack:** Flutter/Dart (flutter_test), Python 3 + Pillow(PIL, 확인됨 11.3.0) — 안전영역 아이콘 패딩용, `flutter_native_splash` (pubspec.yaml 에 이미 설정됨)

**Spec:** `C:\Users\vjinn\.claude\plans\c-dev-hangulsori-ko-lernen-app-docs-han-fizzy-marshmallow.md` (승인된 마스터 플랜 — "P4 성능 즉효", "P5 성능 구조", 검수 보강 7·10·11·26번)

## Global Constraints

- 브랜치: `feat/w2-performance` (이미 체크아웃됨). 태스크당 1커밋, 커밋 푸터: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- 각 태스크 종료 시 `flutter analyze` 신규 이슈 0
- 계약 고정 테스트(`learn_session_queue`·`course_mastery`·`audio_policy_guard` 등) 무변경 — 이 웨이브가 건드리는 파일 중 어느 것도 이 계약들의 대상이 아님을 각 태스크에서 확인한다
- Impeller 비활성 유지 (`android/app/src/main/AndroidManifest.xml:47-50` `EnableImpeller=false`) — 이 웨이브에서 되돌리지 않는다
- `test/scene_asset_resolver_test.dart:47-52` 와 `test/dancheong_burst_preload_contract_test.dart` 는 현재 `lib/main.dart` 소스를 문자열 인덱스로 비교하는 리터럴 가드다 — Task 8에서 병렬화하기 **전에** Task 7에서 먼저 "runner 이전 await 존재"로 재작성한다(검수#11)
- Python 스크립트/일회성 코드는 stdlib + Pillow(PIL) 만, 결정적 출력
- 실기기가 없는 환경에서는 계측·시각 검증 명령만 문서화하고 Jin 게이트로 표시한다(검수#4, #26) — 이 플랜의 어떤 태스크도 "실기기에서 확인했다"고 자칭하지 않는다

---

### Task 1: 콜드스타트 계측 절차 문서화 (전/후 비교 기준선)

**Files:**
- Create: `docs/data/coldstart_benchmark.md`

**Interfaces:**
- Produces: 이후 태스크들이 "전/후" 수치를 채워 넣을 표와 정확한 `adb` 명령. 실기기 접근 권한이 이 실행 환경에는 없으므로 **명령 문서화까지만** 하고 실측은 Jin 게이트로 남긴다.

- [ ] **Step 1: 계측 명령 확정.** 콜드스타트 시간은 `adb shell am start -W` 의 `TotalTime`(프로세스 시작~첫 프레임)을 쓴다. 앱 패키지 id 는 `android/app/build.gradle`(또는 `build.gradle.kts`)의 `applicationId` 를 확인해 채운다:

```bash
grep -rn "applicationId" android/app/build.gradle android/app/build.gradle.kts 2>/dev/null
```

- [ ] **Step 2: `docs/data/coldstart_benchmark.md` 작성.**

```markdown
# 콜드스타트 계측 (W2 성능 웨이브)

측정 불가 환경(이 세션)에서는 명령만 고정한다. Jin 이 실기기에서 실행해 표를 채운다.

## 명령

강제 종료 후 콜드스타트 1회:

    adb shell am force-stop <APPLICATION_ID>
    adb shell am start -W -n <APPLICATION_ID>/<APPLICATION_ID>.MainActivity

`TotalTime`(ms) 을 기록한다. 5회 반복해 중앙값을 쓴다(첫 1회는 warm page cache 편차가 커서 버린다 — 6회 실행, 마지막 5회 기록).

ANR 여부는 세션 10분 사용 후:

    adb logcat -s ActivityManager:E

## 결과

| 시점 | 빌드 | TotalTime 중앙값(ms) | 5회 원값 | 비고 |
|---|---|---|---|---|
| Before (W2 착수 전, `main`/`fix/partner-jin-batch1` 기준) | TBD by Jin | TBD | TBD | Task 2-9 적용 전 |
| After (Task 2-9 적용 후) | TBD by Jin | TBD | TBD | 스플래시 게이트(Task 6)·pre-runApp 병렬화(Task 8) 반영 |

## Jin 게이트

- [ ] Before 계측 (이 플랜의 Task 2 착수 전 브랜치에서)
- [ ] After 계측 (이 플랜의 마지막 태스크 커밋 후)
- [ ] 10분 세션 ANR 0 확인
- [ ] Android 12+ 실기기에서 흰 플래시·크롭 스플래시 없음 확인 (Task 9 게이트와 동일 항목, 중복 체크 아님 — 같은 세션에서 함께 확인)
```

- [ ] **Step 3: 커밋** — `git add docs/data/coldstart_benchmark.md && git commit -m "$(cat <<'EOF'
docs(perf): W2 콜드스타트 계측 절차 + Before/After 기준표

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 2: 보상 영수증 캡처 — 로컬/네트워크 필드 분리 (P4-①, 검수#7)

**Files:**
- Modify: `lib/models/sori_stage_progression.dart` (새 typedef 2종 추가)
- Modify: `lib/services/gye_service.dart` (신규 in-memory 캐시)
- Modify: `lib/services/sori_stage_progression_service.dart` (신규 로컬/네트워크 캡처 함수 2종, `_loadGyeLanternCount` 를 캐시 경유로 교체)
- Modify: `lib/services/sori_stage_reward_receipt_service.dart` (`capture()` 재설계)
- Modify: `test/sori_stage_reward_receipt_service_test.dart` (기존 `capture()` 테스트 2건 갱신 + 신규 Completer 레이스 테스트)

**Interfaces:**
- Produces: `SoriStageLocalBeforeFields`(레코드 typedef), `SoriStageNetworkBeforeFields`(레코드 typedef) — `lib/models/sori_stage_progression.dart` 에 정의. `GyeService.cachedGyeLanternCount`(동기 int 게터), `GyeService.refreshGyeLanternCache()`(비동기, 캐시 갱신). `SoriStageProgressionService.captureLocalBeforeFields()`(동기), `SoriStageProgressionService.loadNetworkBeforeFields()`(비동기). `SoriStageRewardReceiptService.capture()` 새 시그니처(아래) — 호출부(`sori_stage_catalog_screen.dart`, `sori_stage_today_screen.dart`)는 **변경 불필요**(새 파라미터는 옵션널 + 프로덕션 기본값이 실제 서비스를 가리킴).

**왜 `today` 필드를 아예 안 읽는가:** `SoriStageRewardReceiptService.compare()`(`lib/services/sori_stage_reward_receipt_service.dart:40-123`)는 `before.today`/`after.today`/`todayReward` 를 단 한 번도 참조하지 않는다 — xp·stampCount·quests·hanok.unlocked.length·pendingBojagiCount·gameBests·gyeLanternCount 만 비교한다. 기존 `capture()`(:15-38)의 `before = await loadSnapshot()` 가 매번 `TodayLearningSnapshotLoader.load()`(`ScenarioLoader.load()` 전체 6샤드 + `CurriculumCatalog.load()` + `ReviewDeckService.allReviewable()` + 네트워크 연결성 체크를 포함)까지 기다린 뒤에야 `openActivity()`(라우트 push)가 실행됐다 — 이것이 마스터 플랜이 진단한 "6.6MB JSON/CSV 파싱" 지연의 실체다. 새 설계는 이 미사용 필드를 아예 계산하지 않는다.

- [ ] **Step 1: 실패하는 테스트부터 — 기존 `capture()` 테스트 2건을 새 시그니처로 재작성 + Completer 레이스 테스트 추가.** `test/sori_stage_reward_receipt_service_test.dart` 의 120-146번 줄(기존 두 `capture` 테스트)을 아래로 교체하고, 파일 상단 import 에 `dart:async` 를 추가한다:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/sori_stage_reward_receipt_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
```

(기존 4개 `compare()` 테스트는 그대로 둔다 — `compare()` 시그니처는 이 태스크에서 바뀌지 않는다.) `capture never blocks learning when the before snapshot fails` 와 `capture compares state only after the activity returns` 두 테스트를 삭제하고 그 자리에:

```dart
  SoriStageNetworkBeforeFields _network({
    List<QuestProgress> quests = const [],
    int gyeLanternCount = 0,
  }) => (
    quests: quests,
    hanok: PersonalHanokProjection.from(
      const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
    ),
    gyeLanternCount: gyeLanternCount,
  );

  SoriStageLocalBeforeFields _local({int xp = 0}) => (
    xp: xp,
    stamps: 0,
    streakDays: 0,
    pendingBojagiCount: 0,
    gameBests: const <String, int>{},
  );

  test(
    'capture never blocks learning when local field capture fails (검수#7 fail-open)',
    () async {
      var opened = false;
      final receipt = await SoriStageRewardReceiptService.capture(
        activityId: 'course',
        captureLocalBefore: () =>
            throw StateError('local snapshot unavailable'),
        loadNetworkBefore: () async => _network(),
        loadSnapshot: () async => _snapshot(xp: 0),
        openActivity: () async => opened = true,
      );

      expect(opened, isTrue);
      expect(receipt, isNull);
    },
  );

  test('capture compares state only after the activity returns', () async {
    final receipt = await SoriStageRewardReceiptService.capture(
      activityId: 'review',
      captureLocalBefore: () => _local(xp: 2),
      loadNetworkBefore: () async => _network(),
      openActivity: () async {},
      loadSnapshot: () async => _snapshot(xp: 14),
    );

    expect(receipt, isNotNull);
    expect(receipt!.items.single.amount, 12);
  });

  test(
    'local fields are captured synchronously before openActivity(); network '
    'fields are awaited only after the activity returns (검수#7 race, '
    'Completer 기반 — 기존 () async => state 고정 테스트는 이 순서를 못 잡았다)',
    () async {
      final events = <String>[];
      final networkCompleter = Completer<SoriStageNetworkBeforeFields>();

      final receiptFuture = SoriStageRewardReceiptService.capture(
        activityId: 'course',
        captureLocalBefore: () {
          events.add('local-captured');
          return _local(xp: 10);
        },
        loadNetworkBefore: () {
          events.add('network-started');
          return networkCompleter.future;
        },
        openActivity: () async {
          events.add('activity-opened');
        },
        loadSnapshot: () async {
          events.add('after-loaded');
          return _snapshot(xp: 30);
        },
      );

      // openActivity() 는 이미 실행됐고 network future 는 아직 안 끝났다 —
      // capture() 가 완료를 기다리지 않고 "병행" 시작했다는 증거.
      await Future<void>.delayed(Duration.zero);
      expect(events, ['local-captured', 'network-started', 'activity-opened']);

      networkCompleter.complete(_network());
      final receipt = await receiptFuture;

      expect(events.last, 'after-loaded');
      expect(receipt, isNotNull);
      expect(receipt!.items.single.amount, 20);
    },
  );
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/sori_stage_reward_receipt_service_test.dart`. 예상: `captureLocalBefore`/`loadNetworkBefore` 이름 미정의 컴파일 에러(아직 `capture()` 에 없음).

- [ ] **Step 3: `lib/models/sori_stage_progression.dart` 에 typedef 2종 추가.** 파일 맨 아래(221번 줄, `SoriStageProgressionSnapshot` 클래스 뒤)에:

```dart

/// §W2-Task2 (검수#7): 리시트 "before" 캡처 중 `openActivity()` 직전에
/// **동기로** 읽어야 하는 로컬 필드만 모은 값. `Storage`/
/// `DecorationRewardService` 게터는 전부 동기(SharedPreferences 는
/// `Storage.init()` 이후 인메모리)라 await 없이 즉시 구할 수 있다.
typedef SoriStageLocalBeforeFields = ({
  int xp,
  int stamps,
  int streakDays,
  int pendingBojagiCount,
  Map<String, int> gameBests,
});

/// 네트워크/로컬-비동기 계산이 필요한 "before" 필드(quests·hanok·gye
/// 라운턴). `openActivity()` 와 **병행** 실행되고, 활동에서 돌아온 뒤에만
/// await 된다 — 라우트 전환을 절대 막지 않는다.
typedef SoriStageNetworkBeforeFields = ({
  List<QuestProgress> quests,
  PersonalHanokProjection hanok,
  int gyeLanternCount,
});
```

- [ ] **Step 4: `lib/services/gye_service.dart` 에 in-memory 라운턴 캐시 추가.** `myGyeMetas()` 정의(675번 줄) 바로 앞에:

```dart
  /// §W2-Task2: gye 라운턴 합계의 최근값 — 리시트 "before" 캡처가 매번
  /// Firestore 왕복을 기다리지 않도록 하는 캐시. 성공한 새로고침에서만
  /// 갱신되고, 실패해도 마지막 값을 유지한다(fail-open).
  static int _cachedGyeLanternCount = 0;

  static int get cachedGyeLanternCount => _cachedGyeLanternCount;

  /// [cachedGyeLanternCount] 를 Firestore 최신값으로 갱신한다. await 없이
  /// (`unawaited`) 호출해도 안전 — 실패는 조용히 삼키고 이전 값을 지킨다.
  static Future<int> refreshGyeLanternCache() async {
    try {
      final metas = await myGyeMetas();
      var total = 0;
      for (final meta in metas) {
        total += meta.weeklyPromiseSchemaVersion == 1
            ? meta.weeklyPromiseProgress
            : meta.weeklyGoalProgress;
      }
      _cachedGyeLanternCount = total;
      return total;
    } catch (_) {
      return _cachedGyeLanternCount;
    }
  }

```

- [ ] **Step 5: `lib/services/sori_stage_progression_service.dart` 갱신.** 파일 상단 import 에 `sori_stage_reward_receipt_service.dart` 는 추가하지 않는다(순환 방지 — typedef 는 모델 파일에 있다). `_loadGyeLanternCount`(154-167번 줄)를 캐시 경유로 교체:

```dart
  static Future<int> _loadGyeLanternCount() =>
      GyeService.refreshGyeLanternCache();
```

그리고 클래스 안(예: `_loadGyeLanternCount` 바로 뒤)에 신규 캡처 함수 2종 추가:

```dart

  /// §W2-Task2: 리시트 "before" 의 동기 로컬 절반. `capture()` 가
  /// `openActivity()` 바로 앞의 같은 동기 실행 구간에서 호출한다.
  static SoriStageLocalBeforeFields captureLocalBeforeFields() => (
    xp: Storage.xp,
    stamps: Storage.earnedStamps.length,
    streakDays: Storage.streakDays,
    pendingBojagiCount: DecorationRewardService.openableBoxCount(),
    gameBests: _loadGameBests(),
  );

  /// §W2-Task2: 리시트 "before" 의 네트워크/비동기 절반. `openActivity()`
  /// 와 병행 실행된다 — quests·hanok 은 로컬(메모이즈된 asset) 계산이라
  /// 그대로 await 하고, gye 라운턴만 순수 네트워크라 캐시값을 즉시 쓰고
  /// 새로고침은 기다리지 않는다(남는 노출 위험: 다른 기기에서 막 늘어난
  /// 라운턴은 이번 영수증에 늦게 반영될 수 있다 — 실제 저장된 보상에는
  /// 영향 없음, 영수증 표시만 한 박자 늦을 수 있다).
  static Future<SoriStageNetworkBeforeFields> loadNetworkBeforeFields() async {
    final hanokFuture = HanokStructureProjectionService.loadCurrent();
    final questsFuture = QuestTracker.computeAll();
    final gyeLanternBefore = GyeService.cachedGyeLanternCount;
    unawaited(GyeService.refreshGyeLanternCache());
    return (
      quests: await questsFuture,
      hanok: await hanokFuture,
      gyeLanternCount: gyeLanternBefore,
    );
  }
```

파일 최상단에 `import 'dart:async';` 가 없으면 추가한다(`unawaited` 사용).

- [ ] **Step 6: `lib/services/sori_stage_reward_receipt_service.dart` — `capture()` 재설계.** 파일 상단 import 에 추가:

```dart
import 'sori_stage_progression_service.dart';
import 'today_learning_snapshot.dart';
```

`capture()`(15-38번 줄)를 통째로 교체:

```dart
  static Future<RewardReceipt?> capture({
    required String activityId,
    required Future<SoriStageProgressionSnapshot> Function() loadSnapshot,
    required Future<void> Function() openActivity,
    SoriStageLocalBeforeFields Function()? captureLocalBefore,
    Future<SoriStageNetworkBeforeFields> Function()? loadNetworkBefore,
  }) async {
    final captureLocal =
        captureLocalBefore ?? SoriStageProgressionService.captureLocalBeforeFields;
    final loadNetwork =
        loadNetworkBefore ?? SoriStageProgressionService.loadNetworkBeforeFields;

    SoriStageLocalBeforeFields local;
    Future<SoriStageNetworkBeforeFields> networkFuture;
    try {
      // §검수#7: 로컬 필드는 openActivity() 호출 바로 앞, 같은 동기 실행
      // 구간 안에서 읽는다 — 사이에 await 이 없어 다른 코드가 끼어들 여지가
      // 없다. 네트워크 조회는 여기서 "시작만" 하고 기다리지 않는다.
      local = captureLocal();
      networkFuture = loadNetwork();
    } catch (_) {
      await openActivity();
      return null;
    }

    await openActivity();

    try {
      final network = await networkFuture;
      final before = SoriStageProgressionSnapshot(
        today: const TodayLearningSnapshot(pick: null),
        hanok: network.hanok,
        quests: network.quests,
        pendingBojagiCount: local.pendingBojagiCount,
        stampCount: local.stamps,
        xp: local.xp,
        streakDays: local.streakDays,
        todayReward: null,
        gameBests: local.gameBests,
        gyeLanternCount: network.gyeLanternCount,
      );
      final receipt = compare(
        activityId: activityId,
        before: before,
        after: await loadSnapshot(),
      );
      return receipt.isEmpty ? null : receipt;
    } catch (_) {
      return null;
    }
  }
```

- [ ] **Step 7: GREEN 확인** — `flutter test test/sori_stage_reward_receipt_service_test.dart`. 그 다음 호출부 회귀 확인 — `flutter test test/sori_stage_catalog_reward_flow_test.dart`(이 테스트는 `loadSnapshot:` 만 주입하고 `captureLocalBefore`/`loadNetworkBefore` 는 옵션널 기본값 그대로 두므로, 실제 `SoriStageProgressionService.captureLocalBeforeFields`/`loadNetworkBeforeFields` 가 위젯 테스트 환경에서 예외 없이 도는지도 함께 검증한다 — `Storage.xp`/`earnedStamps` 등은 위젯 테스트가 이미 `Storage.init()` 없이 기본값 0 을 반환하도록 되어 있는지 실행해서 확인; 만약 미초기화로 예외가 나면 fail-open 경로(Step 1의 첫 테스트가 보장)가 `null` 리시트로 흡수하므로 테스트 자체는 여전히 통과해야 한다). 실패 시 원인 파악 후 수정.

- [ ] **Step 8: `flutter analyze` 0** 확인.

- [ ] **Step 9: 커밋** — `git add lib/models/sori_stage_progression.dart lib/services/gye_service.dart lib/services/sori_stage_progression_service.dart lib/services/sori_stage_reward_receipt_service.dart test/sori_stage_reward_receipt_service_test.dart && git commit -m "$(cat <<'EOF'
perf(sori-stage): 리시트 캡처 로컬/네트워크 필드 분리 — today 파싱 생략 (P4-1, 검수#7)

before 스냅샷이 더 이상 TodayLearningSnapshotLoader(ScenarioLoader 6샤드+
CurriculumCatalog+ReviewDeckService) 를 기다리지 않는다 — compare() 가
읽지도 않는 필드였다. xp/stamps/streak/보자기는 openActivity() 직전 동기
캡처, quests/hanok 은 로컬 계산 그대로, gye 라운턴만 GyeService 신규
in-memory 캐시로 대체하고 새로고침은 병행 실행한다. Completer 기반 레이스
테스트로 openActivity() 가 네트워크 완료를 기다리지 않음을 고정한다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 3: 카탈로그 탭 lazy load (P4-②)

**Files:**
- Modify: `lib/screens/sori_stage/sori_stage_catalog_screen.dart:33-58`
- Test: `test/sori_stage_catalog_reward_flow_test.dart` (회귀 확인만 — 새 테스트 파일 추가)
- Create: `test/sori_stage_catalog_lazy_load_test.dart`

**Interfaces:**
- Consumes: `lib/screens/sori_stage/sori_stage_hanok_screen.dart:44,50-64` 의 nullable `Future?` + 가드 패턴을 그대로 복제한다(late 는 `LateInitializationError` — 검수 "문제없음" 확인 항목).
- Produces: `_progress` 필드가 `Future<SoriStageProgressionSnapshot>?`(nullable) 로 바뀐다 — `FutureBuilder<T>.future` 는 nullable 을 그대로 받는 파라미터라 145번 줄의 `FutureBuilder` 호출부는 수정 불필요.

- [ ] **Step 1: 실패하는 테스트 작성.** `test/sori_stage_catalog_lazy_load_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(pick: null),
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
  ),
  quests: const [],
  pendingBojagiCount: 0,
  stampCount: 0,
  xp: 0,
  streakDays: 0,
  todayReward: null,
);

void main() {
  testWidgets(
    'active:false 탭은 loadSnapshot 을 호출하지 않는다 (P4-2 lazy load)',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: SoriStageCatalogScreen(
            tab: SoriStageTab.games,
            active: false,
            loadSnapshot: () async {
              calls++;
              return _snapshot();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(calls, 0);
    },
  );

  testWidgets(
    '탭이 나중에 active 가 되면 그때 loadSnapshot 을 1회 호출한다',
    (tester) async {
      var calls = 0;
      var active = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: Column(
              children: [
                TextButton(
                  onPressed: () => setState(() => active = true),
                  child: const Text('activate'),
                ),
                Expanded(
                  child: SoriStageCatalogScreen(
                    tab: SoriStageTab.games,
                    active: active,
                    loadSnapshot: () async {
                      calls++;
                      return _snapshot();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);

      await tester.tap(find.text('activate'));
      await tester.pumpAndSettle();

      expect(calls, 1);
    },
  );
}
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/sori_stage_catalog_lazy_load_test.dart`. 예상: 첫 테스트에서 `calls` 가 1(현재 `initState` 가 `active` 와 무관하게 항상 로드) — `expect(calls, 0)` 실패.

- [ ] **Step 3: 구현.** `lib/screens/sori_stage/sori_stage_catalog_screen.dart:33-58` 을 교체:

```dart
class _SoriStageCatalogScreenState extends State<SoriStageCatalogScreen> {
  Future<SoriStageProgressionSnapshot>? _progress;

  Future<SoriStageProgressionSnapshot> _load() =>
      (widget.loadSnapshot ?? SoriStageProgressionService.load)();

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _progress = _load();
    }
  }

  @override
  void didUpdateWidget(covariant SoriStageCatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        ((!oldWidget.active && widget.active) ||
            oldWidget.loadSnapshot != widget.loadSnapshot ||
            oldWidget.tab != widget.tab)) {
      _progress = _load();
    }
  }

  void _reload() => setState(() {
    _progress = _load();
  });
```

(145번 줄의 `FutureBuilder<SoriStageProgressionSnapshot>(future: _progress, ...)` 는 그대로 둔다 — `future` 파라미터는 이미 nullable 을 받는다. `_progress` 가 `null` 이면 `snapshot.connectionState == ConnectionState.none` 이 되어 `ready == false` 로 처리되고, 카드들은 `progress: null` 로 렌더된다 — 잠금 상태 기본값과 동일해 시각적 회귀가 없다.)

- [ ] **Step 4: GREEN 확인** — `flutter test test/sori_stage_catalog_lazy_load_test.dart`

- [ ] **Step 5: 회귀 확인** — `flutter test test/sori_stage_catalog_reward_flow_test.dart` (이 테스트는 `active` 를 지정하지 않아 기본값 `true` 를 쓰므로 그대로 통과해야 한다). `flutter test test/sori_stage_hanok_shortcuts_test.dart` 도 함께 확인(같은 패턴을 참조했으므로 무관 회귀만 없으면 됨).

- [ ] **Step 6: `flutter analyze` 0** 확인.

- [ ] **Step 7: 커밋** — `git add lib/screens/sori_stage/sori_stage_catalog_screen.dart test/sori_stage_catalog_lazy_load_test.dart && git commit -m "$(cat <<'EOF'
perf(sori-stage): 카탈로그 탭 lazy load — active 탭만 로드 (P4-2)

sori_stage_shell.dart 의 IndexedStack 이 5탭을 전부 미리 build 하면서
Learn/Games 탭이 서로 active 여부와 무관하게 initState 에서 항상
loadSnapshot() 을 실행해 3회 동시 진행도 로드가 발생했다.
sori_stage_hanok_screen.dart 의 nullable Future? + 가드 패턴을 그대로
복제해 active 인 탭만 로드하도록 했다(late 는 LateInitializationError).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 4: `scenarioStars`/`completedScenarios` 파싱 메모이즈 (P4-③)

**Files:**
- Modify: `lib/services/storage_service.dart:2640-2671`
- Create: `test/storage_scenario_cache_test.dart`

**Interfaces:**
- Produces: `Storage.scenarioStars`/`Storage.completedScenarios` 게터가 in-memory 캐시를 경유한다 — 반환 타입·값은 불변, 오직 반복 호출 비용만 사라진다. `Storage.setScenarioStars`/`Storage.addCompletedScenario`(쓰기)가 캐시를 무효화한다.

**왜 스크린이 아니라 Storage 레이어에서 캐싱하는가:** `lib/screens/scenarios_list_screen.dart:154`(`final stars = Storage.scenarioStars;`, `build()` 안)와 `lib/screens/listening_screen.dart:123,195`(`Storage.completedScenarios.toSet()`, `_shelfCompartments()` — `build()` 에서 직접 호출됨, 303번 줄)가 재빌드마다 JSON 을 다시 파싱한다. 화면 쪽에 상태 필드로 캐싱하면 "시나리오 완료 후 언제 갱신하냐"는 라우트-리턴 배선이 새로 필요해 회귀 위험이 생긴다(두 화면 모두 현재 명시적 새로고침 콜백이 없다). Storage 게터 자체를 캐싱하고 **쓰기 시점에만 무효화**하면 어떤 호출자에서도 항상 최신값이 보장되면서 파싱은 값이 바뀔 때만 일어난다.

- [ ] **Step 1: 실패하는 테스트 작성.** `test/storage_scenario_cache_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  test('scenarioStars 는 쓰기 전까지 같은 맵 인스턴스를 재사용한다(캐시)', () async {
    await Storage.setScenarioStars('scn_a', 2);
    final first = Storage.scenarioStars;
    final second = Storage.scenarioStars;
    expect(identical(first, second), isTrue);
    expect(second['scn_a'], 2);
  });

  test('setScenarioStars 이후 값이 즉시 반영된다(캐시 무효화)', () async {
    await Storage.setScenarioStars('scn_b', 1);
    expect(Storage.scenarioStars['scn_b'], 1);
    await Storage.setScenarioStars('scn_b', 3);
    expect(Storage.scenarioStars['scn_b'], 3);
  });

  test('completedScenarios 는 addCompletedScenario 직후 값을 포함한다', () async {
    expect(Storage.completedScenarios, isNot(contains('scn_c')));
    await Storage.addCompletedScenario('scn_c');
    expect(Storage.completedScenarios, contains('scn_c'));
  });

  test(
    '캐시된 scenarioStars 맵을 밖에서 변형해도 다음 setScenarioStars 결과가 오염되지 않는다',
    () async {
      await Storage.setScenarioStars('scn_d', 1);
      final cached = Storage.scenarioStars;
      expect(
        () => cached['scn_d'] = 99,
        throwsUnsupportedError,
        reason: '게터가 반환하는 맵은 불변이어야 캐시가 실수로 오염되지 않는다',
      );
    },
  );
}
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/storage_scenario_cache_test.dart`. 예상: 첫 테스트에서 `identical(first, second)` 가 false(현재는 매번 새 맵을 만든다), 마지막 테스트에서 `cached['scn_d'] = 99` 가 예외를 던지지 않음(현재는 가변 맵을 그대로 반환한다).

- [ ] **Step 3: 구현.** `lib/services/storage_service.dart:2639-2671`(`scenarioStars`/`setScenarioStars`/`completedScenarios`/`addCompletedScenario`)를 교체:

```dart
  /// Sterne pro Szenario (0–3). Speichert nur Verbesserungen.
  /// §W2-Task4: 빌드 경로(scenarios_list_screen.dart)에서 재호출되므로
  /// in-memory 캐시 — 쓰기 시점(setScenarioStars)에만 무효화된다.
  static Map<String, int>? _scenarioStarsCache;

  static Map<String, int> get scenarioStars {
    final cached = _scenarioStarsCache;
    if (cached != null) {
      return cached;
    }
    final raw = _s('kl_scenario_stars');
    Map<String, int> parsed;
    if (raw.isEmpty) {
      parsed = const {};
    } else {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        parsed = m.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        parsed = const {};
      }
    }
    final unmodifiable = Map<String, int>.unmodifiable(parsed);
    _scenarioStarsCache = unmodifiable;
    return unmodifiable;
  }

  static Future<void> setScenarioStars(String id, int stars) async {
    final current = scenarioStars;
    if ((current[id] ?? 0) < stars) {
      final updated = Map<String, int>.of(current)..[id] = stars;
      _scenarioStarsCache = Map<String, int>.unmodifiable(updated);
      await _ss('kl_scenario_stars', jsonEncode(updated));
    }
  }

  /// §W2-Task4: `completedScenarios` 는 로컬 리스트 + XP 보상 원장의 클레임
  /// id 를 병합한다 — 원장 디코드(`_readXpRewardLedger`)가 실제 파싱 비용이라
  /// 결과를 캐싱한다. `addCompletedScenario` 가 무효화한다. 원장 자체가
  /// 다른 경로(예: 리스닝 보상 클레임)로 바뀌는 경우는 이 캐시 범위 밖이라
  /// 다음 프로세스 시작 전까지 반영이 늦을 수 있다 — 기존에도 클레임은
  /// `addCompletedScenario` 를 함께 호출하는 경로로만 완료 표시를 남겼다.
  static List<String>? _completedScenariosCache;

  static List<String> get completedScenarios {
    final cached = _completedScenariosCache;
    if (cached != null) {
      return cached;
    }
    final completed = _l('kl_completed_scenarios');
    final claims = _readXpRewardLedger(strict: false)?.claims.keys;
    if (claims != null) {
      for (final id in claims) {
        if (!completed.contains(id)) {
          completed.add(id);
        }
      }
    }
    final unmodifiable = List<String>.unmodifiable(completed);
    _completedScenariosCache = unmodifiable;
    return unmodifiable;
  }

  static Future<void> addCompletedScenario(String id) async {
    final list = _l('kl_completed_scenarios');
    if (!list.contains(id)) {
      list.add(id);
      await _sl('kl_completed_scenarios', list);
      _completedScenariosCache = null;
    }
  }
```

- [ ] **Step 4: GREEN 확인** — `flutter test test/storage_scenario_cache_test.dart`

- [ ] **Step 5: 전체 회귀 확인** — `flutter test test/scenarios_list_screen_test.dart test/listening_screen_test.dart` (파일명이 다르면 `grep -rl "ScenariosListScreen\|ListeningScreen" test/` 로 실제 파일을 찾아 실행). 스타/완료 관련 다른 테스트가 있으면 함께 실행: `grep -rl "scenarioStars\|completedScenarios" test/`.

- [ ] **Step 6: `flutter analyze` 0** 확인.

- [ ] **Step 7: 커밋** — `git add lib/services/storage_service.dart test/storage_scenario_cache_test.dart && git commit -m "$(cat <<'EOF'
perf(storage): scenarioStars/completedScenarios 파싱 메모이즈 (P4-3)

scenarios_list_screen.dart build() 와 listening_screen.dart
_shelfCompartments() 가 재빌드마다 kl_scenario_stars JSON 과 XP 보상
원장을 다시 디코드했다. Storage 게터 자체에 in-memory 캐시를 추가하고
쓰기(setScenarioStars/addCompletedScenario) 시점에만 무효화해, 화면
쪽에 새 새로고침 배선 없이 항상 최신값을 유지한다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 5: `_cellAspectRatio` 메모이즈 (P4-④, 위치 정정)

**Files:**
- Modify: `lib/screens/sori_stage/sori_stage_catalog_screen.dart:33-58,120-192,324-368`
- Test: 기존 `test/sori_stage_catalog_reward_flow_test.dart` 회귀 확인만(신규 테스트는 순수 함수 캐시라 골든/위젯 검증 불필요 — Step 1에서 순수 함수 단위 테스트로 캐시 히트를 증명)
- Create: `test/sori_stage_cell_aspect_ratio_cache_test.dart`

**참고(스펙 정정):** 마스터 플랜 원문은 "silben_kreuz_screen `_cellAspectRatio`" 라고 적었지만, 저장소 전수 검색(`grep -rn "_cellAspectRatio" lib/`) 결과 이 함수는 `lib/screens/silben_kreuz_screen.dart` 에 존재하지 않는다. 실제 정의·유일한 호출부는 `lib/screens/sori_stage/sori_stage_catalog_screen.dart:186`(호출)·`:324-368`(정의) 뿐이다 — 카탈로그 그리드의 카드 높이를 타이틀·풋터 텍스트를 `TextPainter` 로 실측해 계산하는 함수로, 매 `build()` 마다(그리드 엔트리 전체에 대해) 다시 계산된다. 이 태스크는 실제 위치인 카탈로그 화면을 대상으로 한다.

**Interfaces:**
- Produces: `_cellAspectRatio` 호출이 (cellWidth, titles, footerLabels, 텍스트스케일, locale) 조합이 이전 빌드와 같으면 재계산을 건너뛴다.

- [ ] **Step 1: 실패하는 테스트 작성.** 순수 함수 재계산 여부를 카운터로 증명하기 위해, 먼저 `_maxMeasuredTextHeight`(370번 줄)를 감싸는 카운터 훅을 두는 대신 — **State 필드 캐시**로 구현하므로 위젯 레벨에서 "같은 입력이면 두 번째 `build()` 가 `TextPainter.layout()` 을 다시 안 부른다"를 직접 관찰하긴 어렵다(private, 부수효과 없음). 대신 캐시 로직 자체를 순수 함수로 뽑아 단위 테스트한다. `test/sori_stage_cell_aspect_ratio_cache_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart'
    show cellAspectRatioCacheKey;

void main() {
  test('같은 입력은 같은 캐시 키를 만든다', () {
    final a = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course', 'Hangul'],
      footerLabels: const ['Ready'],
    );
    final b = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course', 'Hangul'],
      footerLabels: const ['Ready'],
    );
    expect(a, b);
  });

  test('cellWidth 가 다르면 캐시 키도 다르다', () {
    final a = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course'],
      footerLabels: const [],
    );
    final b = cellAspectRatioCacheKey(
      cellWidth: 180.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course'],
      footerLabels: const [],
    );
    expect(a, isNot(b));
  });

  test('titles 순서가 다르면 캐시 키도 다르다', () {
    final a = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course', 'Hangul'],
      footerLabels: const [],
    );
    final b = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Hangul', 'Course'],
      footerLabels: const [],
    );
    expect(a, isNot(b));
  });
}
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/sori_stage_cell_aspect_ratio_cache_test.dart`. 예상: `cellAspectRatioCacheKey` 미정의(존재하지 않음) 컴파일 에러.

- [ ] **Step 3: 구현.** `lib/screens/sori_stage/sori_stage_catalog_screen.dart` 상단(다른 top-level 함수들 근처, 320번 줄 `_cellAspectRatio` 바로 앞)에 캐시 키 함수와 캐시 저장소를 추가:

```dart
/// §W2-Task5: `_cellAspectRatio` 는 그리드 엔트리 전체 타이틀·풋터를
/// `TextPainter.layout()` 으로 실측한다 — 셀 폭·텍스트 스케일·로케일·문자열
/// 목록이 그대로면 매 build() 마다 다시 잴 필요가 없다. 이 키가 같으면
/// 이전 결과를 재사용한다.
String cellAspectRatioCacheKey({
  required double cellWidth,
  required double textScale,
  required String locale,
  required Iterable<String> titles,
  required Iterable<String> footerLabels,
}) {
  final buffer = StringBuffer()
    ..write(cellWidth.toStringAsFixed(2))
    ..write('|')
    ..write(textScale.toStringAsFixed(3))
    ..write('|')
    ..write(locale)
    ..write('|')
    ..writeAll(titles, '\u0001')
    ..write('|')
    ..writeAll(footerLabels, '\u0001');
  return buffer.toString();
}
```

`double _cellAspectRatio(...)` 함수(현재 324번 줄) 앞에 모듈 레벨 캐시 변수를 추가하고, 함수 본문 맨 앞에 캐시 조회/저장을 끼워 넣는다:

```dart
String? _cellAspectRatioCacheKey;
double? _cellAspectRatioCacheValue;

/// Grid ratio derived from the 4:3 image plus the measured localized title and
/// status footer. Every string remains available while cards in a row keep the
/// same height.
double _cellAspectRatio(
  BuildContext context,
  double cellWidth, {
  required Iterable<String> titles,
  required Iterable<String> footerLabels,
}) {
  if (!cellWidth.isFinite || cellWidth <= 0) {
    return 0.78;
  }
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  final locale = Localizations.localeOf(context);
  final textScale = scaler.scale(14) / 14;
  final cacheKey = cellAspectRatioCacheKey(
    cellWidth: cellWidth,
    textScale: textScale,
    locale: locale.toLanguageTag(),
    titles: titles,
    footerLabels: footerLabels,
  );
  if (cacheKey == _cellAspectRatioCacheKey &&
      _cellAspectRatioCacheValue != null) {
    return _cellAspectRatioCacheValue!;
  }
  final tt = SoriTextTheme.of(context);
  final titleStyle = tt.cardTitle;
  final footerStyle = tt.cardSubtitle;
  const double bodyPadding = Spacing.sm + Spacing.md;
  final bodyWidth = (cellWidth - Spacing.md * 2).clamp(1.0, double.infinity);
  final title = _maxMeasuredTextHeight(
    texts: titles,
    style: titleStyle,
    maxWidth: bodyWidth,
    scaler: scaler,
    direction: direction,
    locale: locale,
  );
  final footer = _maxMeasuredTextHeight(
    texts: footerLabels,
    style: footerStyle,
    maxWidth: (bodyWidth - 14).clamp(1.0, double.infinity),
    scaler: scaler,
    direction: direction,
    locale: locale,
  );
  // Two physical border pixels plus a small rounding allowance keep the
  // fixed-height grid honest at tablet comfort scale and 200% OS text.
  const double layoutAllowance = 4;
  final double height =
      cellWidth / (4 / 3) +
      bodyPadding +
      title +
      Spacing.xs +
      footer +
      layoutAllowance;
  final ratio = cellWidth / height;
  _cellAspectRatioCacheKey = cacheKey;
  _cellAspectRatioCacheValue = ratio;
  return ratio;
}
```

(모듈 레벨 `String?`/`double?` 캐시 변수 2개는 파일 전역이라 앱 생애주기 동안 유지된다 — 스코프가 "가장 최근 계산 1건"뿐이라 다른 화면 상태를 오염시키지 않고, 로케일/텍스트스케일이 바뀌면 키가 달라져 자동으로 재계산된다.)

- [ ] **Step 4: GREEN 확인** — `flutter test test/sori_stage_cell_aspect_ratio_cache_test.dart`

- [ ] **Step 5: 회귀 확인** — `flutter test test/sori_stage_catalog_reward_flow_test.dart`(그리드 레이아웃이 시각적으로 동일해야 한다 — 캐시는 순수 최적화, 값 자체는 안 바뀐다).

- [ ] **Step 6: `flutter analyze` 0** 확인.

- [ ] **Step 7: 커밋** — `git add lib/screens/sori_stage/sori_stage_catalog_screen.dart test/sori_stage_cell_aspect_ratio_cache_test.dart && git commit -m "$(cat <<'EOF'
perf(sori-stage): _cellAspectRatio 메모이즈 (P4-4)

카탈로그 그리드의 카드 높이 계산이 매 build() 마다 전체 타이틀·풋터
문자열을 TextPainter 로 다시 실측했다. (cellWidth, textScale, locale,
titles, footerLabels) 조합이 이전 빌드와 같으면 캐시된 결과를 재사용한다.

(스펙 정정: 마스터 플랜은 이 함수를 silben_kreuz_screen.dart 로 표기했으나
저장소 전수 검색 결과 실제 정의/유일 호출부는
sori_stage_catalog_screen.dart 였다.)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 6: 스플래시 게이트 — 고정 2000ms → `Future.wait` 상한부 (P4-⑤, 검수#10)

**Files:**
- Create: `lib/services/splash_gate.dart`
- Modify: `lib/screens/splash_screen.dart`
- Modify: `lib/main.dart:207-217,223-249`
- Create: `test/splash_gate_test.dart`
- Create: `test/splash_screen_gate_test.dart`

**Interfaces:**
- Produces: `SplashGate.ready`(`Future<void>` getter — 마이그레이션+오디오 컨텍스트 완료 시 1회 resolve), `SplashGate.markReady()`(idempotent). `SplashScreen` 생성자에 테스트 전용 옵션널 파라미터 `minDisplay`/`gateTimeout`/`readyGate` 추가(기본값은 프로덕션 동작 그대로).

- [ ] **Step 1: 실패하는 테스트 — `SplashGate` 단위 테스트.** `test/splash_gate_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/splash_gate.dart';

void main() {
  test('markReady() 전에는 ready 가 완료되지 않는다', () async {
    var completed = false;
    // ignore: discarded_futures
    SplashGate.ready.then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
  });

  test('markReady() 는 ready 를 완료시키고, 여러 번 불러도 안전하다', () async {
    SplashGate.markReady();
    await expectLater(SplashGate.ready, completes);
    expect(() => SplashGate.markReady(), returnsNormally);
  });
}
```

(참고: `SplashGate` 는 전역 싱글턴 `Completer` 라 테스트 순서에 따라 상태가 남는다 — 두 번째 테스트가 먼저 markReady 를 부르므로, 첫 번째 테스트를 반드시 먼저 배치한다. `flutter test test/splash_gate_test.dart` 단독 실행 기준으로 순서가 고정되어 있으면 충분하다.)

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/splash_gate_test.dart`. 예상: `package:ko_lernen_app/services/splash_gate.dart` 없음(파일 미생성) 컴파일 에러.

- [ ] **Step 3: `SplashGate` 구현.** `lib/services/splash_gate.dart` 신규 생성:

```dart
import 'dart:async';

/// §W2-Task6 (P4-5, 검수#10): 스플래시가 "최소 표시 시간"과 병행 대기하는
/// 준비 신호. `main.dart` 의 백그라운드 시작 절차 중 데이터 마이그레이션과
/// 오디오 컨텍스트 적용이 끝나면 [markReady] 가 1회 호출된다 —
/// BookImageService.initialize() 등 나머지 백그라운드 작업은 이 게이트와
/// 무관하게 계속 지연 실행된다(스플래시 화면과 관계없는 작업이므로).
abstract final class SplashGate {
  static final Completer<void> _ready = Completer<void>();

  /// 스플래시 화면이 최소 표시 타이머와 함께 기다리는 신호.
  static Future<void> get ready => _ready.future;

  /// 여러 번 불러도 안전 — 두 번째 호출부터는 아무 일도 하지 않는다.
  static void markReady() {
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }
}
```

- [ ] **Step 4: `SplashGate` GREEN 확인** — `flutter test test/splash_gate_test.dart`

- [ ] **Step 5: 실패하는 테스트 — `SplashScreen` 타이밍 테스트.** `test/splash_screen_gate_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/splash_screen.dart';

void main() {
  testWidgets(
    '게이트가 즉시 열려도 최소 표시 시간(600ms) 전에는 내비게이션하지 않는다',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            readyGate: () async {},
            minDisplay: const Duration(milliseconds: 600),
            gateTimeout: const Duration(milliseconds: 1500),
          ),
          routes: {'/next': (_) => const Scaffold(body: Text('NEXT'))},
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    '게이트가 절대 안 열려도 상한(1500ms)이 지나면 내비게이션한다',
    (tester) async {
      final never = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            readyGate: () => never.future,
            minDisplay: const Duration(milliseconds: 600),
            gateTimeout: const Duration(milliseconds: 1500),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
    },
  );
}
```

- [ ] **Step 6: 실행해 실패 확인** — `flutter test test/splash_screen_gate_test.dart`. 예상: `readyGate`/`minDisplay`/`gateTimeout` 명명 파라미터 없음(현재 생성자는 `const SplashScreen({super.key})` 뿐) 컴파일 에러.

- [ ] **Step 7: `SplashScreen` 구현.** `lib/screens/splash_screen.dart` 전체를 교체:

```dart
import 'package:flutter/material.dart';
import '../motion/transitions.dart';
import '../services/splash_gate.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import 'intro_gate_screen.dart';
import 'consent_screen.dart';
import 'onboarding_start_screen.dart';
import 'app_shell.dart';

/// 앱 시작 시 로고 화면. 최소 표시 시간(기본 600ms)과 백그라운드 준비
/// 신호([SplashGate.ready])를 병행 대기하고, 상한(기본 1500ms)을 넘기지
/// 않는다. 이전에는 무조건 2000ms 를 기다렸다 — 마이그레이션·오디오
/// 컨텍스트가 그보다 일찍 끝나면 불필요하게 대기했고, 늦게 끝나도(느린
/// 기기) 상한이 없어 얼마든지 늘어날 수 있었다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minDisplay = const Duration(milliseconds: 600),
    this.gateTimeout = const Duration(milliseconds: 1500),
    Future<void> Function()? readyGate,
  }) : _readyGate = readyGate;

  final Duration minDisplay;
  final Duration gateTimeout;

  /// 테스트 전용 훅 — 프로덕션은 [SplashGate.ready] 를 기다린다.
  final Future<void> Function()? _readyGate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final gate = widget._readyGate ?? (() => SplashGate.ready);
    Future.wait<void>([
      Future<void>.delayed(widget.minDisplay),
      gate().timeout(widget.gateTimeout, onTimeout: () {}),
    ]).then((_) => _navigateToNext());
  }

  void _navigateToNext() {
    if (!mounted) {
      return;
    }
    final hasCompleted = Storage.hasCompletedOnboarding;
    final sessionCount = Storage.sessionCount;
    final isSecondSession = sessionCount == 1;

    late Widget nextScreen;

    if (!hasCompleted && !Storage.consentAccepted) {
      // Consent is the first durable boundary. A learner must never look
      // onboarded merely because they saw a welcome or chose a daily goal.
      nextScreen = const ConsentScreen();
    } else if (!hasCompleted && Storage.userLevelCode == null) {
      // A consented learner without a placement always gets the intentional
      // start-point choice.
      nextScreen = const OnboardingStartScreen();
    } else if (isSecondSession) {
      // 2회차 — 솟을대문 인트로
      nextScreen = const IntroGateScreen();
    } else {
      // 3회차+ — 홈
      nextScreen = const AppShell();
    }

    Navigator.of(
      context,
    ).pushReplacement(SoriTransitions.fadeScale((_) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoriColors.lightBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSide = constraints.biggest.shortestSide * 0.7;
            return Center(
              child: Image.asset(
                'assets/icons/HanLogo.png',
                excludeFromSemantics: true,
                width: logoSide,
                height: logoSide,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}
```

(배경색 `Colors.white` → `SoriColors.lightBg`(#FAF6EC) — 마스터 플랜 "배경 흰색→#FAF6EC 정합". 이 색은 `pubspec.yaml` 의 `flutter_native_splash.color`/`android_12.color` 와도 이미 `#FAF6EC` 로 일치한다.)

- [ ] **Step 8: GREEN 확인** — `flutter test test/splash_screen_gate_test.dart`

- [ ] **Step 9: `main.dart` 배선 — 마이그레이션+오디오 컨텍스트 완료 시 `SplashGate.markReady()` 호출, 낡은 주석 갱신.** `lib/main.dart` 상단 import 에 추가:

```dart
import 'services/splash_gate.dart';
```

207-214번 줄의 주석("2026-08-19: 위 두 단계... 스플래시가 최소 2초 떠 있는 동안 끝난다.")을 아래로 교체(같은 위치, `runner(const KoLernenApp());` 앞):

```dart
  // 2026-08-19(원 결정) + 2026-08-26(W2 갱신): 에셋 매니페스트(§SceneAssetResolver)
  // + 축하 스프라이트 디코딩(§DancheongBurst)만 첫 프레임 전에 끝내면 된다.
  // 마이그레이션·오디오 컨텍스트는 첫 프레임 뒤로 미루되, splash_screen.dart
  // 가 SplashGate.ready 로 그 완료를 기다린다(최소 600ms~상한 1500ms) — 예전
  // "스플래시가 고정 2초 떠 있으니 그 안에 끝난다"는 가정과 달리, 이제
  // 스플래시 표시 시간 자체가 이 작업의 완료 여부에 (상한 내에서) 반응한다.
  // BookImageService.initialize()/크롭·피커 복구는 SplashGate 와 무관하게
  // 계속 게이트 밖에서 지연 실행된다 — 스플래시 로고와 관계가 없다.
  runner(const KoLernenApp());

  unawaited(_finishStartupInBackground());
```

`_finishStartupInBackground()`(223번 줄)의 본문 중 `await AudioPolicy.instance.applyPlatformAudioContext();`(244번 줄) 바로 뒤에 추가:

```dart
  // SFX 전역 오디오 세션: 타 앱 음악과 mix + 무음 스위치 존중 (ADR-002 §5-3).
  await AudioPolicy.instance.applyPlatformAudioContext();
  // §W2-Task6: 스플래시가 기다리는 두 단계(마이그레이션+오디오 컨텍스트)가
  // 여기서 끝난다 — BookImageService 이후 단계들은 게이트와 무관.
  SplashGate.markReady();
  try {
    await BookImageService.initialize();
```

(마이그레이션 자체는 이미 이 함수 맨 앞(227-232번 줄)에서 `await DataMigrationService.run()` 으로 끝나 있으므로, 오디오 컨텍스트까지 끝난 시점이 정확히 "마이그레이션+오디오컨텍스트 완료" 시점이다.)

- [ ] **Step 10: 전체 회귀 확인** — `flutter test test/splash_gate_test.dart test/splash_screen_gate_test.dart`. `grep -rln "SplashScreen\|_startProductionApplication\|_finishStartupInBackground" test/` 로 다른 관련 테스트를 찾아 함께 실행.

- [ ] **Step 11: `flutter analyze` 0** 확인.

- [ ] **Step 12: 커밋** — `git add lib/services/splash_gate.dart lib/screens/splash_screen.dart lib/main.dart test/splash_gate_test.dart test/splash_screen_gate_test.dart && git commit -m "$(cat <<'EOF'
perf(splash): 고정 2000ms 대기 → 최소600ms/상한1500ms 게이트 (P4-5, 검수#10)

SplashGate 를 신설해 마이그레이션+오디오 컨텍스트 완료 신호를 노출한다.
SplashScreen 은 Future.wait([최소표시 600ms, SplashGate.ready.timeout(1500ms)])
로 대기한다 — 배경 작업이 빨리 끝나면 그만큼 빨리, 느려도 1500ms 를 넘기지
않는다. BookImageService.initialize 등 나머지 백그라운드 작업은 게이트
밖에서 계속 지연 실행된다. 배경색 흰색→#FAF6EC(pubspec.yaml 스플래시 색과
정합). main.dart 의 낡은 "고정 2초 안에 끝난다" 주석을 갱신했다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 7: `ScenarioLoader` — `findById` + 샤드 파싱 `compute()` 이관 (P5-①)

**Files:**
- Modify: `lib/services/scenario_loader.dart`
- Modify: `lib/screens/scenario_player_screen.dart:647-650`
- Modify: `lib/screens/scenarios_list_screen.dart` (open 경로에 level 힌트 threading)
- Test: `test/scenario_loader_shard_test.dart`, `test/scenario_loader_test.dart` 회귀 확인
- Create: `test/scenario_loader_compute_test.dart`

**Interfaces:**
- Produces: `ScenarioLoader.findById(String id, {LearnerLevel? preferredLevel})`(`Future<Scenario?>`) — 코퍼스가 이미 전체 캐시돼 있으면 `byId` 로 즉시 조회, 아니면 `preferredLevel` 샤드부터 `loadLevel()` 로 하나씩 찾는다. `static (List<Scenario>, int) _parseShard(String raw)`(순수 함수, top-level `compute()` 로 isolate 이관 가능) — `_parseInto(raw, into)` 뮤테이션 패턴을 대체한다.
- Consumes: `Scenario.fromJson`(이미 순수/isolate-safe — 검수 "문제없음" 확인 항목).

**주의(검수#6, 치명 버그 회피):** 기존 `_parseInto(String raw, List<Scenario> into)` 는 호출자가 넘긴 `into` 리스트를 직접 뮤테이션한다. `compute()` 는 콜백과 인자를 별도 isolate 로 **복사**해 실행하므로, 이 함수를 그대로 `compute(_parseInto, (raw, into))` 식으로 옮기면 isolate 안에서 `into` 의 **복사본만** 채워지고 호출자의 원본 리스트는 계속 비어 있다 — 시나리오 전량 소실. 그래서 `_parseShard` 는 인자로 원본 문자열만 받고, 결과를 리턴값(튜플)으로만 돌려준다.

- [ ] **Step 1: 실패하는 테스트 — `_parseShard`/`compute()` 이관 후에도 skip-broken 의미가 보존됨을 증명.** `test/scenario_loader_compute_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ScenarioLoader.reset();
    rootBundle.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test(
    'compute() 이관 후에도 깨진 항목은 건너뛰고 유효한 항목만 남는다 '
    '(skip-broken 의미 보존, 검수#6)',
    () async {
      final mixedShard = jsonEncode({
        'version': 1,
        'scenarios': [
          {
            'id': 'valid_one',
            'level': 'a1',
            'title': {'ko': '가', 'de': 'g', 'en': 'g'},
          },
          'not-a-map', // skipped: e is! Map<String, dynamic>
          {
            'id': 'valid_two',
            'level': 'a1',
            'title': {'ko': '나', 'de': 'n', 'en': 'n'},
          },
        ],
      });
      final requested = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
            final key = const StringCodec().decodeMessage(message)!;
            requested.add(key);
            final body = key == 'assets/data/scenarios_a1.json'
                ? mixedShard
                : '{"version":1,"scenarios":[]}';
            return ByteData.sublistView(
              Uint8List.fromList(const Utf8Encoder().convert(body)),
            );
          });

      final list = await ScenarioLoader.load();

      expect(list.map((s) => s.id), containsAll(['valid_one', 'valid_two']));
      expect(list.length, 2);
      expect(ScenarioLoader.lastError, isNull);
    },
  );

  test('findById 는 preferredLevel 샤드 하나만 먼저 읽는다', () async {
    final requested = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = const StringCodec().decodeMessage(message)!;
          requested.add(key);
          final body = key == 'assets/data/scenarios_b1.json'
              ? jsonEncode({
                  'version': 1,
                  'scenarios': [
                    {
                      'id': 'target',
                      'level': 'b1',
                      'title': {'ko': '다', 'de': 'd', 'en': 'd'},
                    },
                  ],
                })
              : '{"version":1,"scenarios":[]}';
          return ByteData.sublistView(
            Uint8List.fromList(const Utf8Encoder().convert(body)),
          );
        });

    final found = await ScenarioLoader.findById(
      'target',
      preferredLevel: LearnerLevel.b1,
    );

    expect(found?.id, 'target');
    expect(
      requested.where((p) => p.contains('scenarios_')).toList(),
      ['assets/data/scenarios_b1.json'],
    );
  });

  test('findById 는 없는 id 면 null 을 반환한다(전 샤드 탐색 후)', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.sublistView(
            Uint8List.fromList(
              const Utf8Encoder().convert('{"version":1,"scenarios":[]}'),
            ),
          );
        });

    final found = await ScenarioLoader.findById('missing');
    expect(found, isNull);
  });
}
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/scenario_loader_compute_test.dart`. 예상: `ScenarioLoader.findById` 미정의 컴파일 에러.

- [ ] **Step 3: 구현.** `lib/services/scenario_loader.dart` 상단 import 에 추가:

```dart
import 'package:flutter/foundation.dart' show compute;
```

`_parseInto`(20-35번 줄)를 순수 함수로 교체:

```dart
  /// §W2-Task7 (검수#6): 순수 함수 — 외부 상태를 뮤테이션하지 않는다.
  /// compute() 로 isolate 에 보내면 인자와 반환값만 복사되므로, 예전
  /// `_parseInto(raw, into)` 처럼 호출자의 리스트를 직접 채우는 방식은
  /// isolate 경계에서 그 변경분이 소실된다(복사본만 바뀐다) — 반드시
  /// 리턴값(튜플)으로만 결과를 전달한다.
  static (List<Scenario>, int) _parseShard(String raw) {
    final scenarios = <Scenario>[];
    var skipped = 0;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    for (final e in (json['scenarios'] as List? ?? const [])) {
      if (e is! Map<String, dynamic>) {
        skipped++;
        continue;
      }
      try {
        scenarios.add(Scenario.fromJson(e));
      } catch (err) {
        skipped++;
      }
    }
    return (scenarios, skipped);
  }
```

`load()`(38-65번 줄)의 루프 안 `_parseInto` 호출부를 교체:

```dart
    for (final level in shardLevels) {
      try {
        final raw = await rootBundle.loadString(shardPath(level));
        final (parsed, shardSkipped) = await compute(_parseShard, raw);
        list.addAll(parsed);
        skipped += shardSkipped;
      } catch (e) {
        // Ein fehlender Shard darf die anderen fünf Level nicht mitnehmen.
        failed.add(level.code);
      }
    }
```

`loadLevel()`(78-102번 줄)의 파싱부도 교체:

```dart
    final list = <Scenario>[];
    try {
      final raw = await rootBundle.loadString(shardPath(level));
      final (parsed, _) = await compute(_parseShard, raw);
      list.addAll(parsed);
      lastError = null;
    } catch (e) {
      lastError = 'Szenarien (${level.code}) konnten nicht geladen werden: $e';
    }
```

`byId(String id)`(109-123번 줄) 바로 뒤에 `findById` 신설:

```dart
  /// §W2-Task7 (P5-1): id 기준으로 시나리오를 찾되, 전체 코퍼스가 아직
  /// 캐시돼 있지 않으면 [preferredLevel] 샤드부터 먼저 읽는다.
  /// `scenario_player_screen.dart` 는 예전에 `load()`(전체 6샤드)를 부른
  /// 뒤 `byId()` 로 걸러냈다 — id 하나를 찾으려고 매번 전 코퍼스를 당겼다.
  static Future<Scenario?> findById(
    String id, {
    LearnerLevel? preferredLevel,
  }) async {
    if (_cached != null) {
      return byId(id);
    }
    if (preferredLevel != null) {
      final shard = await loadLevel(preferredLevel);
      for (final s in shard) {
        if (s.id == id) {
          return s;
        }
      }
    }
    for (final level in shardLevels) {
      if (level == preferredLevel) {
        continue;
      }
      final shard = await loadLevel(level);
      for (final s in shard) {
        if (s.id == id) {
          return s;
        }
      }
    }
    return null;
  }
```

- [ ] **Step 4: GREEN 확인** — `flutter test test/scenario_loader_compute_test.dart`

- [ ] **Step 5: 회귀 확인** — `flutter test test/scenario_loader_shard_test.dart test/scenario_loader_test.dart`. `loadLevel` 이 여전히 레벨당 샤드 1개만 읽는지(LRU 카운트 불변), `load()` 가 전체 6샤드에서 여전히 30개 이상을 반환하는지 확인.

- [ ] **Step 6: 호출부 배선 — `scenario_player_screen.dart:647-650`.** `_loadScenarioFromCatalog`(647번 줄)를 교체:

```dart
  Future<Scenario?> _loadScenarioFromCatalog(String scenarioId) =>
      ScenarioLoader.findById(scenarioId, preferredLevel: widget.levelHint);
```

`ScenarioPlayerScreen`(375번 줄) 생성자에 옵션널 `levelHint` 필드를 추가한다 — `required this.scenarioId,`(387번 줄) 바로 뒤:

```dart
    this.levelHint,
```

그리고 클래스 필드 선언부(`final String scenarioId;` 근처)에:

```dart
  /// §W2-Task7: 알고 있으면 `ScenarioLoader.findById` 가 이 레벨 샤드부터
  /// 찾도록 힌트를 준다 — 없으면 전체 순회(정확성은 동일, 최적화만 없음).
  final LearnerLevel? levelHint;
```

(`LearnerLevel` 타입이 이 파일에 이미 import 돼 있는지 `grep -n "LearnerLevel" lib/screens/scenario_player_screen.dart | head -3` 로 확인 — `models/scenario.dart` 를 통해 이미 들어와 있을 가능성이 높다. 없으면 `import '../models/scenario.dart' show LearnerLevel;` 추가.)

- [ ] **Step 7: 주 진입 경로에 힌트 전달 — `scenarios_list_screen.dart`.** 이미 `Scenario` 객체를 들고 있는 두 호출부에 `scenario.level` 을 넘긴다. `_OpenScenarioCard`(316-352번 줄)의 `openBuilder`:

```dart
      openBuilder: (ctx, _) => ScenarioPlayerScreen(
        scenarioId: scenario.id,
        levelHint: scenario.level,
      ),
```

`_NextRecommended`(684-705번 줄)의 `openScenario()`:

```dart
    void openScenario() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScenarioPlayerScreen(
            scenarioId: scenario.id,
            levelHint: scenario.level,
          ),
        ),
      );
    }
```

(다른 호출부— 딥링크·추천 등 `Scenario` 객체 없이 id 만 아는 경로 — 는 `levelHint` 를 생략해도 된다. `findById` 가 힌트 없이도 정확하게 동작하므로 최적화 누락일 뿐 회귀는 아니다.)

- [ ] **Step 8: `grep -rn "ScenarioPlayerScreen(" lib/` 로 다른 호출부를 전수 확인** — 컴파일 에러 없이 새 옵션널 파라미터를 무시할 수 있는지(named optional 이라 기존 호출부는 그대로 컴파일된다) 확인만 한다. 코드 수정은 하지 않는다.

- [ ] **Step 9: 전체 회귀** — `flutter test test/scenario_loader_shard_test.dart test/scenario_loader_test.dart test/scenario_loader_compute_test.dart`. `grep -rl "ScenarioPlayerScreen" test/` 로 위젯 테스트를 찾아 함께 실행.

- [ ] **Step 10: `flutter analyze` 0** 확인.

- [ ] **Step 11: 커밋** — `git add lib/services/scenario_loader.dart lib/screens/scenario_player_screen.dart lib/screens/scenarios_list_screen.dart test/scenario_loader_compute_test.dart && git commit -m "$(cat <<'EOF'
perf(scenario): findById(preferredLevel) + 샤드 파싱 compute() 이관 (P5-1)

_parseInto(raw, into) 의 리스트 뮤테이션을 순수 함수 _parseShard(raw) ->
(List<Scenario>, int) 로 리팩터해 compute() isolate 로 옮겼다 — 뮤테이션
방식 그대로 옮겼다면 isolate 경계에서 호출자 리스트가 채워지지 않아
시나리오가 전량 소실됐을 것이다(검수#6). skip-broken 의미(깨진 항목만
건너뛰고 나머지는 보존)는 테스트로 고정했다.

ScenarioPlayerScreen 이 시나리오 하나를 열려고 6샤드 전체를 로드하던
경로(_loadScenarioFromCatalog)를 findById(preferredLevel) 로 교체 —
scenarios_list_screen.dart 는 이미 들고 있는 scenario.level 을 힌트로
넘긴다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 8: pre-runApp 병렬화 가드 재작성 — "runner 이전 await 존재" (P5-②a, 검수#11)

**Files:**
- Modify: `test/scene_asset_resolver_test.dart:47-52`
- Modify: `test/dancheong_burst_preload_contract_test.dart`

**Interfaces:**
- Produces: 두 계약 테스트가 더 이상 `'await SceneAssetResolver.load();'`/`'await DancheongBurst.preload();'` 리터럴(세미콜론 포함 완전한 단독 statement)을 문자열로 찾지 않는다 — 대신 (a) 호출이 `runner(const KoLernenApp())` 이전에 등장하고 (b) 그 호출이 `await` 로 다스려짐(단독 `await X();` 이거나 `await Future.wait([...])` 안)을 확인한다. Task 9가 `Future.wait` 로 묶어도 이 두 테스트는 계속 통과한다.

**왜 먼저 재작성하는가:** 두 테스트는 지금 `source.indexOf('await SceneAssetResolver.load();')`/`'await DancheongBurst.preload();'` 처럼 완전한 단독 문장을 리터럴로 찾는다. Task 9에서 `await Future.wait([SceneAssetResolver.load(), DancheongBurst.preload()]);` 로 묶으면 이 정확한 리터럴이 사라져(각 호출 앞에 `await` 도 없고 뒤에 `;` 도 없다) 두 테스트가 실제로는 안전한 리팩터인데도 실패한다. 계약의 **의도**(첫 프레임 전에 반드시 끝난다)는 안 바뀌므로, 검사 방식만 리팩터에 안전하게 먼저 바꾼다.

- [ ] **Step 1: 현재 동작 확인(베이스라인)** — `flutter test test/scene_asset_resolver_test.dart test/dancheong_burst_preload_contract_test.dart` 를 실행해 지금 GREEN 인지 확인한다(리팩터 전이므로 당연히 GREEN 이어야 한다 — 이 스텝은 "이후 실패했다면 내가 깬 것"을 구분하기 위한 기준선이다).

- [ ] **Step 2: `test/scene_asset_resolver_test.dart:47-52` 재작성.** 해당 test 블록(45-53번 줄 근방, `source.indexOf` 두 줄)을 찾아 교체:

```dart
      final source = File('lib/main.dart').readAsStringSync();
      final runnerMatch = RegExp(
        r'runner\(\s*const\s+KoLernenApp\(\)\s*\)',
      ).firstMatch(source);
      expect(
        runnerMatch,
        isNotNull,
        reason: 'lib/main.dart 에서 KoLernenApp 을 띄우는 지점을 찾지 못했다.',
      );
      final beforeRunner = source.substring(0, runnerMatch!.start);

      const call = 'SceneAssetResolver.load()';
      expect(
        beforeRunner.contains(call),
        isTrue,
        reason: '$call 호출이 runner(const KoLernenApp()) 이전에 있어야 한다.',
      );

      // §W2-Task8 (검수#11): "runner 이전 await 존재" 계약 — 단독
      // await 문이든 Future.wait([...]) 병렬 실행이든, 이 호출이 반드시
      // await 로 다스려져야 한다(fire-and-forget 이면 첫 프레임 전 완료를
      // 보장 못 한다). 리터럴 세미콜론 문장을 통째로 찾지 않아 병렬화
      // 리팩터에도 안전하다.
      final awaited = RegExp(
        r'await\s+(?:Future\.wait\(\s*\[[\s\S]*?' +
            RegExp.escape(call) +
            r'|' +
            RegExp.escape(call) +
            r')',
      ).hasMatch(beforeRunner);
      expect(
        awaited,
        isTrue,
        reason: '$call 는 await 되어야 한다(직접 또는 Future.wait 안에서).',
      );
```

(`import 'dart:io';` 는 이미 파일에 있을 것 — 없으면 추가.)

- [ ] **Step 3: `test/dancheong_burst_preload_contract_test.dart` 재작성.** 전체 `test(...)` 블록(14-44번 줄)을 교체:

```dart
  test(
    'burst sheets finish preloading before the first app frame '
    '(runner 이전 await 존재 계약 — 병렬화 리팩터에 안전)',
    () {
      final source = File('lib/main.dart').readAsStringSync();

      final launch = RegExp(
        r'(runApp|runner)\(\s*const\s+KoLernenApp\(\)\s*\)',
      ).firstMatch(source);
      expect(
        launch,
        isNotNull,
        reason: 'lib/main.dart 에서 KoLernenApp 을 띄우는 지점을 찾지 못했다.',
      );
      final beforeLaunch = source.substring(0, launch!.start);

      const call = 'DancheongBurst.preload()';
      expect(
        beforeLaunch.contains(call),
        isTrue,
        reason:
            '$call 호출이 실앱 실행(runApp/runner) 이전에 있어야 한다. '
            '없으면 첫 축하가 절차적 폴백으로 떨어진다.',
      );

      final awaited = RegExp(
        r'await\s+(?:Future\.wait\(\s*\[[\s\S]*?' +
            RegExp.escape(call) +
            r'|' +
            RegExp.escape(call) +
            r')',
      ).hasMatch(beforeLaunch);
      expect(
        awaited,
        isTrue,
        reason: '$call 는 await 되어야 한다(직접 또는 Future.wait 안에서).',
      );

      // UxPreviewApp 조기 반환 경로는 프리로드 앞에 있어도 된다(디버그
      // 갤러리). 그 경로까지 순서를 강제하면 갤러리 기동이 불필요하게
      // 느려진다.
    },
  );
```

- [ ] **Step 4: 재작성 후에도 GREEN 확인(리팩터 전 코드 기준)** — `flutter test test/scene_asset_resolver_test.dart test/dancheong_burst_preload_contract_test.dart`. 현재 `lib/main.dart` 는 아직 `await SceneAssetResolver.load();`/`await DancheongBurst.preload();` 단독 문장 그대로이므로, 새 정규식도 이 형태를 `await X()` 케이스로 매치해 여전히 통과해야 한다.

- [ ] **Step 5: `flutter analyze` 0** 확인.

- [ ] **Step 6: 커밋** — `git add test/scene_asset_resolver_test.dart test/dancheong_burst_preload_contract_test.dart && git commit -m "$(cat <<'EOF'
test(main): pre-runApp 가드를 '리터럴 문장' 대신 '순서+await 존재'로 재작성 (검수#11)

scene_asset_resolver_test.dart 와 dancheong_burst_preload_contract_test.dart
가 lib/main.dart 소스에서 완전한 단독 문장(`await X();`)을 문자열로 찾고
있었다 — 다음 태스크(P5-2b)에서 두 호출을 Future.wait([...]) 로 묶으면
이 정확한 리터럴이 사라져 안전한 리팩터인데도 실패했을 것이다. 계약의
실제 의도(runner 이전에 반드시 await 로 완료됨)만 검사하도록 정규식을
바꿔, 단독 await 문과 Future.wait 병렬 실행 둘 다 통과하게 했다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 9: pre-runApp 병렬화 — `SceneAssetResolver.load()` ∥ `DancheongBurst.preload()` (P5-②b)

**Files:**
- Modify: `lib/main.dart:195-205`

**Interfaces:**
- Consumes: Task 8이 재작성한 두 계약 테스트(`test/scene_asset_resolver_test.dart`, `test/dancheong_burst_preload_contract_test.dart`) — 이 태스크의 변경이 그 테스트를 GREEN 으로 유지해야 한다.

- [ ] **Step 1: 실행해 베이스라인 확인** — `flutter test test/scene_asset_resolver_test.dart test/dancheong_burst_preload_contract_test.dart` (Task 8 직후라 GREEN).

- [ ] **Step 2: 구현.** `lib/main.dart:195-205` — 현재:

```dart
  // The resolver must finish before the first frame. Otherwise a dedicated
  // per-scenario illustration can be silently replaced by its category
  // fallback for the lifetime of the already-built screen.
  // (계약: test/scene_asset_resolver_test.dart 가 이 순서를 고정한다.)
  await SceneAssetResolver.load();

  // 정답 축하 스프라이트(복주머니·엽전)를 첫 프레임 전에 디코딩한다.
  // 새 설치 직후 첫 정답도 Satz 전용 6배 시트를 쓰도록 완료를 기다린다.
  // 에셋 실패는 preload 내부에서 기록하고 절차적 burst로 안전하게 폴백한다.
  // (계약: test/dancheong_burst_preload_contract_test.dart 가 이 순서를 고정한다.)
  await DancheongBurst.preload();
```

를 아래로 교체:

```dart
  // 두 준비 작업 모두 첫 프레임 전에 끝나야 하지만 서로 의존하지 않는다
  // (하나는 에셋 매니페스트 조회, 하나는 스프라이트 시트 디코딩) — 순차
  // await 대신 병렬로 실행해 콜드스타트를 단축한다.
  // 리졸버가 안 끝나면 전용 시나리오 일러스트가 카테고리 폴백으로 조용히
  // 대체된 채 이미 빌드된 화면 생애주기 내내 유지될 수 있고, 프리로드가
  // 안 끝나면 첫 축하가 절차적 폴백으로 떨어진다 — 그래서 runner() 전에
  // **둘 다** await 된다.
  // (계약: test/scene_asset_resolver_test.dart · test/dancheong_burst_preload_contract_test.dart
  // 가 "runner 이전 await 존재"로 이 순서를 고정한다 — Task 8 참조.)
  await Future.wait<void>([
    SceneAssetResolver.load(),
    DancheongBurst.preload(),
  ]);
```

- [ ] **Step 3: GREEN 확인** — `flutter test test/scene_asset_resolver_test.dart test/dancheong_burst_preload_contract_test.dart`

- [ ] **Step 4: 전체 스모크** — `flutter test test/main_test.dart` 또는 `grep -rl "launchKoLernenApp\|_startProductionApplication" test/` 로 관련 테스트를 찾아 실행. main.dart 관련 다른 테스트(예: UX 프리뷰 게이트)가 있으면 함께 확인.

- [ ] **Step 5: `flutter analyze` 0** 확인.

- [ ] **Step 6: 커밋** — `git add lib/main.dart && git commit -m "$(cat <<'EOF'
perf(startup): SceneAssetResolver.load() ∥ DancheongBurst.preload() 병렬화 (P5-2)

두 pre-runApp 준비 작업이 서로 의존하지 않는데도 순차 await 되고 있었다.
Future.wait 로 병렬 실행해 첫 프레임까지의 대기 시간을 두 작업 중 더 느린
쪽 하나로 줄인다. Task 8에서 먼저 재작성한 "runner 이전 await 존재" 계약
테스트가 이 리팩터를 계속 GREEN 으로 지킨다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

### Task 10: Android 12+ 스플래시 아이콘 세이프존 재제작 (P5-③, 검수#26)

**Files:**
- Create: `assets/icons/HanLogo_android12_safe.png` (신규 — 1152×1152, 안전영역 패딩)
- Modify: `pubspec.yaml:250-259` (`flutter_native_splash.android_12.image`)
- Modify: `android/app/src/main/res/values-v31/styles.xml` (재생성 결과 검토 후 화이트리스트 속성 재적용)
- Modify: `android/app/src/main/res/values-night-v31/styles.xml` (동일)
- Create: `tool/pad_android12_splash_icon.py` (재현 가능한 패딩 스크립트 — 향후 아이콘 교체 시 재사용)

**배경(2회 회귀 이력 — `android/app/src/main/res/values-v31/styles.xml` 주석):** 2026-06-05 와 2026-08-10 두 번 모두 `android:windowSplashScreenAnimatedIcon`(+ background)을 다시 추가했다가, Android 12+ OS 가 강제하는 아이콘-세이프존 원형/사각 마스크가 `android12splash.png`(당시 풀-블리드 아트웍)를 잘라 "로고 윗부분 한 조각만 보이는" 크롭 회귀가 재현돼 둘 다 되돌렸다. **현재 확인된 원인:** `pubspec.yaml` 의 `flutter_native_splash.android_12.image` 가 `assets/icons/HanLogo.png`(1024×1024, PIL 로 실측한 결과 로고가 캔버스 전체를 채우는 풀-블리드 아트웍)를 그대로 가리키고 있다 — OS 세이프존(전체 캔버스의 안쪽 ~66% 지름 원)을 고려한 여백이 없다. 이 태스크는 **별도의, 여백이 있는 아이콘 에셋**을 만들어 `android_12.image` 에만 연결한다 — 일반 스플래시(`flutter_native_splash.image`)는 세이프존 제약이 없는 Android <12/iOS 용이라 기존 `HanLogo.png`(풀-블리드) 그대로 둔다.

- [ ] **Step 1: 현재 자산 실측 — 회귀 재현 여부를 코드로 먼저 확인.** `python -c` 로 확인(패딩 전 상태를 기록해 Step 2의 전/후 비교 기준으로 삼는다):

```bash
python -c "
from PIL import Image
im = Image.open('assets/icons/HanLogo.png')
print('HanLogo.png size:', im.size)
bbox = im.getchannel('A').getbbox()
print('non-transparent bbox:', bbox)
w, h = im.size
if bbox:
    content_w = bbox[2] - bbox[0]
    print('content fraction of width:', content_w / w)
"
```

(예상: `content fraction of width` 가 0.9 이상 — 즉 로고 내용이 캔버스 가장자리까지 거의 꽉 차 있다. 이게 크롭 회귀의 직접 원인이다.)

- [ ] **Step 2: 패딩 스크립트 작성.** `tool/pad_android12_splash_icon.py` 신규 생성:

```python
#!/usr/bin/env python3
"""Android 12+ 스플래시 아이콘 세이프존 패딩.

OS 가 android:windowSplashScreenAnimatedIcon 에 강제하는 세이프존은 전체
캔버스 대비 약 2/3 지름의 원형/사각 마스크다(공식 권장: 콘텐츠를 캔버스의
약 55~60% 폭 안에 배치). 이 스크립트는 기존 풀-블리드 아이콘을 투명
패딩으로 감싸 1152x1152 캔버스 중앙에, 콘텐츠 폭이 캔버스의 CONTENT_RATIO
만큼만 차지하도록 다시 그린다.

실행: python tool/pad_android12_splash_icon.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

SOURCE = Path("assets/icons/HanLogo.png")
OUTPUT = Path("assets/icons/HanLogo_android12_safe.png")
CANVAS_SIZE = 1152
# 세이프존 안쪽으로 여유를 두기 위해 55% — 구글 권장 상한(~66%)보다
# 보수적으로 잡아 2회 회귀 재발을 방지한다.
CONTENT_RATIO = 0.55


def build_safe_icon() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    content_side = int(CANVAS_SIZE * CONTENT_RATIO)
    resized = source.resize((content_side, content_side), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    offset = ((CANVAS_SIZE - content_side) // 2, (CANVAS_SIZE - content_side) // 2)
    canvas.paste(resized, offset, resized)
    canvas.save(OUTPUT)

    bbox = canvas.getchannel("A").getbbox()
    assert bbox is not None, "패딩 후 콘텐츠가 사라졌다"
    content_w = bbox[2] - bbox[0]
    fraction = content_w / CANVAS_SIZE
    print(f"{OUTPUT}: {canvas.size}, content fraction of width = {fraction:.3f}")
    assert fraction <= 0.6, (
        f"콘텐츠가 세이프존을 넘을 수 있다(fraction={fraction:.3f} > 0.6) — "
        "CONTENT_RATIO 를 낮춰라."
    )


if __name__ == "__main__":
    build_safe_icon()
```

- [ ] **Step 3: 실행 + 자가 검증.**

```bash
python tool/pad_android12_splash_icon.py
python -c "
from PIL import Image
im = Image.open('assets/icons/HanLogo_android12_safe.png')
print('size:', im.size)
bbox = im.getchannel('A').getbbox()
print('non-transparent bbox:', bbox)
print('content fraction of width:', (bbox[2]-bbox[0]) / im.size[0])
"
```

예상: `size: (1152, 1152)`, `content fraction of width` 가 0.55 근방(≤0.6) — 이전 스텝 1의 0.9+ 대비 실제 여백이 생겼음을 수치로 확인.

- [ ] **Step 4: `pubspec.yaml` 배선.** `flutter_native_splash.android_12.image`(258번 줄)를 새 에셋으로 교체:

```yaml
  android_12:
    image: assets/icons/HanLogo_android12_safe.png
    color: "#FAF6EC"
```

(`image:`(254번 줄, 일반 스플래시)는 그대로 `assets/icons/HanLogo.png` 유지 — 세이프존 제약이 없는 경로다.) `flutter pub get` 는 에셋 경로 변경만으로는 불필요하지만, `pubspec.yaml` 의 `assets:` 목록에 `assets/icons/` 전체가 이미 포함돼 있는지 확인한다:

```bash
grep -n "assets/icons" pubspec.yaml
```

포함돼 있지 않고 개별 파일 나열 방식이면 `assets/icons/HanLogo_android12_safe.png` 항목을 추가한다.

- [ ] **Step 5: `flutter_native_splash:create` 실행 — 재적용 목록 사전 기록.** 실행 **전에** 현재 화이트리스트 속성값을 기록해 둔다(재생성이 스타일 블록 전체를 템플릿으로 덮어쓰므로, 실행 후 diff 와 대조하기 위해):

```bash
grep -n "forceDarkAllowed\|windowFullscreen\|windowDrawsSystemBarBackgrounds\|windowLayoutInDisplayCutoutMode" \
  android/app/src/main/res/values/styles.xml \
  android/app/src/main/res/values-v31/styles.xml \
  android/app/src/main/res/values-night/styles.xml \
  android/app/src/main/res/values-night-v31/styles.xml
```

그 다음 실행:

```bash
flutter pub run flutter_native_splash:create
```

- [ ] **Step 6: `git diff` 필수 리뷰 — 재적용 목록.** 마스터 플랜 검수#26 이 명시한 대로, 스플래시 2항목(`windowSplashScreenBackground`/`windowSplashScreenAnimatedIcon`) 외에 아래 4개 속성이 `values/`·`values-v31/`(그리고 존재한다면 `values-night/`·`values-night-v31/`) 양쪽에서 **살아남았는지** 확인한다:

```bash
git diff android/app/src/main/res/values/styles.xml
git diff android/app/src/main/res/values-v31/styles.xml
git diff android/app/src/main/res/values-night/styles.xml
git diff android/app/src/main/res/values-night-v31/styles.xml
git diff android/app/src/main/AndroidManifest.xml
```

- `android:forceDarkAllowed="false"` — 4개 styles.xml 전부
- `android:windowFullscreen="false"` — 4개 전부
- `android:windowDrawsSystemBarBackgrounds="false"` — 4개 전부
- `android:windowLayoutInDisplayCutoutMode="shortEdges"` — 4개 전부
- `AndroidManifest.xml` 의 `io.flutter.embedding.android.EnableImpeller` = `false` 메타데이터(47-50번 줄) — **변경 없어야 함**(Global Constraints)

`flutter_native_splash:create` 가 위 속성 중 하나라도 지웠다면, 그 `<style>` 블록에 **수동으로 다시 추가**한다(Step 2에서 기록해 둔 값 그대로). `values-v31/styles.xml` 의 기존 회귀 이력 주석(1-20번 줄)은 **삭제하지 않고 유지**한 뒤, 그 아래에 이번 변경을 이어 기록한다:

```xml
             2026-08-26(W2 Task 10): 세이프존 패딩된 HanLogo_android12_safe.png
             (tool/pad_android12_splash_icon.py, content fraction ≈0.55)로
             flutter_native_splash:create 재실행 — 위 두 속성을 다시 켰다.
             실기기 검증 전까지 이 커밋은 잠정이다: 아래 "Jin 게이트" 완료
             전에는 릴리즈 빌드에 포함하지 않는다. -->
```

- [ ] **Step 7: `flutter analyze` 0** 확인.

- [ ] **Step 8: 실기기 검증 체크리스트 — Jin 게이트(이 세션에서는 실행 불가, 커밋에 포함하되 완료로 표시하지 않는다).** `docs/data/coldstart_benchmark.md`(Task 1에서 생성)의 "Jin 게이트" 섹션에 아래 항목을 추가한다:

```markdown

## Android 12+ 스플래시 아이콘 세이프존 — Jin 실기기 게이트 (Task 10)

- [ ] Android 12+ 실기기(예: 기존 회귀 재현 기기 M2101K6G)에서 콜드스타트 시
      로고가 잘리지 않고 전체가 보인다
- [ ] 라이트/다크 모드 양쪽에서 확인
- [ ] 흰 플래시(레이아웃 전환 시 배경색 불일치) 없음 — 배경은 시스템
      스플래시·Flutter 스플래시(Task 6, #FAF6EC)·NormalTheme 배경 3곳 모두
      시각적으로 이어져야 한다
- [ ] 문제가 재현되면 `values-v31/styles.xml`/`values-night-v31/styles.xml`
      에서 `windowSplashScreenBackground`/`windowSplashScreenAnimatedIcon`
      2개 속성만 롤백(다른 4개 화이트리스트 속성은 유지)하고, CONTENT_RATIO
      를 `tool/pad_android12_splash_icon.py` 에서 더 낮춰 재시도
```

- [ ] **Step 9: 커밋(잠정 — Jin 게이트 대기 상태로 명시).** `git add assets/icons/HanLogo_android12_safe.png pubspec.yaml android/app/src/main/res/values-v31/styles.xml android/app/src/main/res/values-night-v31/styles.xml android/app/src/main/res/values/styles.xml android/app/src/main/res/values-night/styles.xml tool/pad_android12_splash_icon.py docs/data/coldstart_benchmark.md && git commit -m "$(cat <<'EOF'
perf(android): 세이프존 패딩된 Android12+ 스플래시 아이콘 재제작 (P5-3, 검수#26)

기존 android_12.image(HanLogo.png)가 풀-블리드 아트웍이라 OS 세이프존
마스크에 잘리는 게 2회(2026-06-05, 2026-08-10) 회귀의 실제 원인이었다.
tool/pad_android12_splash_icon.py 로 콘텐츠를 캔버스의 ~55% 폭 안에 두는
HanLogo_android12_safe.png(1152x1152)를 만들어 android_12.image 에만
연결했다(일반 image 는 세이프존 제약이 없어 풀-블리드 HanLogo.png 유지).
flutter_native_splash:create 재실행 후 클리어된 forceDarkAllowed 등 4개
화이트리스트 속성을 values/·values-v31/(+night 변형) 양쪽에 재적용했다.

실기기 미검증 — docs/data/coldstart_benchmark.md 의 Jin 게이트 체크리스트
완료 전까지 릴리즈 빌드에 포함하지 않는다.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"`

---

## Self-Review 결과

- **스펙 커버:** P4 5건 전부 대응(Task 2=①리시트, Task 3=②탭lazy, Task 4=③파싱호이스트, Task 5=④aspectRatio메모, Task 6=⑤스플래시게이트) / P5 3건 전부 대응(Task 7=①ScenarioLoader, Task 8+9=②pre-runApp 병렬화 2태스크 분할[검수#11 그대로 반영], Task 10=③Android12 아이콘) / 계측(Task 1) / 검수#7(Task 2 Completer 레이스 테스트) / 검수#26 재적용 목록(Task 10 Step 6)
- **스펙 정정 1건(투명 기록):** 마스터 플랜 "P4-④ silben_kreuz_screen `_cellAspectRatio`" 는 실제로는 `sori_stage_catalog_screen.dart` 에만 존재(전수 grep 확인) — Task 5에 정정 사유를 명시하고 실제 위치로 대상을 바꿨다.
- **플레이스홀더 스캔:** "TBD"는 `docs/data/coldstart_benchmark.md`(Task 1) 표 안에만 있고 — 이는 실기기 접근이 없는 이 세션이 채울 수 없는 실측값이라고 명시적으로 문서화한 것이지, 코드/테스트 스텝의 미완성이 아니다. 코드·테스트 스텝은 전부 실행 가능한 실제 코드를 포함한다.
- **시그니처 일관성:** `SoriStageLocalBeforeFields`/`SoriStageNetworkBeforeFields`(Task 2 정의) → `SoriStageProgressionService.captureLocalBeforeFields`/`loadNetworkBeforeFields`(같은 Task, 같은 타입 사용) → `SoriStageRewardReceiptService.capture()` 옵션널 파라미터(같은 Task, 같은 타입) 까지 동일 이름·타입으로 통일 확인. `ScenarioLoader._parseShard`(Task 7)의 반환 타입 `(List<Scenario>, int)` 이 `load()`/`loadLevel()` 양쪽 호출부와 일치. `SplashGate.ready`/`markReady()`(Task 6)가 `SplashScreen` 의 `readyGate` 훅과 `main.dart` 배선 양쪽에서 같은 이름으로 쓰임.
- **실행 순서:** Task 1(계측 문서, 독립) → Task 2/3/4/5/6(P4, 파일 교집합 없음 — 병렬 가능) → Task 7(P5, 독립) → Task 8(가드 재작성, **Task 9보다 반드시 먼저**) → Task 9(병렬화, Task 8 의존) → Task 10(P5 Android, 독립, PIL 확인됨 v11.3.0). Task 8→9 순서를 어기면 Task 9 커밋 시 두 계약 테스트가 실패한다.
- **계약 무변경 확인:** `learn_session_queue`/`course_mastery`/`audio_policy_guard`/`typography_guard`/`arb_l10n_guard` 대상 파일(각각 `lib/services/learn_session_queue.dart`, `lib/services/course_mastery_service.dart`, 오디오/타이포/l10n 관련 파일) 중 이 웨이브가 수정하는 파일과 교집합 없음 — 이 플랜이 만지는 파일은 `sori_stage_*`, `storage_service.dart`(scenarioStars/completedScenarios 만), `scenario_loader.dart`, `scenario_player_screen.dart`/`scenarios_list_screen.dart`(open 경로만), `splash_screen.dart`/`splash_gate.dart`, `main.dart`(pre-runApp 구간만), Android `styles.xml`/`pubspec.yaml`(스플래시 설정만) 뿐이다.
