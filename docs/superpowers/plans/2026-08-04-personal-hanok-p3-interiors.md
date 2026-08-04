# Personal Hanok P3 Interiors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the personal Hanok into three independent, collectible interiors without changing learning progress, rewards, or Gye data.

**Architecture:** Keep the legacy flat 사랑방 placement API as a compatibility facade, while a versioned local store owns `surface → slot → decoration` placements for 사랑방, 안방, and 대청마루. A generic room screen and catalog render each opaque room shell with the existing alpha furnishings. The world map routes only unlocked wings into these rooms; the existing Gye experience remains a separate community surface and is reached through a navigation bridge rather than shared placement state.

**Tech Stack:** Flutter/Dart, SharedPreferences, Flutter widget tests, ARB localization, PNG assets, existing Sori design system.

## Global Constraints

- Preserve `DecorationRewardService`, `ownedDecor`, reward journals, course recommendation priority, and the independent 70% mastery rules exactly.
- Preserve the existing `Storage.roomPlacement`, `setRoomPlacement`, and `RoomPlacementService.placeInSlot` contracts as 사랑방 compatibility aliases.
- Never sync room placements through `cloud_sync.dart`; only `ownedDecor` remains merge-safe across devices.
- A decoration may appear in at most one personal room slot at a time; moving it between rooms removes the prior placement deterministically.
- New user-visible copy must exist in both `l10n/app_de.arb` and `l10n/app_en.arb`, followed by `flutter gen-l10n`.
- Use `SoriTextTheme`, Sori surfaces, 44dp minimum interactions, `SoriContentClamp`, and no new raw user-visible strings.
- New room shells are opaque 1086×1448 PNGs in `assets/illustrations/personal_hanok_v2/interiors/`; user furnishings remain true-alpha existing decoration layers.
- Do not reuse or write Gye art, Firestore data, rules, or social state from personal Hanok code.
- Run targeted red/green tests before each implementation task, then format, analyze, test, and commit only files changed by that task. Update `AGENTS.md` in the same or immediately following commit.

---

### Task 1: Add a versioned multi-surface placement model

**Files:**
- Create: `lib/models/personal_room.dart`
- Modify: `lib/services/storage_service.dart`
- Modify: `lib/services/room_placement_service.dart`
- Modify: `lib/widgets/sori/placed_decoration.dart`
- Test: `test/personal_room_placement_service_test.dart`
- Test: `test/room_placement_storage_test.dart`
- Test: `test/room_placement_service_test.dart`

**Interfaces:**
- Produce `enum PersonalRoomSurface { sarangbang, anbang, daecheongmaru }`.
- Produce `typedef RoomPlacement = Map<String, String>` and `typedef RoomPlacements = Map<PersonalRoomSurface, RoomPlacement>`.
- Produce `Storage.roomPlacements` / `Storage.setRoomPlacements(RoomPlacements)` backed by `kl_room_placements_v2` with an explicit v2-present check.
- Produce `RoomPlacementService.sanitizeAll`, `candidatesForSurfaceSlot`, and `placeInSurfaceSlot` while keeping the existing single-room methods as 사랑방 delegates.

- [ ] **Step 1: Write failing storage migration tests.**

```dart
test('wraps a legacy flat placement as sarangbang only when v2 is absent', () {
  expect(Storage.roomPlacements[PersonalRoomSurface.sarangbang], {
    'wall_back': 'decoration_pyeonaek',
  });
});

test('does not revive legacy placement when an empty v2 payload exists', () {
  expect(Storage.roomPlacements, isEmpty);
});
```

- [ ] **Step 2: Run the storage test to verify RED.**

Run: `flutter test test/room_placement_storage_test.dart`

Expected: compilation failure because `roomPlacements` and `PersonalRoomSurface` do not exist.

- [ ] **Step 3: Implement the minimal model and storage boundary.**

```dart
enum PersonalRoomSurface { sarangbang, anbang, daecheongmaru }

typedef RoomPlacement = Map<String, String>;
typedef RoomPlacements = Map<PersonalRoomSurface, RoomPlacement>;
```

Persist only string-to-string maps, ignore malformed entries, fall back to legacy only when the v2 preference key is absent, and mirror the normalized 사랑방 map back to `kl_room_placement` on every v2 write.

- [ ] **Step 4: Run the storage test to verify GREEN.**

Run: `flutter test test/room_placement_storage_test.dart`

Expected: PASS, including the existing partially malformed legacy JSON regression.

- [ ] **Step 5: Write failing cross-room service tests.**

