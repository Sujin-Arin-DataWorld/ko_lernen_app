# Hanok World System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Turn the personal Hanok into a coherent, responsive learning world while preserving the existing recommendation, mastery, reward, and Gye contracts; add safe P4b shared-exhibition dedication.

**Architecture:** First repair map targeting and centralize a read-only today-learning snapshot. Then reorganize Home, the map, and venue presentation around that snapshot without changing learning destinations. Finally add a server-authoritative Gye exhibition document with callable-only writes; personal decor ownership and room placement remain unchanged.

**Tech Stack:** Flutter/Dart, SharedPreferences, Firestore, Firebase Functions v2/Admin SDK, Firestore Rules, ARB localization, existing Sori design system, Flutter/Node/Rules tests.

## Global Constraints

- Do not change recommendMission, CourseMastery 70% evidence, existing learning routes, DecorationRewardService, or CloudSync union semantics.
- No map tap, venue view, or selection may create XP, course evidence, decor ownership, or a Gye write.
- Use existing Sori tokens/components, ARB DE/EN parity, generated l10n, 44dp minimum interaction, and the existing responsive matrix.
- Test RED before each behavioral change; run targeted analyzer/tests before committing only that task's files and matching AGENTS.md entry.
- P4b-MVP is a shared exhibition only. It must not remove local ownedDecor or private-room placement.

---

### Task 1: Make map hit targets disjoint and accessible (P0)

**Files:**
- Modify: lib/data/personal_hanok_catalog.dart
- Modify: lib/widgets/sori/personal_hanok_map.dart
- Modify: lib/screens/hanok_world_screen.dart
- Modify: lib/l10n/app_de.arb, lib/l10n/app_en.arb, generated l10n files
- Test: test/personal_hanok_catalog_test.dart, test/personal_hanok_map_test.dart, test/hanok_world_screen_test.dart

**Interfaces:**
- Add distinct hitBounds to PersonalHanokZoneDefinition; visual bounds remain for labels and animation.
- Add personalHanokAccessibleZones(projection) in catalog order with the same unlock/route behavior as painted places.
- PersonalHanokMap takes selectedZone and reports selection without overlapping gesture layers.

- [x] **Step 1: Write failing target tests.**

~~~dart
test('interactive map hit bounds are pairwise disjoint', () {
  final zones = kPersonalHanokZones.where((zone) => zone.isInteractive);
  for (final a in zones) {
    for (final b in zones.skipWhile((zone) => zone != a).skip(1)) {
      expect(a.hitBounds.overlaps(b.hitBounds), isFalse);
    }
  }
});

testWidgets('Daecheong selection is never intercepted by Anchae', (tester) async {
  PersonalHanokZone? selected;
  await tester.pumpWidget(hostMap(onSelect: (zone) => selected = zone));
  await tester.tap(daecheongHitCenter);
  expect(selected, PersonalHanokZone.daecheongmaru);
});
~~~

- [x] **Step 2: Run the catalog/map tests and confirm RED** because hitBounds and accessible zone APIs do not exist.
- [x] **Step 3: Implement the catalog and semantic controls.** Define exact non-overlapping targets from the canonical map, retain visual artwork coordinates, give every interaction an ARB semantic label, and render an accessible localized place list.
- [x] **Step 4: Add selected-place state to HanokWorldScreen.** A locked selected zone shows a milestone explanation; an unlocked selected zone exposes one text-first route CTA.
- [x] **Step 5: Verify and commit.** Flutter gen-l10n, target/world/responsive verification, and AGENTS logging completed; implementation commit:
~~~text
69dfe65 fix(hanok): make map destinations reliably tappable
~~~

### Task 2: Establish one TodayLearningSnapshot facade

**Files:**
- Create: lib/services/today_learning_snapshot.dart
- Modify: lib/services/sarangbang_study_recommendation.dart
- Modify: lib/screens/home_screen.dart
- Modify: lib/screens/sarangbang_screen.dart
- Test: test/today_learning_snapshot_test.dart, test/sarangbang_recommendation_test.dart, test/sarangbang_study_screen_test.dart

