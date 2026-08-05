# Study → Sarangbang/Hanok → Reward loop repair (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Studying (e.g. clearing vocab packs from the Sarangbang) must produce and surface the bojagi rewards the learner has actually earned, without ever opening the Quests screen, and refresh reliably.

**Architecture:** Add one thin, idempotent seam (`QuestTracker.syncEarnedRewards`) that recomputes quests and persists new completions, and call it from the two study-return surfaces (Home `_refreshHome`, Sarangbang `_load`). Surface waiting bojagi as a content card (`PendingRewardCard`) on Home and Sarangbang, gated on the existing `DecorationRewardService.openableBoxCount()`. Make Home refresh on app-resume. The existing serial mutation queue and claim journal in `DecorationRewardService` are untouched.

**Tech Stack:** Flutter/Dart, SharedPreferences (`Storage`), Flutter localizations (ARB + `flutter gen-l10n`).

## Global Constraints

- New user-facing strings live in BOTH `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb`; keep DE=EN key parity; run `flutter gen-l10n` after editing. DE is the primary language.
- No em-dash and no markdown in user-facing DE/EN copy.
- The reward card is a **content card (`SoriCard`), not an iOS-style numeric badge** (Jin's standing preference).
- Do NOT modify `DecorationRewardService`'s serial queue (`_serialize`) or the claim journal; the crash-safety and no-double-grant invariants must remain intact.
- Every new call site is best-effort and non-blocking: a failure in the sync seam or a read failure in the card must never throw into the widget tree.
- `if/else` always uses braces (project Dart rule). Run `dart format` before committing.
- Commit only the files each task lists. Do NOT push (Jin pushes explicitly). Record the change in `AGENTS.md` session log as a follow-up.

---

### Task 1: `QuestTracker.syncEarnedRewards()` seam + best-effort social hardening

The only producer of a pending bojagi is `DecorationRewardService.ensurePendingBoxForQuest()`, whose only caller is `QuestTracker.persistNewCompletions()`, itself only called from `QuestsScreen`. This task adds a screen-agnostic seam and makes the local reward survive an unavailable social layer.

**Files:**
- Modify: `lib/services/quest_tracker.dart` (add `syncEarnedRewards`; harden the two `GyeService` calls in `persistNewCompletions`)
- Test: `test/quest_tracker_sync_test.dart`

**Interfaces:**
- Consumes: `QuestTracker.computeAll({DateTime? now}) → Future<List<QuestProgress>>`; `QuestTracker.persistNewCompletions(List<QuestProgress>) → Future<void>`; `DecorationRewardService.ensurePendingBoxForQuest(String) → Future<void>`; `Storage.pendingBoxes → List<String>`; `Storage.questCompletions → Map<String,String>`; `kQuestById` (from `data/quest_catalog.dart`).
- Produces: `QuestTracker.syncEarnedRewards() → Future<void>` (best-effort; never throws).

- [ ] **Step 1: Write the failing test**

```dart
// test/quest_tracker_sync_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/services/quest_tracker.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('persistNewCompletions enqueues one bojagi for a freshly completed '
      'quest, marks it, and is idempotent', () async {
    final questId = kQuestById.keys.first;
    final done = QuestProgress(
      questId: questId,
      current: 1,
      target: 1,
      active: true,
      completed: true,
      completedAtIso: null,
    );

    await QuestTracker.persistNewCompletions([done]);
    expect(Storage.pendingBoxes, contains(questId));
    expect(Storage.questCompletions.containsKey(questId), isTrue);

    final boxes = Storage.pendingBoxes.length;
    // Second run: the quest is now marked (completedAtIso != null), so nothing
    // new is granted.
    final again = QuestProgress(
      questId: questId,
      current: 1,
      target: 1,
      active: true,
      completed: true,
      completedAtIso: Storage.questCompletions[questId],
    );
    await QuestTracker.persistNewCompletions([again]);
    expect(Storage.pendingBoxes.length, boxes);
  });

  test('syncEarnedRewards never throws and is idempotent on a clean state',
      () async {
    await QuestTracker.syncEarnedRewards();
    final boxes = Storage.pendingBoxes.length;
    await QuestTracker.syncEarnedRewards();
    expect(Storage.pendingBoxes.length, boxes);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/quest_tracker_sync_test.dart`
Expected: FAIL — `syncEarnedRewards` is undefined; the first test may also throw from an unguarded `GyeService` call.

- [ ] **Step 3: Harden the social calls in `persistNewCompletions`**

In `lib/services/quest_tracker.dart`, the loop already writes the reward box and the completion marker BEFORE broadcasting. Wrap only the social broadcast so an unavailable Gye/Firebase layer never loses a locally-earned reward. Replace the broadcast line inside the loop:

```dart
        await DecorationRewardService.ensurePendingBoxForQuest(p.questId);
        await Storage.markQuestCompleted(p.questId);
        // 2픽: 방금 완료한 퀘스트를 계 피드에 broadcast (축하 유도) — best-effort.
        // 보상 상자·완료 마커는 위에서 이미 로컬에 기록됐으므로, 소셜 계층이
        // 없거나 실패해도 학습 보상은 유실되지 않는다.
        try {
          await GyeService.broadcastFeed(
            GyeFeedType.questCompleted,
            {'questId': p.questId},
          );
        } catch (_) {
          // Offline / not signed in: the reward already persisted.
        }
```

And wrap the trailing level-up sync:

```dart
    // 2픽: 레벨업도 계 피드에 동기화 (순환 회피 — 여기서 pull) — best-effort.
    try {
      await GyeService.syncLevelUp();
    } catch (_) {
      // Social sync is optional for the local reward loop.
    }
```

- [ ] **Step 4: Add the `syncEarnedRewards` seam**

Add this static method to `QuestTracker` (e.g. directly after `persistNewCompletions`):

```dart
  /// Screen-agnostic reward sync: recompute quests and persist any newly
  /// reached completions so studying alone produces the bojagi the learner
  /// earned, without opening the Quests screen. Best-effort: it swallows its
  /// own errors so a UI caller (Home, Sarangbang) can await it unconditionally.
  /// Idempotent — [persistNewCompletions] only acts on quests reached for the
  /// first time, and [DecorationRewardService.ensurePendingBoxForQuest] refuses
  /// duplicates, so running it from several surfaces cannot double-grant.
  static Future<void> syncEarnedRewards() async {
    try {
      final progresses = await computeAll();
      await persistNewCompletions(progresses);
    } catch (_) {
      // Non-blocking: a reward-sync failure must never surface to the UI.
    }
  }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/quest_tracker_sync_test.dart`
Expected: PASS (both tests).

- [ ] **Step 6: Commit**

```bash
git add lib/services/quest_tracker.dart test/quest_tracker_sync_test.dart
git commit -m "feat(rewards): add QuestTracker.syncEarnedRewards seam + best-effort social sync"
```

---

### Task 2: Call the seam from Home and Sarangbang study-return points

`QuestsScreen` keeps its existing explicit flow (it renders the progress list). Home and Sarangbang gain the seam so returning from a learning route produces earned rewards.

**Files:**
- Modify: `lib/screens/home_screen.dart` (inside `_refreshHome`, ~line 308)
- Modify: `lib/screens/sarangbang_screen.dart` (inside `_load`, before the `setState`)

**Interfaces:**
- Consumes: `QuestTracker.syncEarnedRewards()` (Task 1).

- [ ] **Step 1: Wire Home**

In `lib/screens/home_screen.dart`, add the import if missing:

```dart
import '../services/quest_tracker.dart';
```

At the very start of `_refreshHome()` (before `_loadToday` / `_loadPath` / `_loadHanokPreview`), run the seam so a produced bojagi is visible on the same refresh:

```dart
    // Studying returns to Home; surface any bojagi earned since last refresh.
    await QuestTracker.syncEarnedRewards();
```

- [ ] **Step 2: Wire Sarangbang**

In `lib/screens/sarangbang_screen.dart`, add the import:

```dart
import '../services/quest_tracker.dart';
```

In `_load()`, immediately after `final snapshot = await load();` and before reading the room snapshot, run the seam:

```dart
      // A study route just returned; produce any newly earned bojagi.
      await QuestTracker.syncEarnedRewards();
```

- [ ] **Step 3: Verify the app still analyzes and existing screen tests pass**

Run: `flutter analyze lib/screens/home_screen.dart lib/screens/sarangbang_screen.dart`
Expected: No issues.
Run: `flutter test test/screen_smoke_test.dart`
Expected: PASS (Home + Sarangbang still build; the seam is best-effort).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/home_screen.dart lib/screens/sarangbang_screen.dart
git commit -m "feat(rewards): sync earned bojagi when returning to Home/Sarangbang"
```

---

### Task 3: `PendingRewardCard` widget + ARB copy

A learner must SEE "you have a bundle" where they study. This is a content card gated on `DecorationRewardService.openableBoxCount()` (which already excludes corrupted/unknown-quest boxes).

**Files:**
- Create: `lib/widgets/sori/pending_reward_card.dart`
- Modify: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`
- Test: `test/widgets/pending_reward_card_test.dart`

**Interfaces:**
- Consumes: `DecorationRewardService.openableBoxCount({Iterable<String>? pending}) → int`; `Storage.pendingBoxes → List<String>`; `Storage.addPendingBox(String) → Future<void>`; `SoriCard`, `SoriColors`, `Spacing`, `SoriTextTheme` (from `widgets/sori/`); generated `AppL10n` getters `pendingRewardTitle`, `pendingRewardBody(int count)`, `pendingRewardOpen`.
- Produces: `PendingRewardCard({Key? key, Future<void> Function()? onOpened})` — a `StatelessWidget` that renders nothing (`SizedBox.shrink`) when the openable count is 0, otherwise a tappable `SoriCard`; tapping pushes `/bojagi` and awaits it, then calls `onOpened`.

- [ ] **Step 1: Add ARB keys (DE)**

In `lib/l10n/app_de.arb` add:

```json
  "pendingRewardTitle": "Belohnung wartet",
  "pendingRewardBody": "{count, plural, one{1 Bojagi zum Öffnen} other{{count} Bojagi zum Öffnen}}",
  "@pendingRewardBody": {
    "placeholders": { "count": { "type": "int" } }
  },
  "pendingRewardOpen": "Öffnen",
```

- [ ] **Step 2: Add ARB keys (EN)**

In `lib/l10n/app_en.arb` add:

```json
  "pendingRewardTitle": "Reward waiting",
  "pendingRewardBody": "{count, plural, one{1 bojagi to open} other{{count} bojagi to open}}",
  "@pendingRewardBody": {
    "placeholders": { "count": { "type": "int" } }
  },
  "pendingRewardOpen": "Open",
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: clean; `AppL10n.pendingRewardTitle`, `AppL10n.pendingRewardBody(int)`, `AppL10n.pendingRewardOpen` now exist.

- [ ] **Step 4: Write the failing widget test**

```dart
// test/widgets/pending_reward_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/pending_reward_card.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('de'),
      routes: {
        '/bojagi': (_) => const Scaffold(body: Text('bojagi-screen')),
      },
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hides when there are no openable boxes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_host(const PendingRewardCard()));
    await tester.pumpAndSettle();
    expect(find.text('Belohnung wartet'), findsNothing);
  });

  testWidgets('shows and navigates to /bojagi when a box is waiting',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // A real quest id is an openable box (openableBoxCount filters by
    // kQuestById.containsKey).
    await Storage.addPendingBox(kQuestById.keys.first);
    await tester.pumpWidget(_host(const PendingRewardCard()));
    await tester.pumpAndSettle();
    expect(find.text('Belohnung wartet'), findsOneWidget);
    await tester.tap(find.text('Belohnung wartet'));
    await tester.pumpAndSettle();
    expect(find.text('bojagi-screen'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run test to verify it fails**

Run: `flutter test test/widgets/pending_reward_card_test.dart`
Expected: FAIL — `PendingRewardCard` does not exist.

- [ ] **Step 6: Implement the widget**

```dart
// lib/widgets/sori/pending_reward_card.dart
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/decoration_reward_service.dart';
import 'card.dart';
import 'tokens.dart';

/// A content card that appears wherever the learner studies (Home, Sarangbang)
/// when at least one bojagi is waiting to be opened. It is a card, not a badge:
/// it names the reward and offers an explicit open action. It reads the count
/// from [DecorationRewardService.openableBoxCount], which excludes corrupted
/// boxes, so it never promises a reward the bojagi screen cannot deliver.
class PendingRewardCard extends StatelessWidget {
  const PendingRewardCard({super.key, this.onOpened});

  /// Called after the learner returns from `/bojagi`, so the host can refresh
  /// its pending state (the card hides itself once the queue is empty).
  final Future<void> Function()? onOpened;

  @override
  Widget build(BuildContext context) {
    final int count;
    try {
      count = DecorationRewardService.openableBoxCount();
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriCard(
      variant: SoriCardVariant.hanji,
      accent: SoriColors.gold,
      tinted: true,
      onTap: () async {
        await Navigator.of(context).pushNamed('/bojagi');
        final cb = onOpened;
        if (cb != null) {
          await cb();
        }
      },
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: SoriColors.gold),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.pendingRewardTitle, style: text.cardTitle),
                const SizedBox(height: 2),
                Text(t.pendingRewardBody(count), style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            t.pendingRewardOpen,
            style: text.caption.copyWith(
              color: SoriColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
```

Note: confirm `SoriCard` exposes `variant`, `accent`, `tinted`, `onTap` and that `SoriTextTheme` has `cardTitle`/`bodySmall`/`caption` (all are used this way in `sarangbang_screen.dart` and across the Sori design system). If `SoriColors.gold` differs in name, use the project's gold token from `tokens.dart`.

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test/widgets/pending_reward_card_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/sori/pending_reward_card.dart lib/l10n/app_de.arb lib/l10n/app_en.arb lib/l10n/generated/ test/widgets/pending_reward_card_test.dart
git commit -m "feat(rewards): PendingRewardCard content card + DE/EN copy"
```

---

### Task 4: Place `PendingRewardCard` on Home and Sarangbang

**Files:**
- Modify: `lib/screens/home_screen.dart` (in the Home scroll body, directly under the mission hero)
- Modify: `lib/screens/sarangbang_screen.dart` (in the ListView, under `_SarangbangWelcome`)

**Interfaces:**
- Consumes: `PendingRewardCard` (Task 3).

- [ ] **Step 1: Add the card to Sarangbang**

In `lib/screens/sarangbang_screen.dart`, import:

```dart
import '../widgets/sori/pending_reward_card.dart';
```

In the `ListView` children, insert immediately after `const _SarangbangWelcome(),` and its trailing `SizedBox`:

```dart
                        PendingRewardCard(onOpened: _load),
                        const SizedBox(height: Spacing.lg),
```

- [ ] **Step 2: Add the card to Home**

In `lib/screens/home_screen.dart`, import:

```dart
import '../widgets/sori/pending_reward_card.dart';
```

Insert `PendingRewardCard(onOpened: _refreshHome)` directly under the mission hero widget in the Home scroll body (the same block that holds the `/sarangbang` mission CTA, ~line 453). Add a `SizedBox(height: Spacing.md)` below it to match the surrounding rhythm.

- [ ] **Step 3: Widget tests for visibility on both surfaces**

Add to `test/screen_smoke_test.dart` (or a new `test/pending_reward_placement_test.dart`) two cases: with `SharedPreferences.setMockInitialValues({})` then `await Storage.addPendingBox(kQuestById.keys.first)` the card title `Belohnung wartet` appears on Home and on Sarangbang; with `{}` and no box it does not. Pump each screen with the app's localization delegates and a `/bojagi` route stub. Keep assertions to `find.text('Belohnung wartet')`.

- [ ] **Step 4: Run tests + responsive matrix**

Run: `flutter test test/screen_smoke_test.dart test/responsive_test.dart`
Expected: PASS; no overflow at 308-1280dp and 1.3x (the card is a standard `SoriCard` row).

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_screen.dart lib/screens/sarangbang_screen.dart test/
git commit -m "feat(rewards): surface PendingRewardCard on Home and Sarangbang"
```

---

### Task 5: Refresh reliability — Home resume + post-bojagi

Close the residual staleness: a bojagi produced while backgrounded, or after opening `/bojagi`, must appear without a manual pull-to-refresh.

**Files:**
- Modify: `lib/screens/home_screen.dart` (State mixes `WidgetsBindingObserver`)

**Interfaces:**
- Consumes: `_refreshHome()` (existing); `WidgetsBinding.instance`.

- [ ] **Step 1: Make the Home State observe lifecycle**

Add `with WidgetsBindingObserver` to `_HomeScreenState`'s declaration. In `initState()` register: `WidgetsBinding.instance.addObserver(this);`. In `dispose()` (create it if absent, and call `super.dispose()` last) unregister: `WidgetsBinding.instance.removeObserver(this);`.

- [ ] **Step 2: Refresh on resume**

Add the override:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // Studied, backgrounded, reopened: pull the reward loop + growth forward.
      _refreshHome();
    }
  }
```

- [ ] **Step 3: Post-bojagi refresh**

The `PendingRewardCard(onOpened: _refreshHome)` wiring from Task 4 already refreshes Home after `/bojagi` returns. Confirm no other Home entry to `/bojagi` exists that bypasses a refresh (grep `home_screen.dart` for `/bojagi`); there is none today, so no further change.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/screens/home_screen.dart`
Expected: No issues (observer registered and disposed).
Run: `flutter test test/screen_smoke_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(rewards): refresh Home reward loop on app resume"
```

---

## Self-review (spec coverage)

- **P1-a (produce rewards from studying):** Task 1 (seam + hardening) + Task 2 (wire Home/Sarangbang). Idempotency preserved via existing guards.
- **P1-b (surface waiting bundles):** Task 3 (card + ARB, gated on `openableBoxCount`) + Task 4 (placement on Home + Sarangbang).
- **P1-c (refresh reliability):** Task 5 (resume observer) + Task 4's `onOpened` post-bojagi refresh.
- **Acceptance criteria:** (1) covered by Task 1/2; (2) Task 3/4 + `onOpened` hide-on-empty; (3) Task 5; (4) no `DecorationRewardService` queue/journal change, `openableBoxCount` de-dupes, seam idempotent; (5) Task 4 responsive/1.3x + DE/EN parity in Task 3.
- **Out of scope (Phase 2, separate spec/plan):** pack-clear = bojagi drop, continuous fractional Hanok growth, level-up celebration.

## Execution note

Phase 2 (immediate reward layer) is deliberately excluded and will get its own spec/plan.