```dart
test('moves an owned decoration out of another room', () async {
  await RoomPlacementService.placeInSurfaceSlot(
    PersonalRoomSurface.sarangbang,
    'floor_center',
    'decoration_soban',
  );
  await RoomPlacementService.placeInSurfaceSlot(
    PersonalRoomSurface.anbang,
    'floor_center',
    'decoration_soban',
  );
  expect(Storage.roomPlacements[PersonalRoomSurface.sarangbang], isEmpty);
  expect(Storage.roomPlacements[PersonalRoomSurface.anbang], {
    'floor_center': 'decoration_soban',
  });
});
```

- [ ] **Step 6: Run the service test to verify RED.**

Run: `flutter test test/personal_room_placement_service_test.dart`

Expected: compilation failure because multi-surface service APIs do not exist.

- [ ] **Step 7: Implement deterministic global sanitization and writes.**

Normalize surfaces in `sarangbang`, `anbang`, `daecheongmaru` order. Validate slot id and category against the supplied surface catalog, preserve existing valid placements even if the owned set changes, and verify ownership only for a new write. Remove a chosen slug from every other room before committing. Serialize writes through one service queue so two open room screens cannot interleave a stale read/write cycle.

- [ ] **Step 8: Run the placement service tests to verify GREEN.**

Run: `flutter test test/room_placement_service_test.dart test/personal_room_placement_service_test.dart`

Expected: PASS, including legacy single-room calls.

- [ ] **Step 9: Format, analyze, and commit the storage/model task.**

Run:

```text
dart format lib/models/personal_room.dart lib/services/storage_service.dart lib/services/room_placement_service.dart lib/widgets/sori/placed_decoration.dart test/personal_room_placement_service_test.dart test/room_placement_storage_test.dart test/room_placement_service_test.dart
dart analyze lib/models/personal_room.dart lib/services/storage_service.dart lib/services/room_placement_service.dart lib/widgets/sori/placed_decoration.dart
flutter test test/room_placement_storage_test.dart test/room_placement_service_test.dart test/personal_room_placement_service_test.dart
```

Commit only the listed model/storage/service/tests and the matching `AGENTS.md` entry.

### Task 2: Define room catalog and make the room renderer surface-aware

**Files:**
- Create: `lib/data/personal_room_catalog.dart`
- Modify: `lib/widgets/sori/room_layer.dart`
- Test: `test/personal_room_catalog_test.dart`
- Test: `test/room_layer_test.dart`

**Interfaces:**
- Produce `PersonalRoomDefinition` with `surface`, `backgroundAsset`, `slots`, `requires`, and `studyRoute`.
- Produce `personalRoomFor(PersonalRoomSurface surface)`.
- Update `RoomLayer` to accept one current surface plus all normalized placements so marker eligibility follows the same global candidate rule as the picker.

- [ ] **Step 1: Write failing catalog and room-layer tests.**

```dart
test('anbang and daecheong preserve the five slot categories', () {
  expect(personalRoomFor(PersonalRoomSurface.anbang).slots, hasLength(5));
  expect(personalRoomFor(PersonalRoomSurface.daecheongmaru).slots, hasLength(5));
});

testWidgets('hides an empty-room marker when the only decor is in another room', (tester) async {
  // anbang owns the only shelf item; sarangbang must not advertise it.
});
```

- [ ] **Step 2: Run the new tests to verify RED.**

Run: `flutter test test/personal_room_catalog_test.dart test/room_layer_test.dart`

Expected: compilation failure because the catalog and global placement input do not exist.

- [ ] **Step 3: Implement the catalog and renderer wiring.**

Use `kSarangbangSlots` unchanged for 사랑방. Define anbang and daecheong slots with the same five semantic categories and the image-safe fractional coordinates specified by the asset contract. Route all marker eligibility through `RoomPlacementService.candidatesForSurfaceSlot`.

- [ ] **Step 4: Run the catalog and room-layer tests to verify GREEN.**

Run: `flutter test test/personal_room_catalog_test.dart test/room_layer_test.dart`

Expected: PASS, including existing incompatible-slot and dead-marker regressions.

- [ ] **Step 5: Format, analyze, and commit the renderer task.**

Run:

```text
dart format lib/data/personal_room_catalog.dart lib/widgets/sori/room_layer.dart test/personal_room_catalog_test.dart test/room_layer_test.dart
dart analyze lib/data/personal_room_catalog.dart lib/widgets/sori/room_layer.dart
flutter test test/personal_room_catalog_test.dart test/room_layer_test.dart
```

Commit only the listed files and the matching `AGENTS.md` entry.

### Task 3: Create and validate the two opaque personal-room shells

**Files:**
- Create: `assets/illustrations/personal_hanok_v2/interiors/anbang_empty.png`
- Create: `assets/illustrations/personal_hanok_v2/interiors/daecheong_empty.png`
- Create: `tool/check_personal_room_assets.py`
- Test: `test/personal_room_catalog_test.dart`

