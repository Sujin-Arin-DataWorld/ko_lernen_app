# Living Hanok Learning World — Execution Plan

> **Executor note:** follow the contract in `../specs/2026-08-04-living-hanok-learning-world-design.md`. Preserve unrelated dirty `hanok_compound/` prototype files. Commit only files listed for each task.

## Task 1 — Pure personal-world projection and catalog

**Files:**
- Create `lib/models/personal_hanok.dart`
- Create `lib/data/personal_hanok_catalog.dart`
- Create `test/personal_hanok_catalog_test.dart`
- Create `tool/check_personal_hanok_assets.py`
- Update `pubspec.yaml`

1. Write tests first for all thresholds, monotonicity, legacy fallback, map-only asset paths, and pond-before-bridge z-order.
2. Implement `PersonalHanokProjection.from(LevelRatios)` with no storage or service writes.
3. Put visual layer metadata and semantic hit-zone metadata in a catalog; keep placement coordinates separate from assets.
4. Make the asset checker fail closed for missing or malformed future assets, but do not run it as green until the image family exists.
5. Run the focused test and analyzer. Commit the model/catalog only.

## Task 2 — Canonical personal map art family

**Files:**
- Create only `assets/illustrations/personal_hanok_v2/**`
- Update `tool/check_personal_hanok_assets.py` only if a discovered format fact requires it

1. Produce and visually inspect an opaque base and completed-estate reference.
2. Produce full-canvas true-alpha structure overlays from the same map camera: gate, haengrang, sarangchae, anchae, daecheong, sadang.
3. Produce independently redrawn landscape overlays: pond, bridge, garden, pavilion, jars, lanterns.
4. Run the checker and a composite inspection at phone/tablet target sizes.
5. Commit art only after a composite is coherent; never mix in the old prototype family.

## Task 3 — Map renderer and world route

**Files:**
- Create `lib/widgets/sori/personal_hanok_map.dart`
- Create `lib/screens/hanok_world_screen.dart`
- Update `lib/main.dart`
- Create `test/personal_hanok_map_test.dart`
- Update ARB/generated l10n as required

1. Write a widget test that proves a B1-25% projection exposes the gate and a B2-100% projection exposes the finished map layers.
2. Render the base and unlocked overlays in fixed z-order; never calculate unlocks in the renderer.
3. Add semantic 44dp map targets and route each supported location through the contract.
4. Keep the Gye road noninteractive and preserve the legacy stage art before the map boundary.
5. Add `/hanok` with the shared route transition.

## Task 4 — Sarangbang as the learning venue

**Files:**
- Create `lib/screens/sarangbang_furnish_screen.dart`
- Replace `lib/screens/sarangbang_screen.dart` with study venue
- Create `lib/services/sarangbang_recommendation_service.dart`
- Update `lib/screens/home_screen.dart`, `lib/screens/bojagi_screen.dart`, `lib/main.dart`
- Update `test/sarangbang_picker_test.dart`
- Create `test/sarangbang_study_screen_test.dart`

1. Move the current room placement UI intact to `SarangbangFurnishScreen`.
2. Test that the new study screen invokes `recommendMission` with the same source data/priority and carries the original route without inventing learning evidence.
3. Present the resolved mission inside a Sarangbang desk context; primary action opens the existing course/pack/review/scenario target.
4. Change Home primary study actions to open `/sarangbang`; change the bojagi completion CTA to `/sarangbang/furnish`.
5. Add the furnishing affordance from the study screen without changing P1 services.

## Task 5 — Localization, responsive hardening, verification

**Files:**
- `l10n/app_de.arb`, `l10n/app_en.arb`, generated l10n files
- `AGENTS.md`
- tests created above and any narrow route test updates

1. Add DE/EN copy; run `flutter gen-l10n`, never hand-edit generated output.
2. Run targeted widget tests at phone/tablet widths plus existing responsive matrix.
3. Run `dart analyze` and `git diff --check`; run the broad Flutter suite if independent baseline failures are absent.
4. Update `AGENTS.md` with the final state, tests, and every phase commit hash in an immediately following log commit if required.

## Commit sequence

1. `docs(hanok): define living learning world`
2. `feat(hanok): add personal world projection contract`
3. `feat(hanok): add canonical personal map assets`
4. `feat(hanok): add interactive personal world map`
5. `feat(sarangbang): open today's mission in the study room`
6. `test(hanok): harden learning world routes and layout`

No push is part of this plan.