**Interfaces:**
- TodayLearningSnapshot contains the existing MissionPick, scenario metadata, presentation revision, and canonical SarangbangStudyDestination.
- TodayLearningSnapshotLoader.load() is the only production loader used by Home and Sarangbang.
- todayLearningDestinationFor(snapshot) preserves all existing pack-access and route argument behavior.

- [x] **Step 1: Write a failing pure agreement test.**

~~~dart
test('home and Sarangbang receive the same snapshot for equal inputs', () async {
  final inputs = FakeTodayLearningInputs.courseFirst();
  final home = await TodayLearningSnapshotLoader.load(inputs: inputs);
  final room = await TodayLearningSnapshotLoader.load(inputs: inputs);
  expect(home.pick, room.pick);
  expect(home.destination, room.destination);
});
~~~

- [x] **Step 2: Run snapshot/Sarangbang tests and confirm RED.**
- [x] **Step 3: Extract existing loader assembly into the facade.** Keep recommendation priority inside recommendMission. Keep SarangbangStudyRecommendation as a compatibility adapter until its callers migrate.
- [x] **Step 4: Replace Home's duplicate hero assembly and Sarangbang's direct loader.** Both refresh after a launched route returns. Verify all-done, review, scenario, pack, and course cases retain existing route behavior.
- [x] **Step 5: Verify and commit.** Targeted snapshot/Home/Sarangbang checks and AGENTS logging completed; implementation commit:
~~~text
0c8a564 feat(hanok): unify today learning snapshot
~~~

### Task 3: Recompose Home as today's Madang

**Files:**
- Modify: lib/screens/home_screen.dart
- Modify: lib/widgets/sori/mission_hero_card.dart only if it needs a presentational slot
- Modify: DE/EN ARB and generated l10n
- Test: test/home_screen_test.dart, test/screen_smoke_test.dart, test/responsive_test.dart, test/typography_guard_test.dart

**Interfaces:**
- Home ordering is Sarangbang primary, Hanok preview, then secondary routines.
- Exactly one primary study CTA goes through /sarangbang. Discovery cards remain secondary.

- [x] **Step 1: Write failing widget expectations.**

~~~dart
expect(find.byKey(const ValueKey('home-primary-sarangbang')), findsOneWidget);
expect(find.byKey(const ValueKey('home-hanok-preview')), findsOneWidget);
expect(widgetTop('home-primary-sarangbang'), lessThan(widgetTop('home-hanok-preview')));
~~~

- [x] **Step 2: Run Home tests and confirm RED.**
- [x] **Step 3: Recompose Home presentation only.** Retain tiger feedback but remove hidden whole-hero study taps. Move review, difficult words, and daily modules below the first two sections. Give the Hanok preview an explicit localized text-first route action.
- [x] **Step 4: Run flutter gen-l10n and verify no new raw text/style/icon-button regression.**
- [x] **Step 5: Verify and commit.** Home, smoke, responsive, typography, analyzer, and AGENTS logging completed; implementation commit:
~~~text
a4b3411 feat(home): make the Sarangbang today's study context
~~~

### Task 4: Build WorldMapViewport and the place panel

**Files:**
- Create: lib/widgets/sori/world_map_viewport.dart
- Modify: lib/screens/hanok_world_screen.dart
- Modify: lib/widgets/sori/personal_hanok_map.dart
- Modify: lib/data/personal_hanok_catalog.dart
- Modify: DE/EN ARB and generated l10n
- Test: test/world_map_viewport_test.dart, test/hanok_world_screen_test.dart, test/responsive_test.dart

**Interfaces:**
- WorldMapViewport(projection, selectedZone, onSelect, onOpen) renders a 4:3 map plus selected-place detail.
- Phone puts detail below the map; width >= 720dp uses a persistent trailing panel.
- The map returns a semantic PersonalHanokZone only and remains read-only.