**Interfaces:**
- `anbang_empty.png` and `daecheong_empty.png` are 1086×1448 RGB/RGBA opaque shells with no baked user collectibles.
- `tool/check_personal_room_assets.py` fails if either asset is missing, has the wrong dimensions, transparent corners, chroma-key pixels, or no reserved placement geometry.

- [ ] **Step 1: Inspect the existing 사랑방 shell and write a failing asset-contract test.**

```dart
test('each personal room definition points to a checked opaque 3:4 shell', () {
  for (final surface in PersonalRoomSurface.values) {
    expect(File(personalRoomFor(surface).backgroundAsset).existsSync(), isTrue);
  }
});
```

- [ ] **Step 2: Run the new test to verify RED.**

Run: `flutter test test/personal_room_catalog_test.dart`

Expected: FAIL because the anbang and daecheong asset paths do not exist.

- [ ] **Step 3: Generate and post-process the two shells.**

Generate each image from the Asset Generation Bible using `sarangbang_empty.png` and the personal estate reference as visual anchors. Retain reserved empty wall, floor, shelves, and peg areas; reject any candidate with baked books, desks, chests, screens, gat, fan, people, labels, Gye art, outline rendering, transparent canvas, or nonmatching camera. Resize/crop only after visual inspection to 1086×1448 and place the final binary under the isolated personal root.

- [ ] **Step 4: Add the checker and run asset verification.**

Run:

```text
python tool/check_personal_room_assets.py
flutter test test/personal_room_catalog_test.dart
```

Expected: checker and catalog test PASS.

- [ ] **Step 5: Commit the room-shell asset task.**

Commit only the two personal room PNGs, their checker/test updates, and the matching `AGENTS.md` entry.

### Task 4: Turn 사랑방, 안채, and 대청 into generic collectible room screens

**Files:**
- Create: `lib/screens/personal_room_furnish_screen.dart`
- Create: `lib/widgets/sori/room_slot_picker.dart`
- Modify: `lib/screens/sarangbang_furnish_screen.dart`
- Modify: `lib/main.dart`
- Modify: `lib/screens/hanok_world_screen.dart`
- Modify: `l10n/app_de.arb`
- Modify: `l10n/app_en.arb`
- Modify: `lib/l10n/generated/app_localizations.dart`
- Modify: `lib/l10n/generated/app_localizations_de.dart`
- Modify: `lib/l10n/generated/app_localizations_en.dart`
- Test: `test/personal_room_furnish_screen_test.dart`
- Test: `test/sarangbang_picker_test.dart`
- Test: `test/hanok_world_screen_test.dart`
- Test: `test/screen_smoke_test.dart`
- Test: `test/responsive_test.dart`

**Interfaces:**
- `PersonalRoomFurnishScreen(surface: PersonalRoomSurface, ...)` reads and writes only via `RoomPlacementService`.
- `SarangbangFurnishScreen` remains a compatible wrapper around the generic 사랑방 surface.
- `/hanok/anbang` and `/hanok/daecheong` render the generic rooms only after their milestones unlock.
- `hanokRouteForZone(anchae)` returns `/hanok/anbang`; `hanokRouteForZone(daecheongmaru)` returns `/hanok/daecheong`.

- [ ] **Step 1: Write failing direct-route lock and screen behavior tests.**

```dart
testWidgets('locked anbang never exposes a placement write action', (tester) async {
  await tester.pumpWidget(_host(const PersonalRoomFurnishScreen(
    surface: PersonalRoomSurface.anbang,
  )));
  expect(find.byType(RoomLayer), findsNothing);
});

test('canonical map routes completed anchae into its interior', () {
  expect(hanokRouteForZone(PersonalHanokZone.anchae), '/hanok/anbang');
});
```

- [ ] **Step 2: Run the screen test to verify RED.**

Run: `flutter test test/personal_room_furnish_screen_test.dart test/hanok_world_screen_test.dart`

Expected: compilation failure because the generic screen and routes do not exist.

- [ ] **Step 3: Implement the generic room screen with a strict unlock gate.**

Use `HanokStageService.levelRatios` and `PersonalHanokProjection` only to gate rendering. The locked branch must show localized explanation and a route back to `/hanok`, and it must not instantiate the picker or call the placement service. The unlocked branch renders the shell, global placements, current-room slots, the shared picker, and one localized existing-study CTA for that room.

- [ ] **Step 4: Preserve 사랑방 behavior through the wrapper.**

Move `kSlotPickClear` and `SlotPickerSheet` to the reusable widget file, keep the dismissed-sheet-vs-clear sentinel invariant, keep the 보자기 action only on 사랑방, and update the existing picker tests to import the shared component.

- [ ] **Step 5: Add DE/EN copy, regenerate localization, and wire routes.**

