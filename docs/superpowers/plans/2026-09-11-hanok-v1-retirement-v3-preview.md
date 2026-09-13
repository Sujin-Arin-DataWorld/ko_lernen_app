# Hanok V1 Retirement and V3 Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every learner-facing Personal Hanok V1 path with the approved static IlDu V3 preview, preserve meaningful V1 user settings through a one-time local/cloud import, and remove retired V1 asset and CI triggers.

**Architecture:** Put all temporary presentation behind one reusable, non-interactive preview widget. Move user-owned presentation settings into a V3 `IlDuWorldState`, retain the old JSON decoder only inside an import-only compatibility boundary, and keep CourseMastery as the sole future unlock authority. Remove V1 renderer, assets, and tooling after all callers use the preview or competency-only services.

**Tech Stack:** Flutter/Dart, `shared_preferences`, existing CloudSync and account reconciliation, ARB-generated localization, Python CI routing tests, Flutter widget/unit tests.

**Spec:** `docs/superpowers/specs/2026-09-11-hanok-v1-retirement-v3-preview-design.md`

## Global Constraints

- The supplied PNG remains byte-identical: `768 x 1376`, `2,127,303` bytes, SHA-256 `c35e5b89a2f2154a61b07ed0d8e0b02b6d6e7b063825b10b132f02a95f14c0c6`.
- Preview rendering uses `BoxFit.contain`, `Alignment.center`, and `SoriSurfaces.surfaceAlt`; it has no tap handler, button semantics, hotspot, or route into an interactive map.
- `/hanok`, `/hanok/anbang`, and `/hanok/daecheong` resolve to the preview while IlDu V3 remains unfinished.
- CourseMastery, excluding bypassed prerequisites, remains the only progress authority. Pack ratios, XP, browse history, stamps, quests, placement level, and Gye grant no V3 ownership.
- Do not synthesize V3 building, decoration, room, or anchor coordinates from V1 data.
- Do not migrate V1 `seenRevealIds`; those IDs refer to retired presentation assets.
- New state uses local key `kl_ildu_world_state_v1` and cloud field `ildu_world_state_json`.
- The only permitted V1 compatibility code after retirement is the strict, import-only decoder for `kl_hanok_state_v1` / `hanok_state_json` into `IlDuWorldState`.
- Preserve room-v3 layouts, IlDu V3 manifests, placements, turntables, earned decorations, CourseMastery, quests, stamps, SRS, and Gye.
- Do not edit generated localization files by hand. Reuse `soriStageHanokUpdating`.
- Do not commit, push, open or edit a PR, merge, deploy, or remove the worktree without explicit user authority. Commit steps below are conditional gates, not standing authorization.

---

## Planned File Structure

- Presentation is isolated in `hanok_v3_preview.dart` and `hanok_preview_screen.dart`; no
  migration or progress logic belongs in either widget.
- Persistence is isolated in `ildu_world_state.dart` and `ildu_world_state_service.dart`; the
  only V1 decoder lives in `legacy_hanok_v1_importer.dart`.
- Shared progress is read through `hanok_competence_projection_service.dart`; it does not
  depend on V1 assets, pack ratios, map projection, or presentation state.
- CI selection remains in `ci_scope.py`; the retirement guard verifies that the boundaries
  above cannot silently regress.
- The exact create/modify/delete inventory is recorded in the appendix after the task list.

---

### Task 1: Lock the supplied preview bytes and presentation contract

**Files:**
- Create: `assets/illustrations/hanok/ildu_v3_preview.png`
- Create: `lib/widgets/sori/hanok_v3_preview.dart`
- Create: `test/hanok_v3_preview_test.dart`
- Modify: `lib/widgets/sori/updating_scene.dart`
- Modify: `test/sori_updating_scene_test.dart`

**Interfaces:**
- Consumes: existing `SoriUpdatingScene`, `SoriSurfaces`, and localized updating message supplied by the caller.
- Produces: `const kIlDuV3PreviewAsset` and `HanokV3Preview({Key? key, required String message})`.

- [ ] **Step 1: Copy the exact user-supplied binary and verify it before code changes**

  Run:

  ```powershell
  Copy-Item -LiteralPath 'C:\Users\vjinn\AppData\Local\Temp\codex-clipboard-9d184af7-2443-4ae5-bf1c-5f4db5f8c182.png' -Destination 'assets\illustrations\hanok\ildu_v3_preview.png'
  Get-Item -LiteralPath 'assets\illustrations\hanok\ildu_v3_preview.png' | Select-Object Length
  Get-FileHash -Algorithm SHA256 -LiteralPath 'assets\illustrations\hanok\ildu_v3_preview.png'
  ```

  Expected: length `2127303` and SHA-256 `C35E5B89A2F2154A61B07ED0D8E0B02B6D6E7B063825B10B132F02A95F14C0C6`.

- [ ] **Step 2: Write the failing byte and widget contract**

  Create `test/hanok_v3_preview_test.dart` with these load-bearing assertions:

  ```dart
  import 'dart:io';

  import 'package:crypto/crypto.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';

  void main() {
    test('preview is the exact approved source', () {
      final bytes = File(kIlDuV3PreviewAsset).readAsBytesSync();
      expect(bytes, hasLength(2127303));
      expect(
        sha256.convert(bytes).toString(),
        'c35e5b89a2f2154a61b07ed0d8e0b02b6d6e7b063825b10b132f02a95f14c0c6',
      );
    });

    testWidgets('shows the whole preview without an interactive affordance', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 292.5,
              child: HanokV3Preview(message: '준비 중'),
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, kIlDuV3PreviewAsset);
      expect(image.fit, BoxFit.contain);
      expect(image.alignment, Alignment.center);
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });
  }
  ```

- [ ] **Step 3: Run the new test and confirm the missing widget failure**

  Run: `flutter test test/hanok_v3_preview_test.dart`

  Expected: FAIL because `hanok_v3_preview.dart` and `HanokV3Preview` do not exist.

- [ ] **Step 4: Add general contain/backdrop inputs to the existing updating scene**

  Extend `SoriUpdatingScene` without changing existing callers:

  ```dart
  final BoxFit assetFit;
  final Color? backdropColor;

  const SoriUpdatingScene({
    super.key,
    required this.asset,
    required this.message,
    this.alignment = Alignment.center,
    this.assetFit = BoxFit.cover,
    this.backdropColor,
    this.veilOpacity = 0.45,
    this.messageAlignment = Alignment.center,
  });
  ```

  Put the image behind a themed background and pass the parameters literally:

  ```dart
  ColoredBox(
    color: backdropColor ?? s.surfaceAlt,
    child: Image.asset(
      asset,
      fit: assetFit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => ColoredBox(color: s.surfaceAlt),
    ),
  )
  ```

- [ ] **Step 5: Write the minimal V3 preview wrapper**

  Create `lib/widgets/sori/hanok_v3_preview.dart`:

  ```dart
  import 'package:flutter/material.dart';

  import 'tokens.dart';
  import 'updating_scene.dart';

  const String kIlDuV3PreviewAsset =
      'assets/illustrations/hanok/ildu_v3_preview.png';

  class HanokV3Preview extends StatelessWidget {
    const HanokV3Preview({super.key, required this.message});

    final String message;

    @override
    Widget build(BuildContext context) {
      final surfaces = SoriSurfaces.of(context);
      return SoriUpdatingScene(
        asset: kIlDuV3PreviewAsset,
        message: message,
        alignment: Alignment.center,
        assetFit: BoxFit.contain,
        backdropColor: surfaces.surfaceAlt,
      );
    }
  }
  ```

