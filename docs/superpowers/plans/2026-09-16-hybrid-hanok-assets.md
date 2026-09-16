# Hybrid Hanok Artwork Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Reduce initial mobile asset delivery while preserving exact artwork and offline access to downloaded buildings.

**Architecture:** A shipped immutable manifest identifies approved downloadable Hanok packs. A verified cache-backed loader feeds existing artwork widgets. A gated packaging tool excludes downloadable files only after exact remote verification.

**Tech Stack:** Flutter/Dart, existing http/crypto/path_provider/connectivity_plus, Python standard library/PyYAML, Firebase Storage.

**Spec:** `docs/superpowers/specs/2026-09-16-hybrid-hanok-assets-design.md`

**Approved follow-through:** Jin subsequently authorized commit/PR creation, original publication, and hybrid activation. All 202 objects were published and freshly hash-verified; the feature branch's pubspec is activated. Live TTS rules and App Check configuration were preserved. See the asset-delivery runbook and activation receipt for evidence. Main integration and app-store rollout are separate steps.

## Global Constraints

- No commit, push, merge, remote upload, rules deployment, or release without separate explicit authorization.
- Preserve the exact approved image/video bytes and existing visual composition.
- Keep all non-Hanok assets, sixteen Sarangchae stages, six Hyeopmun stages, and shared lesson illustrations bundled.
- Curriculum/progression/XP/access semantics remain unchanged.
- Wi-Fi/ethernet automatic preparation; cellular/unknown connectivity requires explicit download.
- Android/iOS offline cache is persistent Application Support storage; web has a conditional in-memory implementation.
- Dedicated immutable `learning-art/v1/<sha256>.<png|webp>` storage in `ko-lernen-app.firebasestorage.app`.
- Exact length/SHA-256 verification, atomic writes, bounded transport, coalescing, safe removal, 300 MiB cap.
- No added package dependencies; every user-visible string uses DE/EN ARB.
- Normal pubspec remains fully bundled until an explicit exact-remote verification activates the hybrid bundle.

### Task 1: Reproducible manifest and gated release tooling

**Files:** Create `tool/hanok_asset_delivery.py`, `tool/test_hanok_asset_delivery.py`, `assets/data/hanok_download_manifest.json`, and `docs/assets/HANOK_ASSET_DELIVERY.md`. Do not edit pubspec or existing source artwork. The controller owns design/plan files and later Dart tasks.

**Interfaces:** Produce the manifest schema in the spec verbatim. Export `build_manifest(root: Path) -> dict`, `hybrid_pubspec(root: Path, manifest: dict) -> str`, and functions for strict manifest/local/remote verification. CLI supports manifest generation/check, report/candidate pubspec, staging immutable upload objects without network mutation, and activation after full remote verification. Use standard argparse subcommands with clear help.

- [x] Write unittest fixtures with starter and deferred artwork proving deterministic hashes and exact bucket/path schema. Include duplicate bytes, unreferenced directory strays, and retained siblings in asset folders.
- [x] Implement manifest generation from `ildu_construction_art_v1.json`, `ildu_world_manifest_v1.json`, and literal PNG frame names in `lib/data/ildu_turntable_catalog.dart`. Defer eight construction series excluding hyeopmun. Group construction and turnarounds by building, map sotdaeulmun to main-gate and sadang_hyeopmun to hyeopmun; turnarounds are deferred even when hyeopmun construction is bundled. World background/buildings are a separate pack. Use readable ko/en/de names. Include only referenced art. Preserve lowercased source digests and exact lengths.
- [x] Generate a candidate pubspec by expanding affected directory entries, retaining every nondeferred file and all unrelated YAML/comment/font content. Explicit deferred file entries must also be excluded. Preserve source artwork. For stray nonimage files in deferred dirs, report them separately rather than silently delete/exclude unrelated files.
- [x] Implement fail-closed remote verification via the fixed Firebase HTTPS media endpoint: exact bytes/hash, bounded size/time, no redirect, no supplied arbitrary URLs. Activation requires a non-main worktree, matching input pubspec fingerprint and local source/manifest validation, verifies every unique remote object fresh, writes backup/candidate/receipt, then atomically changes only pubspec. No activate action by default. No uploader or deployment execution; stage files plus metadata/instructions for later approved publishing.
- [x] Add tests ensuring one missing/incorrect/redirected/oversized remote object leaves pubspec unchanged; exact expected bundle exclusion; starters intact; stale manifest rejection; main activation rejection. Run `python -m unittest tool.test_hanok_asset_delivery`.
- [x] Run generation/check/report against the current worktree and stage reviewable outputs under ignored `build/hanok-delivery/`. Document actual before/after raw asset totals and publishing/rollback commands. The default project must still build offline with all images available.