Add only localized titles, room purpose, locked explanation, return-to-map action, and per-room study CTA labels. Run `flutter gen-l10n`; do not hand-edit generated localization output. Add the two named routes in `main.dart`, update world routes, smoke registry, and responsive screen registry.

- [ ] **Step 6: Run focused functional and layout verification.**

Run:

```text
dart format lib/screens/personal_room_furnish_screen.dart lib/widgets/sori/room_slot_picker.dart lib/screens/sarangbang_furnish_screen.dart lib/screens/hanok_world_screen.dart lib/main.dart test/personal_room_furnish_screen_test.dart test/sarangbang_picker_test.dart test/hanok_world_screen_test.dart
dart analyze lib/screens/personal_room_furnish_screen.dart lib/widgets/sori/room_slot_picker.dart lib/screens/sarangbang_furnish_screen.dart lib/screens/hanok_world_screen.dart lib/main.dart
flutter test test/personal_room_furnish_screen_test.dart test/sarangbang_picker_test.dart test/hanok_world_screen_test.dart test/room_layer_test.dart
flutter test test/screen_smoke_test.dart test/responsive_test.dart
```

Expected: PASS on phone, portrait tablet, landscape tablet, and 1.3x system text smoke cases.

- [ ] **Step 7: Commit the room-screen and map-routing task.**

Commit only the listed screen/router/l10n/test files and matching `AGENTS.md` entry.

### Task 5: Add a safe personal-estate to Gye navigation bridge

**Files:**
- Modify: `lib/screens/gye_tab_screen.dart`
- Modify: `lib/main.dart`
- Modify: `lib/screens/hanok_world_screen.dart`
- Modify: `l10n/app_de.arb`
- Modify: `l10n/app_en.arb`
- Modify: `lib/l10n/generated/app_localizations.dart`
- Modify: `lib/l10n/generated/app_localizations_de.dart`
- Modify: `lib/l10n/generated/app_localizations_en.dart`
- Test: `test/hanok_world_screen_test.dart`
- Test: `test/gye_tab_screen_test.dart`

**Interfaces:**
- Produce `/gye/hub`, a standalone route that hosts the existing `GyeTabScreen` with no duplicated community logic.
- Keep `PersonalHanokZone.gyeRoad` noninteractive and keep all personal room storage separate from Gye.

- [ ] **Step 1: Write failing bridge tests.**

```dart
testWidgets('estate world offers the existing Gye hub without making the road zone interactive', (tester) async {
  expect(zoneFor(PersonalHanokZone.gyeRoad).isInteractive, isFalse);
  expect(find.byKey(const ValueKey('hanok-world-gye-bridge')), findsOneWidget);
});
```

- [ ] **Step 2: Run the test to verify RED.**

Run: `flutter test test/hanok_world_screen_test.dart`

Expected: FAIL because the bridge card and standalone route do not exist.

- [ ] **Step 3: Implement the route and a localized world bridge card.**

Place the card outside the canonical map hit regions so the painted Gye road stays an intentional noninteractive landmark. Route to the existing Gye tab screen; do not add personal decorations, donations, Firestore fields, or age-gate bypasses.

- [ ] **Step 4: Add ARB copy, regenerate localization, and verify GREEN.**

Run:

```text
flutter gen-l10n
dart format lib/screens/gye_tab_screen.dart lib/main.dart lib/screens/hanok_world_screen.dart test/hanok_world_screen_test.dart test/gye_tab_screen_test.dart
dart analyze lib/screens/gye_tab_screen.dart lib/main.dart lib/screens/hanok_world_screen.dart
flutter test test/hanok_world_screen_test.dart test/gye_tab_screen_test.dart
```

Expected: PASS; existing Gye creation/join flows remain unchanged.

- [ ] **Step 5: Commit the Gye bridge task.**

Commit only the bridge files and matching `AGENTS.md` entry.

### Task 6: Run final P3/P4 regression and document the completed boundary

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/SESSION_HANDOFF_INTEGRATION_2026-08-04.md` only if its snapshot is now stale

- [ ] **Step 1: Verify source formatting and unintended diff scope.**

Run:

```text
git diff --check
git status --short
```

Expected: no whitespace errors; concurrent `hanok_compound` files remain unstaged.

- [ ] **Step 2: Run the complete regression suite and analyzer.**

Run:

```text
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter silent
python tool/check_personal_hanok_assets.py
python tool/check_personal_room_assets.py
```

Expected: all commands exit 0.

- [ ] **Step 3: Record actual verification and commit the closing documentation.**

Update `AGENTS.md` with exact test commands, results, commit hashes, and the fact that room placements remain local-only while Gye remains an independent community surface. Commit only the documentation files changed for this closeout.
