# Hanok artwork delivery tooling

Hybrid packaging is active in this branch's `pubspec.yaml`. On 2026-09-16,
after explicit approval, all 202 immutable artwork objects were published and
freshly verified by byte length and SHA-256 before activation. Starter artwork,
shared lessons, and all 28 MP4 files remain bundled. No image or video was
resized or recompressed. Main integration and app-store release are separate
steps; this branch activation does not update installed applications.

The machine-readable evidence is
[`hanok-delivery-activation-20260916.json`](hanok-delivery-activation-20260916.json).

## Trust root and pack layout

`assets/data/hanok_download_manifest.json` is generated from:

- `assets/data/ildu_construction_art_v1.json`: eight deferred construction
  series; Hyeopmun's six-stage starter series remains bundled.
- literal `_frame(...)` PNG names in
  `lib/data/ildu_turntable_catalog.dart`: all referenced turntable frames.
- `assets/data/ildu_world_manifest_v1.json`: the V3 canvas, gates, and
  buildings. Decorations resolve through the shared
  `assets/illustrations/decorations/` root and remain bundled.

Construction and turntable frames share building packs. The turntable source
groups `sotdaeulmun` and `sadang_hyeopmun` map to `main-gate` and `hyeopmun`.
Hyeopmun turntable frames are deferred even though Hyeopmun construction stays
bundled. The world is its own pack.

The schema is fixed at `schemaVersion: 1`, bucket
`ko-lernen-app.firebasestorage.app`. Every asset record contains only
`asset`, lowercase `sha256`, positive `bytes`, `contentType`, and
`storagePath`. The storage object is always
`learning-art/v1/<sha256>.<png|webp>`. Duplicate source paths, traversal,
unexpected buckets/prefixes, malformed hashes or lengths, and empty packs are
rejected.

## App behavior

`HanokAssetImage` uses the bundled image first, then a verified downloaded
copy. Missing content downloads automatically on Wi-Fi or Ethernet; cellular
or unknown connections require the user's Download action. Passive world,
turntable, and reward images request only their own files. A selected
construction lesson can prepare the rest of its building pack.

Settings and the world app bar open the downloads page. It distinguishes
included artwork from downloaded packs, shows stored bytes, and supports
download/retry/removal without changing learning progress. Native copies
persist in Application Support with a 300 MiB cap and no automatic eviction
of offline packs. Web copies last only for the current session.

On the first catalog-backed operation after launch, storage is reconciled with
the validated shipped manifest before statuses, cache reads, or downloads run.
Native reconciliation removes only directly contained regular files with owned
SHA-256 PNG/WebP filenames that no longer occur anywhere in the catalog. Current
assets, shared hashes, unrelated files, directories, and links are preserved.
This reclaims obsolete versions before the 300 MiB capacity check; it does not
evict artwork that the current app can still display. Concurrent first requests
share one preparation, and a storage failure can be retried in the same session.
Bundled image loads still bypass catalog/cache preparation and networking.

Mounted missing images observe verified cache completion, including downloads
finished on another page. The service's `readCached(assetPath)` probe performs
no connectivity check, fetch, or change notification; probes coalesce per
service/path and stop when an image becomes available or its widget leaves.
Removal races invalidate pending probes. Removal failures remain visible on
the affected pack through ordinary list refreshes and can be retried.

## Python API

The stable entry points in `tool/hanok_asset_delivery.py` are:

- `build_manifest(root: Path) -> dict`
- `validate_manifest(manifest: dict) -> None`
- `verify_manifest_current(root: Path, manifest: dict) -> None`
- `verify_local_assets(root: Path, manifest: dict) -> dict`
- `verify_remote_assets(manifest: dict, *, open_url=None, timeout=20.0,
  app_check_token=None) -> dict`
- `hybrid_pubspec(root: Path, manifest: dict) -> str`
- `packaging_report(root: Path, manifest: dict) -> dict`
- `stage_upload_objects(root: Path, manifest: dict, output_dir: Path) -> dict`
- `activate(root: Path, manifest: dict, *, expected_pubspec_sha256: str,
  output_dir: Path, open_url=None, timeout=20.0, app_check_token=None) -> dict`

Remote verification constructs the Firebase HTTPS media URL internally. It
accepts no caller URL, follows no redirects, reads at most the declared length
plus one byte, and verifies the exact length and SHA-256. Activation verifies
each unique object afresh.

## Commands

Run these checks from the repository root in the activated configuration:

```powershell
python tool/hanok_asset_delivery.py --root . check
python tool/hanok_asset_delivery.py --root . stage
python -m unittest tool.test_hanok_asset_delivery
```