- [x] **Step 1: Write failing viewport tests** for phone detail, tablet panel, today's-Sarangbang marker, locked place explanation, and accessible list action.
- [x] **Step 2: Run the new viewport tests and confirm RED.**
- [x] **Step 3: Implement with LayoutBuilder and existing Sori clamp/token components.** All visual zones, hit targets, accessible list entries, labels, milestone text, and route actions come from one catalog entry.
- [x] **Step 4: Verify and commit.** Viewport/world/responsive tests, asset check, analyzer, and AGENTS logging completed; implementation commit:
~~~text
11cdd69 feat(hanok): add responsive world map viewport
~~~

### Task 5: Add read-only venue study context

**Files:**
- Create: lib/widgets/sori/personal_room_scene.dart
- Modify: lib/screens/sarangbang_screen.dart
- Modify: lib/screens/personal_room_furnish_screen.dart
- Modify: lib/data/personal_room_catalog.dart
- Test: test/personal_room_scene_test.dart, test/sarangbang_study_screen_test.dart, test/personal_room_furnish_screen_test.dart

**Interfaces:**
- PersonalRoomScene(surface, placements, interactive) draws a shell plus RoomLayer.
- interactive false is semantic/read-only and cannot open a picker or write storage.
- Furnish screens keep current interactive contracts.

- [x] **Step 1: Write failing tests that prove Sarangbang study reads placed decor but exposes no picker write action.**
- [x] **Step 2: Implement the shared scene.** Preserve the separate furnishing route and Bojagi action. Keep locked Anbang/Daecheong from placement reads/writes.
- [x] **Step 3: Verify and commit.** Scene/room/Sarangbang, smoke, responsive, analyzer, and AGENTS checks completed; implementation commit:
~~~text
47edaa1 feat(sarangbang): show a read-only study room scene
~~~

### Task 6: Add P4b model, catalog, and read-only exhibition layer

**Files:**
- Create: lib/models/gye_dedication.dart
- Create: lib/data/gye_dedication_catalog.dart
- Create: lib/widgets/sori/gye_dedication_layer.dart
- Modify: lib/widgets/sori/gye_hanok.dart
- Test: test/gye_dedication_model_test.dart, test/widgets/gye_dedication_layer_test.dart

**Interfaces:**
- GyeDedication parses server documents fail-closed and stores uid, membershipId, exact joined-at epoch, state, allowlisted slug, nullable slot, and monotonic revision.
- Catalog declares ten map-relative exhibit slots using shipped decoration assets.
- Layer renders server data only and never touches Storage.ownedDecor.

- [x] **Step 1: Write failing model/layer tests** for malformed documents, allowlist rejection, duplicate slots, stable ordering, tombstones, and at most ten semantic items.
- [x] **Step 2: Implement model/catalog/layer and compose above GyeHanok.** Do not change weekly-goal construction layers.
- [x] **Step 3: Verify and commit.** Targeted analyzer/tests and AGENTS logging completed; implementation commit:
~~~text
7e9aa60 feat(gye): render shared decoration exhibition
~~~

### Task 7: Add callable-only P4b write path and cleanup

**Files:**
- Create: functions/gye/gye_dedication_runtime.js
- Create: functions/gye/gye_dedication_runtime.test.js
- Modify: functions/gye/index.js
- Modify: functions/gye/deletion_gye_page.js
- Modify: functions/gye/deletion_cleanup_adapters.js
- Modify: firestore.rules, functions/gye/firestore.rules.test.js, functions/gye/package.json

**Interfaces:**
- Export callable setGyeDecorationDedication(gyeId, decorationSlug, expectedRevision, expectedMembershipId, expectedJoinedAtSeconds, expectedJoinedAtNanos, operationId).
- decorationSlug null writes a monotonic withdrawal tombstone; direct Firestore writes are denied.
- Transaction is idempotent by an epoch-bound operation id, conflict-aware by revision, and keeps a bounded sixteen-entry receipt ledger.