### Task 2: Verified cross-platform artwork loading

**Files:** Create focused files under `lib/services/hanok_assets/`: manifest models, service, transport, store interface, native store, web/in-memory store. Tests under `test/services/hanok_assets/`. Modify no UI files. Do not change Task 1 schema without coordinating with controller.

**Interfaces:** Barrel `lib/services/hanok_assets/hanok_asset_delivery.dart` exposes `HanokAssetDelivery extends ChangeNotifier`, static `shared`, `Future<Uint8List> load(String assetPath, {AssetBundle? bundle, bool allowMobileData = false})`, `Future<void> downloadPack(String packId, {bool allowMobileData = false})`, `Future<List<HanokPackStatus>> statuses()`, and `Future<void> removePack(String packId)`. `HanokPackStatus` exposes pack, availableBytes, isComplete, isDownloading, failure. Pack exposes id, title map, assets, totalBytes. Public typed failure distinguishes explicit-download-needed from transient/network/corrupt/cache-full failures. Provide test injection for manifest, bundle, store, fetch, connectivity.

- [x] Write tests using a bundle that misses deferred assets, a memory store, and controlled fetch futures. Verify bundled load performs no network/connectivity initialization; cached offline load; exact bytes verification; only requested pack downloads; policy requiring cellular action.
- [x] Parse and validate shipped manifest strictly. Implement official fixed HTTPS media URI construction and bounded streaming transport with redirect rejection, exact byte length, SHA-256 verification, and timeouts. Bound total active fetches (at most two), coalesce identical hashes, close failed requests, and handle background errors.
- [x] Detect bundled availability for statuses/downloadPack without reading every image into memory. Expose status `isBundled` and `storedBytes`; full-bundle default must not download duplicate packs or offer deletion of package assets. Inject bundled-path detection in tests.
- [x] Preserve existing Firebase App Check: lazily attach the current token as `X-Firebase-AppCheck` on HTTP network misses only when Firebase is configured. Inject the bounded token provider for tests, never log/persist tokens, and do not weaken enforcement. Bound the total request duration, not only individual response chunks.
- [x] Add conditional platform storage: native Application Support `hanok_art/v1`, unique temp files and verified atomic promotion, web memory. No direct `dart:io` dependency on web implementation paths. Corrupt cache is not exposed. Cap native cache at 300 MiB; fail cleanly without silently evicting offline packs. Enumerate only owned immutable filenames; no recursive deletion of arbitrary paths.
- [x] Implement selected-image-first loading and best-effort same-pack preparation when policy permits. Native downloaded files survive fresh service instances. Removal drains or cancels affected downloads so late completion cannot recreate removed data; preserve shared hashes used by other complete packs. State/progress notifications and actual byte counts must remain consistent after failure/retry/removal.
- [x] Add optional `bool prefetchPack = true` to load; when false, load only the requested image. Test that passive map sprites cannot trigger whole-pack fetches.
- [x] Exercise concurrent load coalescing, capacity, corrupt file, retry, restart, partial pack, clear while download pending, shared bytes, web compilation boundary. Run focused flutter tests/analyze. Report exact API and injection usage for UI worker.

### Task 3: Artwork and downloads UI integration