For a future full-bundle baseline, `generate`, `candidate`, `report`, and
`activate` prepare and activate a new reviewed configuration. `candidate`,
`report`, and `activate` expect the full-bundle input; do not rerun them against
the already activated pubspec. `report` writes
`build/hanok-delivery/candidate-pubspec.yaml` and
`asset-report.json`. `stage` writes one verified copy per immutable object under
`build/hanok-delivery/staging/objects/`, plus `metadata.json` and publishing
instructions. These ignored files are review artifacts, not a deployment.

Verify the live bytes after any approved publication using the staged metadata:

```powershell
python tool/hanok_asset_delivery.py --root . verify-remote
```

If Storage App Check enforcement is enabled, provide a current App Check token
through an environment variable and append `--app-check-token-env VARIABLE_NAME`
to `verify-remote` and `activate`. Obtain it through the project's authorized
App Check flow; do not disable enforcement. The tool sends the value only in
`X-Firebase-AppCheck` to the fixed Firebase endpoint and never includes it in
reports or error messages. A missing or invalid value fails verification.
Never put the token itself in command arguments, source files, or receipts.

Activation also requires that fresh remote verification, a linked non-main
worktree, the current deterministic manifest and local source bytes, and an
exact reviewed pubspec fingerprint. The completed activation used input fingerprint
`f3d65d7cd3e576295d4fd2b2741dc6033b3028aedf1226b6654cae8a0969d3e4`:

```powershell
python tool/hanok_asset_delivery.py --root . activate `
  --expected-pubspec-sha256 f3d65d7cd3e576295d4fd2b2741dc6033b3028aedf1226b6654cae8a0969d3e4 `
  --confirm ACTIVATE_HYBRID_HANOK
```

That fingerprint becomes invalid whenever `pubspec.yaml` changes. Regenerate
and review the candidate rather than substituting a new value blindly.

Activation writes the full-bundle backup, candidate, and receipt under
`build/hanok-delivery/` before atomically replacing only `pubspec.yaml`. To
roll back the packaging file after activation:

```powershell
Copy-Item -LiteralPath build/hanok-delivery/pubspec.full-bundle.yaml `
  -Destination pubspec.yaml