- [x] **Step 1: Write runtime tests** for success, duplicate operation, stale revision, first-free-slot assignment, replacement retention, withdrawal, ABA replay, bounded receipts, throttle, banned/suspended/deleting rejection, and membership-generation mismatch.
- [x] **Step 2: Implement a pure runtime with repository adapters, then bind a callable in index.js.** Use App Check, authenticated user id, and an Admin transaction.
- [x] **Step 3: Add rules tests** proving active members can read but cannot create, update, or delete dedication documents directly.
- [x] **Step 4: Extend leave/account/Gye deletion cleanup** with uid + membershipId + joined-at epoch matching and dedication enumeration.
- [x] **Step 5: Verify and commit.** Node `315/315`, Firestore emulator rules `43/43`, targeted Flutter `46/46`, and diff checks passed; implementation commit:
~~~text
7061ab9 feat(gye): harden shared exhibition dedication
~~~

### Task 8: Add P4b client service and confirmation UI

**Files:**
- Create: lib/services/gye_dedication_service.dart
- Create: lib/widgets/sori/gye_dedication_picker.dart
- Modify: lib/screens/gye_screen.dart
- Modify: DE/EN ARB and generated l10n
- Test: test/gye_dedication_service_test.dart, test/gye_screen_test.dart, test/responsive_test.dart

**Interfaces:**
- Service streams validated server documents, preserves tombstones for CAS, and invokes the callable with generated operation id/revision plus the exact active membership epoch.
- Picker filters Storage.ownedDecor locally for usability; server remains authoritative.
- UI is pessimistic until stream confirmation. A stale revision reloads the stream; it never overwrites blindly, and a changed membership epoch cancels confirmation and retry.

- [x] **Step 1: Write failing tests** for no-owned-decor state, confirmation copy, duplicate button suppression, stream-confirmed render, conflict reload, withdrawal, tombstone visibility, and a reused membership id with a different join epoch.
- [x] **Step 2: Implement service, picker, and GyeScreen integration** using showSoriSheet and semantic labels. Do not write a social feed or mutate personal ownership.
- [x] **Step 3: Verify and commit.** Run Flutter targeted, smoke, responsive, typography, analyzer, Node/rules tests; implementation and client-hardening commits:
~~~text
3325d53 feat(gye): let members dedicate a shared exhibit
7061ab9 feat(gye): harden shared exhibition dedication
~~~

### Task 9: Whole-system regression and release handoff

**Files:**
- Modify: AGENTS.md
- Modify: handoff/runbook only if statements become stale

- [x] **Step 1: Run full validation.** `flutter gen-l10n` produced no drift; `flutter analyze --no-pub --fatal-infos` reported no issues; the complete serial Flutter suite passed **2,087** tests after the room-slot touch fix; both personal-Hanok/room asset checkers passed; Node Gye **315/315** and Firestore emulator rules **43/43** passed; `flutter build web --release --no-pub` exited 0. The only web output was the existing `flutter_tts` WebAssembly dry-run warning from pub cache, not a Dart application failure.

~~~text
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
python tool/check_personal_hanok_assets.py
python tool/check_personal_room_assets.py
node --test functions/gye/gye_dedication_runtime.test.js functions/gye/gye_dedication_cleanup.test.js
npm.cmd --prefix functions/gye test
npm.cmd --prefix functions/gye run test:rules
git diff --check
~~~

- [x] **Step 2: Review git diff main...HEAD twice.** First for state-boundary violations; second for localization, responsive, and visual-system regressions.
- [x] **Step 3: Update AGENTS.md** with actual command results, exact commits, P4b-MVP versus real-transfer distinction, and remaining live deployment evidence; commit:
~~~text
docs(hanok): record world system verification
~~~