**Files:** Create `lib/widgets/hanok_asset_image.dart`, `lib/screens/hanok_downloads_screen.dart`; update `lib/screens/ildu_construction_screen.dart`, `lib/screens/ildu_world_screen.dart`, `lib/widgets/sori/hanok_turntable_2d.dart`, `lib/screens/sori_stage/sori_stage_reward_receipt_sheet.dart`, and settings link in `lib/screens/settings_screen.dart`. Add DE/EN ARB entries and regenerate localizations. Update focused widget tests and required source inventory if repository gates require it.

**Interfaces:** Consume Task 2 barrel API. `HanokAssetImage(String assetPath, {key, width, height, fit, alignment, cacheWidth, cacheHeight, semanticLabel, excludeFromSemantics, errorBuilder, HanokAssetDelivery? delivery})` preserves image parameters. Bundled assets should keep AssetImage-compatible fast rendering where practical so current deterministic tests remain useful.

- [x] Add a focused widget test harness with injected service for pending transfer, cellular action, successful image, failed download/retry, and path change without stale image. Test narrow/large text states.
- [x] Wire deferred construction stage images and B2 receipt images; keep shared lesson and Sarangchae imagery bundled. Replace deferred world/turntable images without changing authored bounds, cropping, cache dimensions, frame identity, or semantics. Existing thumbnail/decorations outside deferred paths remain unchanged.
- [x] Forward optional `prefetchPack` into load. Use false for passive world/turntable map sprites and receipt comparisons, true for the selected construction lesson. Do not download every building pack simply because the world map displays many buildings.
- [x] Render localized preparation/download/retry states. Explicit download action passes allowMobileData true for the chosen pack only. On normal Wi-Fi display, prepare current building in background, never whole estate. Surface unavailable assets honestly without substituting wrong-stage art.
- [x] Add Settings navigation to downloads page listing manifest packs, sizes, progress, available/offline state, download/retry/remove. Use existing Sori components. Removal text explains re-download and never changes learning progress. Web labels must not promise persistent offline storage.
- [x] Run `flutter gen-l10n`, focused new widget tests and `test/ildu_construction_screen_test.dart`, `test/ildu_world_screen_test.dart`, progression/reward tests touched by changes. Run analyze on changed Dart files. Report any baseline/environment issues separately.

### Task 4: Delivery rules, integration validation, reviewable release package

**Files:** Update local `storage.rules` only with narrow canonical artwork get rule; add rule contract/emulator tests using existing repository patterns. Controller performs final integration verification and report; separate reviewers receive diff packages. No deployment.

- [x] Add local public get-only rule for immutable approved images; deny listing/client writes and leave personal/TTS rules unchanged. Test canonical metadata, hash/extension path, missing metadata, listing, and write rejection in existing Firebase test harness or explicit static contract if emulator unavailable.
- [x] Add optional CLI `--app-check-token-env ENV_NAME` for verify-remote/activate so Storage App Check enforcement remains usable; read only the named variable, forward only to the fixed Firebase endpoint, never store/print tokens or add them to receipts. Tests verify forwarding and redaction. This is an integration amendment after Task 1 initial implementation.
- [x] Re-run manifest integrity/check and source media hashes. Validate hybrid candidate bundle composition with a locally generated build artifact where possible; never activate normal pubspec without remote verification. Any temporary candidate-build pubspec change must be isolated and restored with exact hash evidence.
- [x] Run changed-area tests once, `flutter analyze --no-pub`, web release compile, and Python tooling tests. Existing full-bundle tests remain the default baseline; new service/widget tests simulate absent deferred assets without bypassing network/cache behavior.
- [x] Produce exact raw asset exclusion and candidate bundle evidence, remote publication checklist/commands, expected user behavior, and residual release gates. Do not equate local build success with Play/App Store download measurement.
- [x] Obtain task and final independent code reviews via provided subagent tools; fix actionable findings and recheck covering tests. Retain uncommitted work and evidence for user review, with no commit/push/merge until asked. Run Graphify update/prune according to repository rules at finish.