```

Then run the normal packaging checks before a release. A rollback changes only
packaging; downloaded cache cleanup is a separate runtime concern.

## 2026-09-16 activated size report

The checked-in manifest has 13 packs and 202 source assets. No identical
content is duplicated in this snapshot, so it also has 202 immutable objects.

| Measurement | Fully bundled | Activated hybrid | Difference |
| --- | ---: | ---: | ---: |
| `flutter.assets` files | 1,013 | 811 | -202 |
| `flutter.assets` raw bytes | 481,345,124 | 256,865,435 | -224,479,689 |
| Assets plus six registered font files | 1,019 | 817 | -202 |
| Assets plus fonts raw bytes | 487,971,916 | 263,492,227 | -224,479,689 |

The retained Sarangchae, Hyeopmun starter, and shared lesson set is 24 files /
40,989,315 bytes. The candidate exclusion is exactly the manifest path set.
Six unreferenced turnaround PNGs and one extensionless turnaround file remain
explicitly bundled; they are listed in `asset-report.json` and are not staged
for publishing.

Use the delivery tool's expanded pubspec paths and built-file hash checks for
this accounting. The older `tool/asset_inventory.py` bundled flag only handles
directory declarations and mislabels the six explicitly retained PNGs.

These totals include the 81,331-byte manifest and the latest main content
merged into the feature branch at `61f5c819dcd51357617f731ce0b4694ad3d8be49`.
That content update added 270,371 bytes to both packaging configurations;
the artwork reduction remains **224,479,689 bytes (46.0%)**.

A fresh `flutter build bundle --release --no-pub` of the activated pubspec
passed. Its 817 registered project files total **263,492,227 bytes**; the
complete Flutter asset directory, including generated manifests and compiled
Dart data, totals **265,649,838 bytes**. The build excludes exactly the 202
manifest paths. Every retained registered file matches its source SHA-256,
including all 28 MP4 files and `docs/data/cultural_glossary.json` outside
`assets/`. URI-encoded Hangul names were reconciled with source paths.

The earlier full/candidate build comparison measured 489,894,848 versus
265,379,467 bytes before that main content update. Original media inventory
verification covered 888 PNG/WebP/MP4 files (610,125,746 bytes), unchanged from
the initial snapshot. These are local asset-directory measurements, not
AAB/IPA sizes, store download sizes, or installed sizes. Android/iOS release
and per-device measurements remain release gates.

## Local validation

After live publication and activation:

- Fresh remote verification: 202/202 objects, 224,479,689 bytes, exact SHA-256.
- Real HTTPS transport/cache smoke: original PNG and WebP downloaded, verified,
  reopened offline by a fresh service, and removed successfully.
- Activated release asset bundle: build and exact exclusion/source-hash checks passed.
- Delivery/UI/world/construction/reward regression run: 95 passed; two bare
  turntable test fixtures lacked localization delegates. Adding the normal
  app delegates resolved these; all three turntable cases passed on rerun.
- Construction provenance/pixel tests: all 17 cases passed through real
  bundle-first delivery with deterministic source-byte transport. Starter
  bundle assertions and original dimensions/pixel/provenance gates remain.
- Python tooling: 18 passed. Additive live Storage rule overlay emulator:
  4 passed, including unchanged legacy TTS behavior.
- Final whole-repository analyzer after activation and test adaptations:
  no issues. Independent scoped activation/test review passed.
- Activated JavaScript web release build passed in 136.9 seconds with
  `--no-wasm-dry-run`.

Earlier implementation validation, before permanent activation:

- Python manifest/packaging/activation tooling: 18 tests passed.
- Local Storage emulator, including existing TTS/private rules: 4 tests passed.
- Final delivery/cache/transport tests: 51 passed.
- Final downloads/image UI tests: 13 passed; construction/world/turntable/reward
  regression tests: 32 passed.
- Whole-repository analyzer passed. Final changed runtime and UI analyzers
  also passed after review fixes.
- Final JavaScript web release build passed in 162.6 seconds using
  `--no-wasm-dry-run`. An earlier release build also passed the Wasm dry-run;
  that earlier Wasm check preceded the final UI/cache-probe fixes. Browser
  runtime tests were not completed because the Chrome runner stalled before
  executing cases.
- The full Flutter run finished with 7,384 passed, 44 skipped, and one
  typography icon-budget failure. Removing the new decorative button icons
  resolved that failure in a focused rerun; the full suite was not repeated.
- Independent final review passed after both original navigation-completion
  and removal-failure reproductions passed on the corrected implementation.
- Final typography/localization/screen-inventory guards: 25 passed. Final
  EN/DE narrow-phone and tablet captures: 3 passed and visually inspected.

Review logs, original-byte inventory, candidate bundle comparison, and
EN/DE phone/tablet captures are retained locally under
`.superpowers/sdd/2026-09-16-hybrid-hanok-assets/`.

## Future publication and activation

The initial publication and activation were explicitly approved and completed.
For a future publication, use the reviewed branch/worktree and authorized
project credentials within the approved scope.

1. Run `check`, `stage`, the Storage emulator tests, and app checks. When
   preparing a new full-bundle baseline, also review `report` and the resulting
   manifest exclusion set and pubspec fingerprints before activation.
2. Publish only the objects listed in `staging/metadata.json`, retaining exact
   bytes, content type, and `canonical=true`. Each object's destination is
   `gs://ko-lernen-app.firebasestorage.app/<storagePath>`. A suitable individual
   command is `gcloud storage cp --if-generation-match=0 --custom-metadata=canonical=true
   --content-type=image/png SOURCE DESTINATION` (use `image/webp` for WebP).
   The [Google Cloud CLI reference](https://docs.cloud.google.com/sdk/gcloud/reference/storage/cp) documents these metadata and generation-precondition flags. Generation zero prevents overwriting an existing immutable object. Verify
   an already-existing object instead of overwriting it or treating the error
   as success. Do not recursively upload source or staging directories.
3. Read the currently deployed Storage rules before preparing any deployment.
   The repository's root `storage.rules` contains an unrelated canonical-only
   TTS migration that was not live on 2026-09-16. Do not deploy the entire file
   merely to publish artwork. This publication added only the reviewed
   `learning-art/v1` canonical-image get rule to the live source, preserved
   every existing TTS clause, tested that exact overlay in the emulator, and
   deployed with a dedicated Storage-only config. A fresh ruleset fingerprint
   guard preceded deployment, and the live readback matched the overlay.
   The resulting ruleset is `d6ba3c5e-b37f-418e-8b1f-75fb3e33085f`.
   Storage App Check was already `UNENFORCED`; its configuration and etag were
   unchanged. Preserve the live App Check mode; never relax it to pass checks.
4. Run `verify-remote`, providing `--app-check-token-env VARIABLE_NAME` when
   enforcement requires a current token. Verify every object's bytes afresh.
   Public reads are for approved artwork only; client writes/listing stay denied.
5. Run `activate` with the reviewed input pubspec fingerprint. It also verifies
   that the canonical shipped manifest matches and remains in the candidate
   bundle; concurrent source/manifest/pubspec changes refuse activation.
6. Build the actual Android/iOS release from the activated candidate. Validate
   first Wi-Fi fetch, explicit cellular fetch, offline reopen, and removal on
   devices. Record Play/App Store per-device download/install sizes separately.
   Main integration, app upload, and store rollout remain separate steps.

Removing bundled files reduces the initial package. Downloading every pack
again uses additional device storage; the downloads page controls that stored
data. Web downloads are held in memory for the session and are not advertised
as persistent offline packs.
