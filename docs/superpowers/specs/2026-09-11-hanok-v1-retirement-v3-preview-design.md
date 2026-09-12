# Hanok V1 retirement and V3 preview design

Status: approved in conversation on 2026-09-11
Scope: Flutter app, local persistence, cloud reconciliation, asset/tool tests, and CI routing
Out of scope: publishing, PR merge, Firebase deployment, and completing the interactive IlDu V3 map

## 1. Problem

`main` removed the Personal Hanok V1 runtime images, but the application still declares,
imports, tests, and routes through the V1 presentation stack. `flutter pub get` therefore
reports missing `personal_hanok_v2` directories, and the full app gate continues to run for
retired Hanok provenance documents and tools.

The replacement IlDu V3 world is not visually or behaviorally complete. It must not be
presented as a finished interactive destination. Until that work is approved, the product
needs one truthful static preview and no path back to either the retired V1 world or the
unfinished V3 editor.

## 2. Decisions

1. Personal Hanok V1 is retired rather than restored.
2. Existing learner progress is not discarded. Course mastery remains the authority for
   future V3 unlocks, and the meaningful user-owned portion of the V1 presentation state is
   imported once into a V3-owned state record.
3. The supplied portrait image is the temporary preview. It is shown in full with no crop,
   recolor, blur, grain, or generated replacement.
4. The preview is informational, not an affordance: it has no tap handler, button semantics,
   hotspot, or route into the interactive map.
5. `/hanok` and the unfinished room deep links remain safe for old links, but resolve to the
   same preview screen rather than V1 or V3 interactive UI.
6. Historical prose may remain in Git history or documentation, but it must not participate
   in app CI merely because it lives below `docs/assets/`.

## 3. Terminology and boundary

### Retired V1 presentation stack

- `HanokWorldScreen`, `PersonalHanokMap`, the A1 construction compositor, V1 reveal and
  venue sheets, and their supporting Personal Hanok catalogs.
- Runtime paths below `assets/illustrations/personal_hanok_v2/` and
  `assets/illustrations/hanok_stages/`.
- V1 production/provenance tools and tests whose only output is one of those removed asset
  families.
- Local key `kl_hanok_state_v1`, cutover key `kl_hanok_cutover_v2`, reveal ledgers, and the
  cloud field `hanok_state_json`, except inside the isolated import-only compatibility code.

### Preserved shared domain

- `CourseMasterySnapshot` and completed, non-bypassed course evidence.
- Semantic Hanok stages and competency projection where they are still used by learning
  results, Gye, or future V3 progress. They must not load V1 images or pack-derived progress.
- IlDu V3 manifest, construction plan, anchor placement, decoration placement, turntables,
  and approved V3 assets.
- Room-v3 layouts, earned decorations, stamps, quests, SRS, and Gye state.

The retirement guard targets V1 presentation identifiers and asset roots, not every symbol
containing the word `hanok`.

## 4. Preview contract

### Source and destination

- Source supplied by the user:
  `C:\Users\vjinn\AppData\Local\Temp\codex-clipboard-9d184af7-2443-4ae5-bf1c-5f4db5f8c182.png`
- Verified source byte length: `2,127,303`
- Verified source dimensions: `768 x 1376`, RGB PNG
- Verified SHA-256:
  `c35e5b89a2f2154a61b07ed0d8e0b02b6d6e7b063825b10b132f02a95f14c0c6`
- Runtime destination:
  `assets/illustrations/hanok/ildu_v3_preview.png`

The destination must be byte-identical to the supplied source. The existing
`assets/illustrations/hanok/` declaration already bundles this leaf directory, so no new
directory declaration is required.

### Rendering

- Use `BoxFit.contain` and `Alignment.center`.
- Fill unused horizontal space with the current theme's `SoriSurfaces.surfaceAlt`, which is
  the existing paper-like surface color; do not introduce an image-derived hard-coded color.
- Keep the existing static veil, construction icon, and localized
  `soriStageHanokUpdating` message.
- Preserve the current pinned header sizing and reduced-motion behavior. The artwork may
  become small in the collapsed header, but it must still remain uncropped.
- Expose one image semantic label containing the localized updating message. Do not expose
  `button: true`, `onTap`, or map instructions.
- A dedicated `HanokPreviewScreen` reuses the same preview widget for old deep links.

## 5. One-time data migration

### Authority

No visual stage, building, or earned grant is copied from V1 as authoritative progress.
Future V3 availability is recomputed from `CourseMasterySnapshot`. Placement level, pack
ratios, browse history, XP, stamps, quests, and Gye never grant V3 ownership.

### V3-owned state

Introduce `IlDuWorldState` under the V3 domain with:

- `schemaVersion = 1`
- `migrationVersion = 1`
- `sourceManifestVersion` from the valid V1 state when present
- `activeDesignSelections`, retaining stable slot/grant IDs and their LWW clocks
- `carePreferences`, retaining the last eligible activity, vacation/display/notification
  settings, their LWW clock, and notified tier IDs

V1 `seenRevealIds` are deliberately not migrated. They identify retired visual assets and
must not suppress future V3 reveals. V1 map coordinates are also not migrated: there is no
approved one-to-one coordinate or anchor mapping.

The local key is `kl_ildu_world_state_v1`; the cloud field is
`ildu_world_state_json`. A local marker `kl_hanok_v1_to_ildu_v3_v1` is written only when a
V1 source actually existed and was successfully imported. A new installation with no V1
source must not be stamped, because it may later sign in and receive a legacy-only cloud
backup.

### Local transaction order

The migration is production schema step 2 in `DataMigrationService`:

1. Read and strictly validate the V1 JSON if the source key exists.
2. Read the existing V3 state if present and merge by the existing LWW clock rules.
3. Write V3 JSON and verify the persisted value.
4. Remove `kl_hanok_state_v1`, `kl_hanok_cutover_v2`,
   `kl_hanok_stages_seen_v1`, and `kl_personal_hanok_milestones_seen_v1`.
5. Write the import marker.
6. Let `DataMigrationService` write schema version 2 only after the whole step succeeds.

The migration runner's backup/journal rollback remains authoritative. A malformed source,
rejected write, or interrupted step leaves schema version 1 and restores every original key.
Repeated execution produces the same V3 state and does not duplicate any selection or tier.

### Cloud compatibility

- New backups emit `ildu_world_state_json` only.
- Reconciliation prefers a valid V3 field when both fields exist.
- If V3 is absent and `hanok_state_json` is present, the same strict importer converts it
  before merge. This is the only remaining V1 code path.
- A malformed legacy field fails reconciliation without overwriting valid local V3 state.
- Once V3 exists, a stale legacy cloud field is ignored and is not parsed again.
- No Firebase deployment or bulk document deletion is part of this change.

## 6. Runtime retirement

- The Sori Hanok tab renders the static preview and its existing independent shortcut
  counts. It no longer constructs an embedded `HanokWorldScreen` or waits for a Personal
  Hanok projection.
- The Today Hanok card uses the same preview art and removes old stage-image lookup and map
  navigation. Numeric learning progress, if retained, comes from trusted course competency.
- Learning-path and onboarding surfaces must not load `personal_hanok_v2` or
  `hanok_stages`; they use the static preview or a non-image progress treatment.
- `IlDuWorldScreen` remains as dormant V3 implementation work, but it must not default
  through `PersonalHanokProjection`. Its projection input is V3-native and fail-closed.
- `/hanok`, `/hanok/anbang`, and `/hanok/daecheong` resolve to
  `HanokPreviewScreen` until a separately approved V3 release changes the route.
- V1-only renderers, catalogs, asset validators, generation scripts, tests, and pubspec
  entries are removed. Shared Hanok domain and IlDu V3 tooling remain.

## 7. CI and regression protection

Replace the broad `docs/assets/` app trigger with the live test/tool inputs:

- `docs/assets/STYLE_LOCK.json`
- `docs/assets/CARD_STYLE_BASELINE.json`
- `docs/assets/VOCAB_PACK_CARD_MANIFEST.json`
- `docs/assets/PHASE_ARTWORK_PRODUCTION.json`
- `docs/assets/SFX_README.md`
- `docs/assets/recipes/`

Add a retirement guard that fails when production source or `pubspec.yaml` contains either
retired asset root, or when V1 screen/map identifiers reappear. The local/cloud V1 storage
identifiers are allowed only in the import-only compatibility file and migration tests.

Required verification:

- Preview source hash, `BoxFit.contain`, paper side fill, semantics, and non-interactivity.
- 390dp phone, 320dp narrow phone, 200% text, collapsed header, and reduced motion.
- Local migration success, no-source behavior, idempotence, existing-V3 merge, malformed
  input rollback, write rejection rollback, and precise legacy-key cleanup.
- Cloud V3 round trip, legacy-only import, V3 precedence, malformed legacy rejection, and
  local-generation conflict preservation.
- `flutter pub get` with no missing V1 directory warning.
- Focused Flutter and Python tests, `flutter analyze`, full `flutter test`, and a release web
  build before integration.

## 8. Completion boundary

This work is complete when the app displays only the approved static preview, no user route
opens V1 or unfinished V3 interaction, valid legacy state can be imported exactly once,
retired asset roots have zero live references, and all required checks pass. Commit, push,
PR creation, merge, deployment, and worktree deletion remain separate authority gates.