- [ ] **Step 6: Extend the existing updating-scene regression test**

  Add a case in `test/sori_updating_scene_test.dart` that passes
  `assetFit: BoxFit.contain`, reads the descendant `Image`, and expects
  `BoxFit.contain`. Keep the existing default-cover assertion so Gye and other callers do not
  change silently.

- [ ] **Step 7: Run the focused tests**

  Run:

  ```powershell
  flutter test test/hanok_v3_preview_test.dart
  flutter test test/sori_updating_scene_test.dart
  ```

  Expected: both PASS; the preview contains no button/tap semantics.

- [ ] **Step 8: Conditional commit gate**

  Only if the user explicitly authorizes commits:

  ```powershell
  git add assets/illustrations/hanok/ildu_v3_preview.png lib/widgets/sori/hanok_v3_preview.dart lib/widgets/sori/updating_scene.dart test/hanok_v3_preview_test.dart test/sori_updating_scene_test.dart
  git commit -m "fix: add noninteractive hanok v3 preview"
  ```

### Task 2: Quarantine every unfinished Hanok destination behind the preview

**Files:**
- Create: `lib/screens/hanok_preview_screen.dart`
- Modify: `lib/main.dart`
- Modify: `lib/screens/sori_stage/sori_stage_hanok_screen.dart`
- Modify: `lib/screens/sori_stage/sori_stage_today_screen.dart`
- Modify: `lib/screens/learning_path_screen.dart`
- Modify: `lib/screens/onboarding_v2/onboarding_hanok_growth_preview.dart`
- Modify: `test/sori_stage_hanok_fold_test.dart`
- Modify: `test/sori_stage_hanok_shortcuts_test.dart`
- Modify: `test/sori_stage_visual_evidence_test.dart`
- Create: `test/hanok_preview_routing_test.dart`

**Interfaces:**
- Consumes: `HanokV3Preview(message: AppL10n.of(context).soriStageHanokUpdating)`.
- Produces: `const HanokPreviewScreen()` and a Hanok tab that keeps shortcut counts but contains no V1 world slivers.

- [ ] **Step 1: Write failing route and interaction tests**

  In `test/hanok_preview_routing_test.dart`, pump a small `MaterialApp` using the same route
  builder shape as `main.dart` and assert all three old entry paths produce
  `HanokPreviewScreen`:

  ```dart
  for (final route in const ['/hanok', '/hanok/anbang', '/hanok/daecheong']) {
    await tester.pumpWidget(_routeHarness(initialRoute: route));
    await tester.pumpAndSettle();
    expect(find.byType(HanokPreviewScreen), findsOneWidget);
    expect(find.byType(IlDuWorldScreen), findsNothing);
  }
  ```

  In the Hanok tab tests, assert `HanokV3Preview` is present, the shortcut keys still appear,
  and no legacy world/map key appears. The retirement guard owns deleted-type assertions so
  this widget test still compiles after those classes are removed.

- [ ] **Step 2: Run tests to verify the preview screen is missing**

  Run:

  ```powershell
  flutter test test/hanok_preview_routing_test.dart
  flutter test test/sori_stage_hanok_shortcuts_test.dart
  ```

  Expected: FAIL because the preview route and tab wiring are not implemented.

