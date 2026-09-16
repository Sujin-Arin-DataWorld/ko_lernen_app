# Hanok artwork delivery tooling

The repository stays fully bundled by default. `pubspec.yaml` is unchanged, so
offline builds continue to contain every current image. The tool prepares a
reviewable hybrid candidate and immutable upload objects; it does not upload,
deploy Storage rules, release an app, or activate the candidate unless an
operator explicitly runs the gated `activate` subcommand.

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

Run commands from the repository root:

```powershell
python tool/hanok_asset_delivery.py --root . generate
python tool/hanok_asset_delivery.py --root . check
python tool/hanok_asset_delivery.py --root . candidate
python tool/hanok_asset_delivery.py --root . report
python tool/hanok_asset_delivery.py --root . stage
python -m unittest tool.test_hanok_asset_delivery
```

`report` writes `build/hanok-delivery/candidate-pubspec.yaml` and
`asset-report.json`. `stage` writes one verified copy per immutable object under
`build/hanok-delivery/staging/objects/`, plus `metadata.json` and publishing
instructions. These ignored files are review artifacts, not a deployment.

After separate publishing approval and an external upload using the staged
metadata, verify the live bytes:

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
exact reviewed pubspec fingerprint. For this snapshot the input fingerprint is
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

## 2026-09-16 local size report

The checked-in manifest has 13 packs and 202 source assets. No identical
content is duplicated in this snapshot, so it also has 202 immutable objects.

| Measurement | Fully bundled | Hybrid candidate | Difference |
| --- | ---: | ---: | ---: |
| `flutter.assets` files | 1,013 | 811 | -202 |
| `flutter.assets` raw bytes | 481,074,753 | 256,595,064 | -224,479,689 |
| Assets plus six registered font files | 1,019 | 817 | -202 |
| Assets plus fonts raw bytes | 487,701,545 | 263,221,856 | -224,479,689 |

The retained Sarangchae, Hyeopmun starter, and shared lesson set is 24 files /
40,989,315 bytes. The candidate exclusion is exactly the manifest path set.
Six unreferenced turnaround PNGs and one extensionless turnaround file remain
explicitly bundled; they are listed in `asset-report.json` and are not staged
for publishing.

The fully bundled total includes the newly generated 81,331-byte manifest. The
pre-task asset-plus-font baseline was therefore 487,620,214 bytes.

Both configurations were also built locally with `flutter build bundle
--release --no-pub`. Their registered project asset/font files match the raw
totals above: **487,701,545 to 263,221,856 bytes, a 46.0% reduction**. This
includes `docs/data/cultural_glossary.json`, which is bundled outside the
`assets/` directory. URI-encoded Hangul output names were reconciled with
their source names.

The complete Flutter asset directories, including generated manifests and
compiled Dart data, measure **489,894,848 to 265,379,467 bytes**. The candidate
removes exactly the 202 manifest paths. Every retained registered file has
the same hash in both builds, and retained PNG/WebP/MP4 files match their
source bytes. The 888 source image/video files (610,125,746 bytes, including
28 MP4 files) remain byte-identical to the initial snapshot.

The temporary candidate build restored `pubspec.yaml` to its exact input
SHA-256 shown above. These are local Flutter asset-directory measurements,
not AAB/IPA sizes, store download sizes, installed sizes, or proof of live
delivery. Android/iOS release and per-device measurements remain release
gates.

## Local validation

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

## Publishing and activation after release approval

The following steps change the live Firebase project and must be separately
approved. Run them only from the reviewed branch/worktree with a cleanly
identified release candidate and authorized project credentials.

1. Re-run `check`, `report`, `stage`, the Storage emulator tests, and app checks.
   Review the current 202-object list and pubspec fingerprints.
2. Publish only the objects listed in `staging/metadata.json`, retaining exact
   bytes, content type, and `canonical=true`. Each object's destination is
   `gs://ko-lernen-app.firebasestorage.app/<storagePath>`. A suitable individual
   command is `gcloud storage cp --if-generation-match=0 --custom-metadata=canonical=true
   --content-type=image/png SOURCE DESTINATION` (use `image/webp` for WebP).
   The [Google Cloud CLI reference](https://docs.cloud.google.com/sdk/gcloud/reference/storage/cp) documents these metadata and generation-precondition flags. Generation zero prevents overwriting an existing immutable object. Verify
   an already-existing object instead of overwriting it or treating the error
   as success. Do not recursively upload source or staging directories.
3. Deploy the reviewed get-only artwork rule with
   `firebase deploy --only storage --project ko-lernen-app`. Keep existing App
   Check enforcement enabled.
4. Run `verify-remote`, providing `--app-check-token-env VARIABLE_NAME` when
   enforcement requires a current token. Verify every object's bytes afresh.
   Public reads are for approved artwork only; client writes/listing stay denied.
5. Run `activate` with the reviewed input pubspec fingerprint. It also verifies
   that the canonical shipped manifest matches and remains in the candidate
   bundle; concurrent source/manifest/pubspec changes refuse activation.
6. Build the actual Android/iOS release from the activated candidate. Validate
   first Wi-Fi fetch, explicit cellular fetch, offline reopen, and removal on
   devices. Record Play/App Store per-device download/install sizes separately.
   Commit, integration, upload, and store rollout are separate authorized steps.

Removing bundled files reduces the initial package. Downloading every pack
again uses additional device storage; the downloads page controls that stored
data. Web downloads are held in memory for the session and are not advertised
as persistent offline packs.