- [ ] **Step 3: Implement the safe deep-link screen**

  Create `HanokPreviewScreen` as a normal scaffold using the existing app bar and background:

  ```dart
  class HanokPreviewScreen extends StatelessWidget {
    const HanokPreviewScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final t = AppL10n.of(context);
      return Scaffold(
        appBar: SoriAppBar(
          title: t.soriStageNavHanok,
          textScale: MediaQuery.textScalerOf(context).scale(1),
          viewportWidth: MediaQuery.sizeOf(context).width,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: HanokV3Preview(message: t.soriStageHanokUpdating),
              ),
            ),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Route all existing Hanok deep links to the safe screen**

  Replace the three cases in `lib/main.dart` with the same destination:

  ```dart
  case '/hanok':
  case '/hanok/anbang':
  case '/hanok/daecheong':
    return SoriTransitions.page(
      (_) => const HanokPreviewScreen(),
      settings: settings,
    );
  ```

  Remove imports that become unused; do not delete IlDu V3 source.

- [ ] **Step 5: Replace the Hanok tab's map and embedded V1 world**

  Remove `worldForTesting`, `worldLoadRatios`, `worldLoadProjection`, the `world()` helper,
  the trailing `HanokWorldScreen` sliver, and `_HanokMapSliver.projection`. Build the header
  with the preview unconditionally:

  ```dart
  final mapArt = HanokV3Preview(message: t.soriStageHanokUpdating);
  ```

  Keep `_ShortcutTiles`, its refresh-after-return behavior, the pinned extent math, and
  reduced-motion snapping. Remove the map hint overlay and every tap path from the preview.

- [ ] **Step 6: Remove interactive V1 art from Today, Lernpfad, and onboarding previews**

  Replace direct `personal_hanok_v2` and `hanok_stages` images with
  `HanokV3Preview(message: t.soriStageHanokUpdating)`. In `_HanokProgress`, remove the outer
  `InkWell` so the card cannot imply that the unfinished world opens. Keep textual
  competency progress until Task 5 changes its source.

- [ ] **Step 7: Run responsive and visual regression tests**

  Run:

  ```powershell
  flutter test test/hanok_preview_routing_test.dart test/sori_stage_hanok_shortcuts_test.dart test/sori_stage_hanok_fold_test.dart
  flutter test test/sori_stage_visual_evidence_test.dart
  flutter test test/onboarding_v2_story_practice_test.dart test/onboarding_v2_runtime_catalog_test.dart
  ```

  Expected: PASS at the existing phone/fold constraints; the full portrait is visible with
  paper-colored side margins and no actionable semantics.

- [ ] **Step 8: Conditional commit gate**

  Only if the user explicitly authorizes commits:

  ```powershell
  git add lib/main.dart lib/screens/hanok_preview_screen.dart lib/screens/sori_stage/sori_stage_hanok_screen.dart lib/screens/sori_stage/sori_stage_today_screen.dart lib/screens/learning_path_screen.dart lib/screens/onboarding_v2/onboarding_hanok_growth_preview.dart test/hanok_preview_routing_test.dart test/sori_stage_hanok_fold_test.dart test/sori_stage_hanok_shortcuts_test.dart test/sori_stage_visual_evidence_test.dart
  git commit -m "fix: quarantine unfinished hanok worlds behind preview"
  ```

### Task 3: Add V3-owned state and the transactional local V1 importer

**Files:**
- Create: `lib/models/ildu_world_state.dart`
- Create: `lib/services/ildu_world_state_service.dart`
- Create: `lib/services/legacy_hanok_v1_importer.dart`
- Create: `test/ildu_world_state_service_test.dart`
- Create: `test/legacy_hanok_v1_importer_test.dart`
- Modify: `lib/models/hanok_growth.dart`
- Modify: `lib/services/hanok_experience_projector.dart`
- Modify: `lib/services/data_migration_service.dart`
- Modify: `lib/services/storage_service.dart`
- Modify: `test/data_migration_test.dart`

**Interfaces:**
- Produces: `IlDuLwwClock`, `IlDuDesignSelection`, `IlDuCarePreferences`, and `IlDuWorldState` with `toJson`, strict `fromJson`, and deterministic `merge`.
- Produces: `IlDuWorldStateService.load()`, `decode(String)`, `captureForCloudReconciliation()`, `save(IlDuWorldState, {String? expectedGeneration})`, and `mergeCloudSnapshotJson(...)`.
- Produces: `LegacyHanokV1Importer.decode(String)` and `migratePreferences(SharedPreferences)`.
- Consumes: `DataMigrationService` schema step 2 and the existing V1 JSON shape only inside the importer.

- [ ] **Step 1: Write strict V3 state tests before moving production code**

  Cover these exact cases in `test/ildu_world_state_service_test.dart`:

  ```dart
  test('round trips design selections and care preferences', () {
    final state = IlDuWorldState(
      sourceManifestVersion: 'hanok-grants-v1',
      activeDesignSelections: {
        'roofForm': IlDuDesignSelection(
          grantId: 'roof.giwa',
          clock: const IlDuLwwClock(counter: 2, actorId: 'device-a'),
        ),
      },
      carePreferences: IlDuCarePreferences.fresh(),
    );
    expect(IlDuWorldState.fromJson(state.toJson()).toJson(), state.toJson());
  });

  test('merge keeps the selection with the greater LWW clock', () {
    final merged = IlDuWorldState.merge(_state(1, 'old'), _state(2, 'new'));
    expect(merged.activeDesignSelections['roofForm']!.grantId, 'new');
  });
  ```

  Also assert rejection of unknown top-level keys, non-UTC activity timestamps, duplicate
  tier IDs, counters above `9007199254740991`, invalid stable IDs, JSON roots other than a
  map, and encoded payloads above `256 * 1024` bytes.

- [ ] **Step 2: Run the V3 state test and verify missing-type failures**

  Run: `flutter test test/ildu_world_state_service_test.dart`

  Expected: FAIL because the V3 state model and service do not exist.

- [ ] **Step 3: Move and rename the reusable persistence primitives**

  Move `HanokLwwClock`, `HanokLoadoutSelection`, `HanokCareState`, and `HanokState` out of
  `hanok_growth.dart` into `ildu_world_state.dart` with these public names and header:

  ```dart
  final class IlDuWorldState {
    static const int currentSchemaVersion = 1;
    static const int currentMigrationVersion = 1;

    IlDuWorldState({
      this.schemaVersion = currentSchemaVersion,
      this.migrationVersion = currentMigrationVersion,
      required this.sourceManifestVersion,
      Map<String, IlDuDesignSelection> activeDesignSelections = const {},
      required this.carePreferences,
    });

    final int schemaVersion;
    final int migrationVersion;
    final String sourceManifestVersion;
    final Map<String, IlDuDesignSelection> activeDesignSelections;
    final IlDuCarePreferences carePreferences;
  }
  ```

  Preserve the existing maximum counter, stable-ID grammar, exact-key validation, strict UTC
  rules, LWW tie-breaker, and care merge rules. Do not add `seenRevealIds` to the new model.
  Update `HanokExperienceProjector.project` to consume `IlDuWorldState` and the renamed
  selection/care types without changing how earned grants are computed from CourseMastery.

- [ ] **Step 4: Add the V3 local service with the existing CAS guarantees**

  Implement `IlDuWorldStateService` from the proven serialized-write structure of
  `HanokStateService`, changing only the model and key:

  ```dart
  final class IlDuWorldStateService {
    static const int maximumEncodedBytes = 256 * 1024;
    static Future<void> _writeTail = Future<void>.value();

    const IlDuWorldStateService();

    IlDuWorldState? load() {
      final raw = Storage.ilduWorldStateRawJson.trim();
      return raw.isEmpty ? null : decode(raw);
    }

    IlDuWorldState decode(String raw) {
      if (utf8.encode(raw).length > maximumEncodedBytes) {
        throw const FormatException('IlDu world state is too large.');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('IlDu world state must be a JSON object.');
      }
      return IlDuWorldState.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
  }
  ```

  Retain expected-generation checks before and inside the strict storage write, plus queue
  serialization for capture/save/merge.

- [ ] **Step 5: Write importer tests for the exact migration policy**

  In `test/legacy_hanok_v1_importer_test.dart`, test:

  - no V1 key: returns `false`, writes neither V3 state nor migration marker;
  - valid V1: copies `manifestVersion`, `activeLoadout`, and `careState`, drops
    `seenRevealIds`, writes V3 first, removes four V1 keys, then writes the marker;
  - existing V3 plus V1: merges LWW selections and care settings deterministically;
  - repeated call: returns without changing the byte representation;
  - malformed/oversized V1: throws `FormatException` and removes nothing;
  - injected rejected V3 write: leaves all V1 keys present.

  Use a literal legacy fixture shaped like this:

  ```dart
  final legacy = jsonEncode({
    'schemaVersion': 1,
    'manifestVersion': 'hanok-grants-v1',
    'cutoverVersion': 2,
    'seenRevealIds': ['retired.asset'],
    'activeLoadout': {
      'roofForm': {
        'grantId': 'roof.giwa',
        'clock': {'counter': 2, 'actorId': 'device-a'},
      },
    },
    'careState': {
      'vacationMode': false,
      'displayEnabled': true,
      'notificationsEnabled': false,
      'settingsClock': {'counter': 1, 'actorId': 'device-a'},
      'notifiedTierIds': <String>[],
    },
  });
  ```

- [ ] **Step 6: Implement the isolated legacy decoder and ordered mutation**

  `LegacyHanokV1Importer.decode` must require exactly the six legacy top-level fields and
  reuse the V3 types for validated clocks, selections, and care preferences. The conversion
  result is:

  ```dart
  return IlDuWorldState(
    sourceManifestVersion: manifestVersion,
    activeDesignSelections: decodedSelections,
    carePreferences: decodedCarePreferences,
  );
  ```

  Implement the local mutation with explicit checked writes:

  ```dart
  static Future<bool> migratePreferences(SharedPreferences prefs) async {
    final raw = prefs.getString(legacyStateKey);
    if (raw == null || raw.trim().isEmpty) {
      return false;
    }
    final imported = decode(raw);
    final currentRaw = prefs.getString(IlDuWorldStateService.preferenceKey);
    final current = currentRaw == null
        ? null
        : const IlDuWorldStateService().decode(currentRaw);
    final next = current == null
        ? imported
        : IlDuWorldState.merge(current, imported);
    final encoded = jsonEncode(next.toJson());
    if (!await prefs.setString(IlDuWorldStateService.preferenceKey, encoded)) {
      throw StateError('IlDu world state migration write was rejected.');
    }
    await prefs.reload();
    if (prefs.getString(IlDuWorldStateService.preferenceKey) != encoded) {
      throw StateError('IlDu world state migration could not be verified.');
    }
    for (final key in legacyKeys) {
      if (prefs.containsKey(key) && !await prefs.remove(key)) {
        throw StateError('Legacy Hanok key removal was rejected.');
      }
    }
    if (!await prefs.setBool(markerKey, true)) {
      throw StateError('Legacy Hanok migration marker was rejected.');
    }
    return true;
  }
  ```

  Constants are literal and private to the compatibility boundary:

  ```dart
  static const legacyStateKey = 'kl_hanok_state_v1';
  static const markerKey = 'kl_hanok_v1_to_ildu_v3_v1';
  static const legacyKeys = <String>[
    'kl_hanok_state_v1',
    'kl_hanok_cutover_v2',
    'kl_hanok_stages_seen_v1',
    'kl_personal_hanok_milestones_seen_v1',
  ];
  ```

- [ ] **Step 7: Register production schema step 2**

  In `DataMigrationService`:

  ```dart
  static const int currentSchemaVersion = 2;

  static final Map<int, DataMigrationStep> _productionSteps =
      <int, DataMigrationStep>{
        2: LegacyHanokV1Importer.migratePreferences,
      };
  ```

  Add `kl_hanok_state_v1` to `_existingInstallMarkers` so a legacy-only installation starts
  from schema 1. Add `Storage.ilduWorldStatePreferenceKey`,
  `Storage.ilduWorldStateRawJson`, and strict setter support. Remove public V1 state/cutover
  getters and setters after the importer no longer needs them.

- [ ] **Step 8: Prove migration rollback through the production registry**

  Extend `test/data_migration_test.dart` with a schema-1 fixture containing the legacy JSON,
  call `DataMigrationService.run(preferences: prefs)`, and assert schema version 2, V3 state,
  absent V1 keys, and a true marker. Add an injected failing step after the importer and assert
  the runner restores every original key and removes the partial V3 key/marker.

- [ ] **Step 9: Run the state and migration suite**

  Run:

  ```powershell
  flutter test test/ildu_world_state_service_test.dart test/legacy_hanok_v1_importer_test.dart test/data_migration_test.dart test/hanok_experience_projector_test.dart
  ```

  Expected: PASS with no generated grant ownership and no V1 reveal ID in V3 JSON.

- [ ] **Step 10: Conditional commit gate**

  Only if the user explicitly authorizes commits:

  ```powershell
  git add lib/models/ildu_world_state.dart lib/models/hanok_growth.dart lib/services/ildu_world_state_service.dart lib/services/legacy_hanok_v1_importer.dart lib/services/data_migration_service.dart lib/services/storage_service.dart lib/services/hanok_experience_projector.dart test/ildu_world_state_service_test.dart test/legacy_hanok_v1_importer_test.dart test/data_migration_test.dart test/hanok_experience_projector_test.dart
  git commit -m "fix: migrate hanok v1 settings into ildu v3 state"
  ```

### Task 4: Move cloud backup and account reconciliation to the V3 field

**Files:**
- Modify: `lib/services/cloud_sync.dart`
- Modify: `lib/services/account/account_reconciliation.dart`
- Modify: `test/hanok_cloud_sync_test.dart`
- Modify: `test/hanok_account_reconciliation_test.dart`
- Modify: `test/cloud_sync_test.dart`
- Modify: `test/services/account/account_reconciliation_test.dart`

**Interfaces:**
- Consumes: `IlDuWorldStateService` and `LegacyHanokV1Importer.decode` from Task 3.
- Produces: cloud field `ildu_world_state_json`; accepts `hanok_state_json` only when the V3 field is absent.

- [ ] **Step 1: Rewrite cloud tests around a V3-first compatibility matrix**

  Update `test/hanok_cloud_sync_test.dart` to assert:

  ```dart
  final payload = await CloudSync.buildBackupPayload();
  expect(payload, contains('ildu_world_state_json'));
  expect(payload, isNot(contains('hanok_state_json')));
  ```

  Add restore cases for:

  1. valid `ildu_world_state_json` only;
  2. valid legacy `hanok_state_json` only, imported into local V3 state;
  3. both fields present, where V3 wins and the legacy decoder is not invoked;
  4. malformed V3, which fails without changing local state;
  5. malformed legacy with no V3, which fails without changing local state.

  Update `test/hanok_account_reconciliation_test.dart` with the same field-precedence matrix
  and deterministic LWW merge assertions.

- [ ] **Step 2: Run both suites and verify old production names fail**

  Run:

  ```powershell
  flutter test test/hanok_cloud_sync_test.dart
  flutter test test/hanok_account_reconciliation_test.dart
  ```

  Expected: FAIL until the cloud snapshot models and services use `IlDuWorldState`.

- [ ] **Step 3: Replace backup capture and reserved-field handling**

  In `CloudSync`, replace `HanokStateLocalCapture? hanokStateCapture` with
  `IlDuWorldStateLocalCapture? ilduWorldStateCapture`, capture through
  `IlDuWorldStateService`, and emit:

  ```dart
  final ilduCapture = ilduWorldStateCapture ??
      await const IlDuWorldStateService().captureForCloudReconciliation();
  if (ilduCapture.state case final state?) {
    payload['ildu_world_state_json'] = jsonEncode(state.toJson());
  }
  ```

  Add `ildu_world_state_json` to the reserved cloud fields. Keep
  `hanok_state_json` reserved so it cannot leak into ordinary fields, but never emit it from a
  new backup.

- [ ] **Step 4: Implement V3-first restore with a legacy-only fallback**

  Select raw input before any write:

  ```dart
  final rawV3 = data['ildu_world_state_json'];
  final rawLegacy = data['hanok_state_json'];
  final rawState = rawV3 ?? rawLegacy;
  if (rawState != null) {
    if (rawState is! String || rawState.trim().isEmpty) {
      throw const FormatException('IlDu cloud data must be nonempty JSON.');
    }
    final decoded = rawV3 != null
        ? const IlDuWorldStateService().decode(rawState)
        : LegacyHanokV1Importer.decode(rawState);
    await const IlDuWorldStateService().mergeCloudSnapshot(
      decoded,
      expectedGeneration: generation,
      beforeWrite: beforeWrite,
    );
  }
  ```

  The branch must not decode `rawLegacy` when `rawV3` is present. Preserve the existing local
  lifetime and expected-generation fences.

- [ ] **Step 5: Rename account reconciliation state and preserve equality semantics**

  Change `AccountReconciliationSnapshot.hanokState` to
  `AccountReconciliationSnapshot.ilduWorldState`. Decode V3 first, otherwise convert the
  legacy field:

  ```dart
  final ilduResult = document.containsKey('ildu_world_state_json')
      ? _decodeIlDuWorldState(document['ildu_world_state_json'])
      : _decodeLegacyHanokState(document['hanok_state_json']);
  ```

  Use `IlDuWorldState.merge` for local/remote resolution, include only
  `ildu_world_state_json` in `toCloudFields`, and remove both state field names from ordinary
  field maps. Update equality and stable hash calculations to use
  `ilduWorldState?.toJson()`.

- [ ] **Step 6: Run cloud, account, and lifetime race tests**

  Run:

  ```powershell
  flutter test test/hanok_cloud_sync_test.dart test/hanok_account_reconciliation_test.dart
  flutter test test/cloud_sync_test.dart test/services/account/account_reconciliation_test.dart
  ```

  Expected: PASS; concurrent local V3 writes win the existing CAS race, and no new payload
  contains `hanok_state_json`.

- [ ] **Step 7: Conditional commit gate**

  Only if the user explicitly authorizes commits:

  ```powershell
  git add lib/services/cloud_sync.dart lib/services/account/account_reconciliation.dart test/hanok_cloud_sync_test.dart test/hanok_account_reconciliation_test.dart test/cloud_sync_test.dart test/services/account/account_reconciliation_test.dart
  git commit -m "fix: reconcile hanok backups through ildu v3 state"
  ```

### Task 5: Replace pack-derived Personal Hanok callers with competency-only progress

**Files:**
- Create: `lib/services/hanok_competence_projection_service.dart`
- Modify: `lib/models/sori_stage_progression.dart`
- Modify: `lib/services/sori_stage_progression_service.dart`
- Modify: `lib/screens/sori_stage/sori_stage_today_screen.dart`
- Modify: `lib/screens/scenario_player_screen.dart`
- Modify: `lib/screens/ildu_world_screen.dart`
- Modify: `lib/services/ildu_world_projection_adapter.dart`
- Modify: `lib/screens/personal_room_furnish_screen.dart`
- Modify: `lib/screens/sarangbang_furnish_screen.dart`
- Modify: `lib/data/personal_room_catalog.dart`
- Modify: `lib/screens/ux_preview_app.dart`
- Modify: `test/support/responsive_screens.dart`
- Modify: `test/screen_smoke_test.dart`
- Modify: `test/hanok_competence_projection_test.dart`
- Modify: `test/ildu_world_screen_test.dart`
- Modify: `test/ildu_world_projection_adapter_test.dart`
- Modify: `test/personal_room_catalog_test.dart`
- Modify: `test/personal_room_furnish_screen_test.dart`
- Modify: every Sori Stage fixture returned by `rg -l "hanok: PersonalHanokProjection|HanokStageService" test`

**Interfaces:**
- Produces: `HanokCompetenceProjectionService.loadCurrent()` returning only completed, non-bypassed CourseMastery evidence.
- Changes: `SoriStageProgressionSnapshot.hanok` becomes `hanokCompetence` of type `HanokCompetenceProjection`.
- Changes: `IlDuWorldScreen.loadProjection` accepts `Future<IlDuWorldProjection> Function()`; production defaults fail closed while the route is quarantined.

- [ ] **Step 1: Write competency-service tests**

  Add these cases to `test/hanok_competence_projection_test.dart`:

  ```dart
  test('loadCurrent ignores pack progress and placement bypasses', () async {
    final result = await HanokCompetenceProjectionService.loadCurrent(
      catalogLoader: () async => fixtureCatalog,
      snapshotReader: (_) => const CourseMasterySnapshot(
        completedUnitIds: ['a1.unit'],
        bypassedPrerequisiteUnitIds: ['a1.unit'],
      ),
    );
    expect(result.completedUnitCount, 0);
    expect(result.stage, HanokStage.empty);
  });
  ```

  Keep the existing duplicate/unknown-ID cases. Remove `HanokStageService` and pack fixtures
  from this test.

- [ ] **Step 2: Implement the CourseMastery-only reader**

  Create `hanok_competence_projection_service.dart`:

  ```dart
  typedef HanokCompetenceCatalogLoader = Future<CurriculumCatalog> Function();
  typedef HanokCompetenceSnapshotReader =
      CourseMasterySnapshot? Function(CurriculumCatalog catalog);

  abstract final class HanokCompetenceProjectionService {
    static Future<HanokCompetenceProjection> loadCurrent({
      HanokCompetenceCatalogLoader? catalogLoader,
      HanokCompetenceSnapshotReader? snapshotReader,
    }) async {
      try {
        final catalog = await (catalogLoader ?? CurriculumCatalog.load)();
        final snapshot =
            (snapshotReader ?? _readStoredSnapshot)(catalog) ??
            const CourseMasterySnapshot.empty();
        return HanokCompetenceProjection.fromSnapshot(
          snapshot: snapshot,
          courseUnits: catalog.courseUnits,
        );
      } catch (_) {
        return const HanokCompetenceProjection.empty();
      }
    }

    static CourseMasterySnapshot? _readStoredSnapshot(
      CurriculumCatalog catalog,
    ) => CourseMasteryService(catalog).readForReconciliation();
  }
  ```

- [ ] **Step 3: Change the Sori aggregate to competency-only data**

  Replace the model field and asynchronous reader:

  ```dart
  final HanokCompetenceProjection hanokCompetence;
  ```

  In `SoriStageProgressionService.load`, call
  `HanokCompetenceProjectionService.loadCurrent()` and pass the result as
  `hanokCompetence`. Apply the same type to `SoriStageNetworkBeforeFields`. Update fixture
  construction mechanically; never recreate `PersonalHanokProjection` in tests.

- [ ] **Step 4: Keep the Today card informative but non-interactive**

  Read:

  ```dart
  final built = snapshot.hanokCompetence.completedUnitCount;
  final total = snapshot.hanokCompetence.totalUnitCount;
  final stage = snapshot.hanokCompetence.stage;
  ```

  Keep the progress text and next-piece icon, but use `HanokV3Preview` for the artwork and
  return the card container directly instead of wrapping it in `InkWell`.

- [ ] **Step 5: Remove PersonalHanokProjection from scenario completion**

  Replace the ratio-plus-personal projection helper with direct competency projection:

  ```dart
  HanokStage stageFor(CourseMasterySnapshot snapshot) =>
      HanokCompetenceProjection.fromSnapshot(
        snapshot: snapshot,
        courseUnits: catalog.courseUnits,
      ).stage;

  return ScenarioCanDoResult.fromSnapshot(
    snapshot: courseUpdate.snapshot,
    scenarioId: s.id,
    courseUnits: catalog.courseUnits,
    contentLinks: catalog.contentLinks,
    structureStageBefore: stageFor(beforeSnapshot),
    structureStageAfter: stageFor(courseUpdate.snapshot),
  );
  ```

  This removes pack ratios from a CourseMastery result without changing the result-card API.

- [ ] **Step 6: Make the dormant IlDu screen fail closed without a V1 bridge**

  Replace `IlDuLegacyProjectionLoader` with:

  ```dart
  typedef IlDuProjectionLoader = Future<IlDuWorldProjection> Function();

  Future<IlDuWorldProjection> _loadUnavailableIlDuProjection() async =>
      const IlDuWorldProjection(
        era: IlDuWorldEra.a1,
        hasVerifiedEvidence: false,
      );
  ```

  `_load()` awaits the manifest and this loader directly. Remove
  `IlDuWorldProjectionAdapter.fromPersonalHanok` and its Personal Hanok import. Retain
  `fromExperience(HanokExperienceProjection)` for the future approved V3 wiring. Update IlDu
  screen tests to inject a literal `IlDuWorldProjection`.

- [ ] **Step 7: Keep only the currently shipped Sarangbang room surface**

  Remove the anbang and daecheong definitions whose deleted backgrounds live under
  `personal_hanok_v2/interiors/`. `PersonalRoomFurnishScreen` no longer loads ratios or a
  `PersonalHanokProjection`; it loads the room definition and room-v3 layout only.
  `SarangbangFurnishScreen` continues to construct it with
  `PersonalRoomSurface.sarangbang`. Delete anbang/daecheong-only cases from the room screen
  test and retain placement, accessibility, save failure, and large-text cases against
  Sarangbang.

- [ ] **Step 8: Remove V1 gallery and responsive fixtures**

  In `ux_preview_app.dart`, replace the early/complete Personal Hanok gallery entries with
  `HanokPreviewScreen`. In `test/support/responsive_screens.dart` and `screen_smoke_test.dart`,
  remove `HanokWorldScreen`, anbang furnish, and daecheong furnish entries; retain
  `HanokPreviewScreen`, Sarangbang study, and Sarangbang furnish.

- [ ] **Step 9: Run the competency and caller suite**

  Run:

  ```powershell
  flutter test test/hanok_competence_projection_test.dart test/ildu_world_projection_adapter_test.dart test/ildu_world_screen_test.dart
  flutter test test/sori_stage_today_sections_test.dart test/sori_stage_today_stage_term_test.dart test/sori_stage_reward_receipt_service_test.dart
  flutter test test/personal_room_catalog_test.dart test/personal_room_furnish_screen_test.dart test/screen_smoke_test.dart test/ux_preview_app_test.dart
  ```

  Expected: PASS with no `PersonalHanokProjection` or `HanokStageService` import in a live
  caller.

- [ ] **Step 10: Conditional commit gate**

  Only if the user explicitly authorizes commits:

  ```powershell
  git add lib/models/sori_stage_progression.dart lib/services/hanok_competence_projection_service.dart lib/services/sori_stage_progression_service.dart lib/screens/sori_stage/sori_stage_today_screen.dart lib/screens/scenario_player_screen.dart lib/screens/ildu_world_screen.dart lib/services/ildu_world_projection_adapter.dart lib/screens/personal_room_furnish_screen.dart lib/screens/sarangbang_furnish_screen.dart lib/data/personal_room_catalog.dart lib/screens/ux_preview_app.dart test
  git commit -m "refactor: detach live progress from personal hanok v1"
  ```

### Task 6: Delete the V1 renderer, V1 asset contracts, and dead production tools

**Files:**
- Delete: the V1 source, test, golden, and tool files listed in this task.
- Modify: `pubspec.yaml`
- Modify: `lib/widgets/sori/madang_background.dart`
- Modify: `test/asset_catalog_bidirectional_test.dart`
- Modify: `test/asset_orphan_guard_test.dart`
- Modify: `test/heritage_journey_contract_test.dart`
- Modify: `test/milestone_feedback_widget_test.dart`
- Modify: `test/sori_stage_today_availability_test.dart`
- Modify: `tool/asset_inventory.py`
- Modify: `tool/check_personal_room_assets.py`
- Modify: `tool/test_check_style_conformance.py`
- Create: `test/hanok_v1_retirement_guard_test.dart`

**Interfaces:**
- Consumes: the Task 1 preview and Task 5 competency-only callers.
- Produces: zero live/runtime references to `personal_hanok_v2`, `hanok_stages`, `HanokWorldScreen`, `PersonalHanokMap`, or pack-derived `HanokStageService`.

- [ ] **Step 1: Write the retirement guard before deleting files**

  Create `test/hanok_v1_retirement_guard_test.dart` with an allowlist that contains only the
  importer and migration tests for legacy storage/cloud names:

  ```dart
  import 'dart:io';

  import 'package:flutter_test/flutter_test.dart';

  void main() {
    test('retired personal Hanok V1 presentation cannot return', () {
      const roots = ['lib', 'test', 'tool', '.github'];
      const forbiddenEverywhere = [
        'assets/illustrations/personal_hanok_v2/',
        'assets/illustrations/hanok_stages/',
        'HanokWorldScreen',
        'PersonalHanokMap',
        'HanokStageService',
      ];
      const legacyImportAllowlist = {
        'lib/services/legacy_hanok_v1_importer.dart',
        'test/legacy_hanok_v1_importer_test.dart',
        'test/hanok_cloud_sync_test.dart',
        'test/hanok_account_reconciliation_test.dart',
        'test/hanok_v1_retirement_guard_test.dart',
      };

      final failures = <String>[];
      for (final root in roots) {
        for (final entity in Directory(root).listSync(recursive: true)) {
          if (entity is! File ||
              !RegExp(r'\.(dart|py|ya?ml)$').hasMatch(entity.path)) {
            continue;
          }
          final path = entity.path.replaceAll('\\', '/');
          if (path == 'test/hanok_v1_retirement_guard_test.dart') {
            continue;
          }
          final source = entity.readAsStringSync();
          for (final token in forbiddenEverywhere) {
            if (source.contains(token)) failures.add('$path: $token');
          }
          if (!legacyImportAllowlist.contains(path) &&
              (source.contains('kl_hanok_state_v1') ||
                  source.contains('hanok_state_json'))) {
            failures.add('$path: legacy state outside importer boundary');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }
  ```

- [ ] **Step 2: Run the guard and capture the expected failure inventory**

  Run: `flutter test test/hanok_v1_retirement_guard_test.dart`

  Expected: FAIL and enumerate the remaining V1 callers. Save the output for comparison; do
  not weaken the token list to make it pass.

- [ ] **Step 3: Remove dead V1 Dart sources**

  After `rg` proves no caller remains, remove exactly:

  ```powershell
  git rm -- lib/data/a1_hanok_construction_catalog.dart lib/data/personal_hanok_catalog.dart lib/data/personal_hanok_estate_stage_catalog.dart lib/data/personal_hanok_venue_catalog.dart lib/models/personal_hanok.dart lib/models/hanok_build_narrative.dart lib/screens/hanok_world_screen.dart lib/services/hanok_build_narrative_service.dart lib/services/hanok_cutover_service.dart lib/services/hanok_state_service.dart lib/services/hanok_stage_service.dart lib/services/hanok_structure_projection_service.dart lib/services/personal_hanok_reveal_service.dart lib/widgets/sori/a1_hanok_construction_map.dart lib/widgets/sori/hanok_build_narrative_line.dart lib/widgets/sori/hanok_cinematic.dart lib/widgets/sori/personal_hanok_map.dart lib/widgets/sori/personal_hanok_unlock_reveal.dart lib/widgets/sori/personal_hanok_venue_sheet.dart lib/widgets/sori/world_map_viewport.dart
  ```

  Keep `hanok_stage.dart`, `hanok_competence.dart`, generic Hanok tokens/header primitives,
  Gye artwork, V3 IlDu models/services/assets, and room-v3 storage.

- [ ] **Step 4: Remove the exact V1 Flutter tests and goldens**

  ```powershell
  git rm -- test/a1_hanok_construction_map_test.dart test/a1_hanok_construction_catalog_test.dart test/goldens/personal_hanok_map_golden_test.dart test/goldens/baselines/personal_hanok_map_complete.png test/goldens/baselines/personal_hanok_map_mid.png test/goldens/baselines/personal_hanok_map_early.png test/hanok_build_narrative_test.dart test/hanok_build_narrative_line_test.dart test/hanok_cutover_service_test.dart test/hanok_state_service_test.dart test/hanok_structure_projection_service_test.dart test/hanok_world_screen_test.dart test/personal_hanok_asset_bundle_test.dart test/personal_hanok_catalog_test.dart test/personal_hanok_decode_budget_test.dart test/personal_hanok_map_test.dart test/personal_hanok_reveal_service_test.dart test/personal_hanok_reveal_storage_test.dart test/personal_hanok_study_fraction_test.dart test/personal_hanok_unlock_reveal_test.dart test/personal_hanok_venue_catalog_test.dart test/personal_hanok_venue_sheet_test.dart test/world_map_viewport_test.dart
  ```

  Do not remove V3 `ildu_*`, shared `hanok_competence_projection_test.dart`, or new migration
  tests.

- [ ] **Step 5: Remove V1-only asset-production tools and their tests**

  ```powershell
  git rm -- tool/derive_hanok_a1_thumbnails.py tool/derive_hanok_a1_kit.py tool/compose_hanok_a1_state.py tool/compose_a2_exterior_overlays.py tool/derive_estate_building_stages.py tool/check_personal_hanok_assets.py tool/hanok_v1_asset_contract.py tool/hanok_a1_kit.py tool/promote_hanok_a1_states.py tool/register_hanok_construction_stages.py tool/test_derive_hanok_a1_kit.py tool/test_compose_hanok_a1_state.py tool/test_check_personal_hanok_assets.py tool/test_hanok_v1_asset_contract.py tool/test_hanok_a1_kit.py tool/test_promote_hanok_a1_states.py tool/test_register_hanok_construction_stages.py
  ```

  Keep every `compose_ildu_*`, `promote_ildu_*`, and `test_*ildu*` V3 tool.

- [ ] **Step 6: Remove stale asset declarations and dynamic asset tests**

  Delete only these declarations from `pubspec.yaml`:

  ```yaml
  - assets/illustrations/personal_hanok_v2/map/
  - assets/illustrations/personal_hanok_v2/map/structures/
  - assets/illustrations/personal_hanok_v2/map/landscape/
  - assets/illustrations/personal_hanok_v2/map/stages/
  - assets/illustrations/personal_hanok_v2/interiors/
  - assets/illustrations/personal_hanok_v2/a1/states/
  - assets/illustrations/hanok_stages/
  ```

  Keep `assets/illustrations/hanok/`, `personal_hanok_v3/world/`, and
  `personal_hanok_v3/turnarounds/`. Remove the `hanok_stages` group from
  `asset_catalog_bidirectional_test.dart` and its dynamic-directory exemption from
  `asset_orphan_guard_test.dart`.

- [ ] **Step 7: Replace the last non-renderer V1 asset fixtures**

  - In `madang_background.dart`, remove the `hanok_stages` image lookup and keep its existing
    procedural/Gye-safe background.
  - In `heritage_journey_contract_test.dart`, use
    `assets/illustrations/personal_hanok_v3/world/main-gate.png` as the approved runtime
    fixture.
  - In `tool/asset_inventory.py`, remove the V1 and legacy-stage families and retain the V3
    world/turnaround families.
  - In `tool/test_check_style_conformance.py`, replace the deleted rear-garden anchor with
    `assets/illustrations/personal_hanok_v3/world/sarangchae.png`.
  - In `tool/check_personal_room_assets.py`, validate only the shipped Sarangbang background
    and room-v3 decoration assets.

- [ ] **Step 8: Run zero-reference and asset-resolution gates**

  Run:

  ```powershell
  rg -n "assets/illustrations/personal_hanok_v2/|assets/illustrations/hanok_stages/|HanokWorldScreen|PersonalHanokMap|HanokStageService" lib test tool .github pubspec.yaml
  flutter pub get
  flutter test test/hanok_v1_retirement_guard_test.dart test/asset_catalog_bidirectional_test.dart test/asset_orphan_guard_test.dart
  python -m unittest tool.test_check_style_conformance
  ```

  Expected: `rg` has no matches, `flutter pub get` reports no missing asset directory, and all
  tests PASS.

- [ ] **Step 9: Conditional commit gate**

  Only if the user explicitly authorizes commits:

  ```powershell
  git add -A lib test tool pubspec.yaml assets/illustrations/hanok/ildu_v3_preview.png
  git commit -m "refactor: retire personal hanok v1 runtime"
  ```

### Task 7: Stop retired Hanok documentation from selecting the app CI lane

**Files:**
- Delete: `test/hanok_v1_asset_provenance_test.dart`
- Modify: `.github/scripts/ci_scope.py`
- Modify: `.github/scripts/test_ci_scope.py`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: the remaining live `docs/assets` inputs read by non-V1 tests/tools.
- Produces: exact-file/prefix CI selection for live asset contracts; archived V1 provenance prose no longer selects app CI.

- [ ] **Step 1: Rewrite the CI scope test first**

  Delete `test_hanok_provenance_docs_are_not_skipped` from
  `.github/scripts/test_ci_scope.py`. Add exact positive and negative cases:

  ```python
  def test_live_asset_contracts_select_app(self):
      for path in (
          "docs/assets/STYLE_LOCK.json",
          "docs/assets/CARD_STYLE_BASELINE.json",
          "docs/assets/VOCAB_PACK_CARD_MANIFEST.json",
          "docs/assets/PHASE_ARTWORK_PRODUCTION.json",
          "docs/assets/SFX_README.md",
          "docs/assets/recipes/listening-card.md",
      ):
          self.assert_enabled([path], "app")

  def test_retired_hanok_provenance_is_docs_only(self):
      for path in (
          "docs/assets/HANOK_V1_ASSET_PROVENANCE.json",
          "docs/assets/hanok_a1_kit/stage_01.json",
          "docs/assets/hanok_a2_overlays/overlays.json",
          "docs/assets/hanok_estate_kit/anchae_stages.json",
      ):
          self.assert_disabled([path], "app")
  ```

- [ ] **Step 2: Run the scope test and verify the broad prefix still fails**

  Run: `python -m unittest .github/scripts/test_ci_scope.py`

  Expected: FAIL because `docs/assets/` still selects the app lane.

- [ ] **Step 3: Replace the broad docs/assets prefix with exact live inputs**

  In `.github/scripts/ci_scope.py`, set:

  ```python
  APP_DOC_PREFIXES = (
      "docs/store/",
      "docs/screenshots/",
      "docs/assets/recipes/",
  )

  APP_DOC_FILES = {
      "docs/assets/STYLE_LOCK.json",
      "docs/assets/CARD_STYLE_BASELINE.json",
      "docs/assets/VOCAB_PACK_CARD_MANIFEST.json",
      "docs/assets/PHASE_ARTWORK_PRODUCTION.json",
      "docs/assets/SFX_README.md",
      # retain the existing account/legal/runtime files below
  }
  ```

  Preserve every pre-existing non-asset entry in `APP_DOC_FILES`.

- [ ] **Step 4: Mirror the exact paths in the workflow trigger**

  In both `push.paths` and `pull_request.paths` of `.github/workflows/ci.yml`, replace
  `docs/assets/**` with:

  ```yaml
  - 'docs/assets/STYLE_LOCK.json'
  - 'docs/assets/CARD_STYLE_BASELINE.json'
  - 'docs/assets/VOCAB_PACK_CARD_MANIFEST.json'
  - 'docs/assets/PHASE_ARTWORK_PRODUCTION.json'
  - 'docs/assets/SFX_README.md'
  - 'docs/assets/recipes/**'
  ```

  Remove the V1-specific prose above the asset-gates job. Keep the Python asset-gates job
  itself because card, scene, SFX, and V3 IlDu tools still require it.

- [ ] **Step 5: Delete the V1 provenance test and rerun CI routing tests**

  Run:

  ```powershell
  git rm -- test/hanok_v1_asset_provenance_test.dart
  python -m unittest .github/scripts/test_ci_scope.py
  ```

  Expected: PASS; live style/card/SFX/recipe paths select app and the four retired Hanok
  provenance examples do not.

- [ ] **Step 6: Conditional commit gate**

  Only if the user explicitly authorizes commits:

  ```powershell
  git add .github/scripts/ci_scope.py .github/scripts/test_ci_scope.py .github/workflows/ci.yml test/hanok_v1_asset_provenance_test.dart
  git commit -m "ci: retire hanok v1 asset triggers"
  ```

### Task 8: Run the full retirement and release-safety verification

**Files:**
- Modify only files required by evidence-backed failures from the commands below.
- Update: `graphify-out` tracked commit-layer files through `graphify update .`; never add `graphify-out/graph.json`.

**Interfaces:**
- Consumes: all previous task deliverables.
- Produces: a clean, reviewable worktree whose app, migration, asset, and CI gates pass from the same HEAD.

- [ ] **Step 1: Verify the approved preview artifact again**

  Run:

  ```powershell
  Get-Item -LiteralPath 'assets\illustrations\hanok\ildu_v3_preview.png' | Select-Object Length
  Get-FileHash -Algorithm SHA256 -LiteralPath 'assets\illustrations\hanok\ildu_v3_preview.png'
  ```

  Expected: `2127303` bytes and the approved hash.

- [ ] **Step 2: Verify the retirement boundary with independent searches**

  Run:

  ```powershell
  rg -n "assets/illustrations/personal_hanok_v2/|assets/illustrations/hanok_stages/|HanokWorldScreen|PersonalHanokMap|HanokStageService" lib test tool .github pubspec.yaml
  rg -n "kl_hanok_state_v1|hanok_state_json" lib test
  ```

  Expected: the first command has no matches. The second command matches only
  `legacy_hanok_v1_importer.dart` and the four explicit migration/cloud/guard tests.

- [ ] **Step 3: Run formatting, static analysis, and whitespace gates**

  Run:

  ```powershell
  dart format lib test
  flutter analyze
  git diff --check
  ```

  Expected: no analyzer issue and no whitespace error.

- [ ] **Step 4: Run the focused state, preview, route, and CI suites**

  Run:

  ```powershell
  flutter test test/hanok_v3_preview_test.dart test/hanok_preview_routing_test.dart test/ildu_world_state_service_test.dart test/legacy_hanok_v1_importer_test.dart test/data_migration_test.dart
  flutter test test/hanok_cloud_sync_test.dart test/hanok_account_reconciliation_test.dart test/hanok_competence_projection_test.dart test/ildu_world_screen_test.dart test/ildu_world_projection_adapter_test.dart
  flutter test test/sori_stage_hanok_shortcuts_test.dart test/sori_stage_hanok_fold_test.dart test/sori_stage_today_sections_test.dart test/sori_stage_visual_evidence_test.dart
  python -m unittest .github/scripts/test_ci_scope.py
  ```

  Expected: all PASS.

- [ ] **Step 5: Run the full repository gates**

  Run:

  ```powershell
  flutter test
  python -m unittest discover -s tool -p 'test_*.py'
  flutter build web --release

  ```

  Expected: all tests pass and the web release build completes with no missing-asset error.

- [ ] **Step 6: Inspect the preview at representative widths**

  Capture or inspect the Hanok tab and `/hanok` preview at `320 x 640`, `390 x 844`, and a
  tablet width of `768`. Confirm the full roof, front gate, mountain skyline, and bottom wall
  remain visible; side margins use the theme surface; the updating copy wraps at 200% text;
  and tapping the image changes neither route nor state.

- [ ] **Step 7: Update Graphify and review only owned changes**

  Run:

  ```powershell
  graphify update .
  git status --short
  git diff --stat
  git diff -- docs/superpowers/specs/2026-09-11-hanok-v1-retirement-v3-preview-design.md docs/superpowers/plans/2026-09-11-hanok-v1-retirement-v3-preview.md
  ```

  Do not stage `graphify-out/graph.json`. Review unexpected files before any commit request.

- [ ] **Step 8: Conditional final commit and remote gates**

  If and only if the user explicitly authorizes commit/push/PR work, commit only owned files,
  push the branch, open or update one focused PR, verify required CI at the exact PR head, and
  request merge authority separately. After merge, verify the exact merge SHA on `main`
  before applying the repository's approved worktree-cleanup audit.

## Pre-execution Self-Review

- Spec coverage: Tasks 1-2 cover the exact image, contain layout, non-interaction, message,
  and deep-link quarantine. Tasks 3-4 cover local and cloud one-time import. Tasks 5-7 remove
  V1 runtime, asset, tool, and CI triggers without deleting shared progress or V3 code. Task 8
  covers functional, visual, static, build, and graph verification.
- Type consistency: `IlDuWorldState` is produced in Task 3 and consumed by Tasks 3-4;
  `HanokCompetenceProjection` remains the shared progress type; `IlDuWorldProjection` remains
  the V3 screen type; no later task refers to `HanokState` as a production type.
- Destructive boundary: every deletion is a tracked Git removal recoverable from history, and
  it occurs only after caller searches and replacement tests.
- Authority boundary: every commit, push, PR, merge, deployment, and worktree removal remains
  conditional on an explicit user request.
## Appendix: Detailed File Inventory

### Create

- `assets/illustrations/hanok/ildu_v3_preview.png` — exact user-supplied temporary artwork.
- `lib/widgets/sori/hanok_v3_preview.dart` — reusable non-interactive preview composition.
- `lib/screens/hanok_preview_screen.dart` — safe destination for existing Hanok deep links.
- `lib/models/ildu_world_state.dart` — V3-owned settings and deterministic merge model.
- `lib/services/ildu_world_state_service.dart` — strict local serialization and CAS writes.
- `lib/services/legacy_hanok_v1_importer.dart` — the sole legacy JSON decoder and converter.
- `lib/services/hanok_competence_projection_service.dart` — CourseMastery-only progress reader for shared non-V1 surfaces.
- `test/hanok_v3_preview_test.dart` — byte, layout, interaction, and semantics contract.
- `test/ildu_world_state_service_test.dart` — V3 schema, strict decoding, merge, and CAS tests.
- `test/legacy_hanok_v1_importer_test.dart` — local and cloud one-time import behavior.
- `test/hanok_v1_retirement_guard_test.dart` — forbidden V1 runtime and asset-root scan.

### Modify

- `lib/widgets/sori/updating_scene.dart`
- `lib/screens/sori_stage/sori_stage_hanok_screen.dart`
- `lib/screens/sori_stage/sori_stage_today_screen.dart`
- `lib/screens/learning_path_screen.dart`
- `lib/screens/onboarding_v2/onboarding_hanok_growth_preview.dart`
- `lib/screens/ildu_world_screen.dart`
- `lib/screens/personal_room_furnish_screen.dart`
- `lib/screens/scenario_player_screen.dart`
- `lib/screens/ux_preview_app.dart`
- `lib/main.dart`
- `lib/models/hanok_growth.dart`
- `lib/models/sori_stage_progression.dart`
- `lib/services/data_migration_service.dart`
- `lib/services/hanok_experience_projector.dart`
- `lib/services/ildu_world_projection_adapter.dart`
- `lib/services/sori_stage_progression_service.dart`
- `lib/services/storage_service.dart`
- `lib/services/cloud_sync.dart`
- `lib/services/account/account_reconciliation.dart`
- `lib/data/personal_room_catalog.dart`
- `lib/widgets/sori/madang_background.dart`
- `pubspec.yaml`
- `.github/scripts/ci_scope.py`
- `.github/scripts/test_ci_scope.py`
- `.github/workflows/ci.yml`
- `test/data_migration_test.dart`
- `test/sori_updating_scene_test.dart`
- `test/sori_stage_hanok_fold_test.dart`
- `test/sori_stage_hanok_shortcuts_test.dart`
- `test/sori_stage_visual_evidence_test.dart`
- `test/ildu_world_screen_test.dart`
- `test/ildu_world_projection_adapter_test.dart`
- `test/hanok_cloud_sync_test.dart`
- `test/hanok_account_reconciliation_test.dart`
- `test/support/responsive_screens.dart`
- `test/ux_preview_app_test.dart`
- `test/asset_catalog_bidirectional_test.dart`
- `test/asset_orphan_guard_test.dart`
- `tool/asset_inventory.py`
- `tool/check_personal_room_assets.py`
- `tool/test_check_style_conformance.py`

### Delete after callers are removed

- `lib/data/a1_hanok_construction_catalog.dart`
- `lib/data/personal_hanok_catalog.dart`
- `lib/data/personal_hanok_estate_stage_catalog.dart`
- `lib/data/personal_hanok_venue_catalog.dart`
- `lib/models/personal_hanok.dart`
- `lib/models/hanok_build_narrative.dart`
- `lib/screens/hanok_world_screen.dart`
- `lib/services/hanok_build_narrative_service.dart`
- `lib/services/hanok_cutover_service.dart`
- `lib/services/hanok_state_service.dart`
- `lib/services/hanok_stage_service.dart`
- `lib/services/hanok_structure_projection_service.dart`
- `lib/services/personal_hanok_reveal_service.dart`
- `lib/widgets/sori/a1_hanok_construction_map.dart`
- `lib/widgets/sori/hanok_build_narrative_line.dart`
- `lib/widgets/sori/hanok_cinematic.dart`
- `lib/widgets/sori/personal_hanok_map.dart`
- `lib/widgets/sori/personal_hanok_unlock_reveal.dart`
- `lib/widgets/sori/personal_hanok_venue_sheet.dart`
- `lib/widgets/sori/world_map_viewport.dart`
- V1-only tests and goldens named `a1_hanok_*`, `personal_hanok_*`, `hanok_world_screen_test.dart`, `hanok_build_narrative*`, `hanok_cutover_service_test.dart`, `hanok_state_service_test.dart`, `hanok_structure_projection_service_test.dart`, and `world_map_viewport_test.dart`.
- V1-only tools and tests named `derive_hanok_a1_*`, `compose_hanok_a1_state.py`, `compose_a2_exterior_overlays.py`, `derive_estate_building_stages.py`, `hanok_a1_kit.py`, `hanok_v1_asset_contract.py`, `promote_hanok_a1_states.py`, `register_hanok_construction_stages.py`, and `check_personal_hanok_assets.py`.

---
