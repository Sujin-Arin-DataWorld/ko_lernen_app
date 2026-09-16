# Hybrid Hanok artwork delivery

## Approved intent

Jin approved the recommended hybrid approach on 2026-09-16: keep basic screens and first learning content in the app, and download large Hanok artwork by building. Preserve the exact approved image/video bytes and existing visual composition. This implements mobile download/install size reduction, not developer disk cleanup.

## Scope and first-install experience

- Keep all existing non-Hanok assets, every character video, the full sixteen-stage Sarangchae sequence, Hyeopmun's six-stage first construction lesson, and shared lesson illustrations bundled.
- Make the other eight construction series, referenced turnaround frames, and the V3 world artwork available in immutable download packs. Construction and turnaround files for the same building share a pack where possible. World map composition is a separate pack. Retain the original source files at their canonical repository paths.
- Keep curriculum/catalog JSON local. Downloads never award XP, change completed stages, unlock buildings, or change learning evidence.
- Wi-Fi/ethernet can automatically prepare the selected building. Cellular or unknown connectivity requires an explicit download action. An explicit action permits only that requested pack. Existing downloaded files work without a network connection or Firebase sign-in. Do not prefetch the entire estate at startup.
- Downloads are byte-for-byte copies. No transcoding, resizing, palette change, PNG/WebP conversion, or video edits.

## Manifest and immutable storage

`assets/data/hanok_download_manifest.json` has schemaVersion 1, storageBucket `ko-lernen-app.firebasestorage.app`, and a packs array. Each pack has a stable kebab-case id, title translations (`ko`, `en`, `de`), and assets. Each asset has `asset` (canonical relative source path), `sha256` (64 lowercase hex), `bytes` (positive integer), `contentType` (`image/png` or `image/webp`), and `storagePath` (`learning-art/v1/<sha256>.<png|webp>`). Each source path belongs to exactly one pack. Repeated content hashes may share storage objects. Only approved, actually referenced images enter the manifest, derived from the existing catalogs. Directory strays are not published.

Runtime parsing rejects duplicate paths/ids, traversal, unexpected buckets/prefixes, invalid hashes/lengths/extensions, and empty packs. JSON is shipped with the app and is the trust root; do not fetch an executable or mutable remote catalog.

The full-bundle rollout state must not download duplicate copies. Detect bundled manifest entries for pack status/download operations; expose `isBundled` and `storedBytes` as well as availability. Settings labels bundled packs as included in the app and offers removal only for downloaded data. Bundled availability is not counted against the disk-cache cap.

The existing Firebase Storage bucket serves these approved assets through Firebase's HTTPS media endpoint. Client access is public get-only for the dedicated prefix, constrained to validated filename and administrator-written `canonical=true` metadata. Client listing/writing is denied. Existing personal and TTS rules retain their behavior. Publishing and rules deployment require a separate explicit release approval; this change prepares tools and local rules only.

## Loader and cache

New focused services own manifest validation, transport, and platform storage. The public service contract is `HanokAssetDelivery.shared`, `load(String assetPath, {AssetBundle? bundle, bool allowMobileData = false}) -> Future<Uint8List>`, `downloadPack(String packId, {bool allowMobileData = false}) -> Future<void>`, `statuses() -> Future<List<HanokPackStatus>>`, `removePack(String packId) -> Future<void>`, and ChangeNotifier updates for progress/state. The manifest models expose pack id/title/assets and byte totals; statuses expose pack, availableBytes, isComplete, isDownloading, and optional failure.

Resolution order: existing bundled file, verified local copy, permitted download. Serving a bundled file must not initialize Firebase or a network request. In a hybrid build, resolve the selected image first; prepare the remainder of that same building asynchronously only when network policy allows. Catch background errors and retain successfully verified files. Download failure never substitutes a different building/stage image.

Add `bool prefetchPack = true` to load/widget options. Small map sprites and passive reward comparisons pass false: viewing many buildings at once must not trigger every building's full pack. The selected construction viewer and downloads page may prepare a full pack. Low-level image load still resolves only the requested file when prefetch is false.

HTTP fetches use HTTPS, enforce exact declared byte length and SHA-256 before exposure, cap transfers to the declared size, reject redirects/unexpected origins, and use bounded timeouts. Coalesce simultaneous requests for the same immutable object and avoid unbounded concurrent downloads. The service must be injectable for deterministic network/storage/connectivity tests.

The app already initializes Firebase App Check. A direct HTTP artwork request must lazily obtain the current App Check token when Firebase is configured and send `X-Firebase-AppCheck`, with a bounded token request and no token logging; bundle/cache hits never request a token. A missing Firebase configuration can attempt public access but must report server rejection honestly. Do not weaken App Check enforcement to support media delivery. CLI remote verification must support an explicitly named environment variable containing a short-lived App Check token for projects with Storage enforcement, without persisting or printing it.

Android/iOS store bytes under Application Support in a dedicated `hanok_art/v1` directory, not an OS-evictable temp directory. Write a unique temporary file, verify, then atomically promote it. A failed/truncated transfer never becomes an available asset. Downloaded packs remain offline until explicitly removed; do not promise persistence after uninstall/OS data reset. Keep only manifest-owned files and a 300 MiB storage cap; on insufficient space fail clearly without deleting offline packs. Removing a pack during an in-flight download must not recreate the removed files on late completion, and hashes shared with another completed pack must remain usable. Browser builds use a conditional in-memory store and do not promise persistent offline downloads.

## UI

Use a reusable `HanokAssetImage` with the existing Image.asset-style sizing, fit, semantics, cacheWidth/cacheHeight, and errorBuilder options. Preserve fast bundled rendering and all composition/crop coordinates. Wire it into the construction viewer, B2 reward receipts, V3 world imagery, and `HanokTurntableFrameImage`; Sarangchae stays bundled. Loading, explicit download, failure/retry, and verified display are distinct states. No stale image may remain when switching building/stage.

Provide a small Hanok downloads page reachable from Settings: pack name, size/download state, download/retry action, and remove downloaded data. Warn through normal UI text that removal requires downloading again; it must not reset learning progress. All user-visible strings use existing DE/EN ARB localization. Progress UI must not overflow at 320dp/large text or require an endless spinner to settle in widget tests.

## Safe packaging and rollout

Normal source checkout and pubspec remain fully bundled until remote availability is proven; otherwise existing release pipelines would ship broken image paths. The tooling generates a separate reviewable hybrid pubspec and a byte report without changing originals. An explicit activation command verifies every remote object's exact bytes/hash and manifest identity before atomically updating pubspec to remove only manifest entries from directory registrations (expand retained siblings explicitly). It preserves non-Hanok assets/fonts and refuses to run on main or over unexpected pubspec content. A missing object, changed source hash, or failed verification leaves pubspec unchanged. A fully bundled rollback is recorded before activation. Never automatically upload, deploy, commit, push, merge, or release.

## Acceptance

- Reproducible manifest; local bytes/hash match every entry; starter content remains in candidate hybrid bundle; every remote reference is covered.
- Cold bundled/offline startup; first Wi-Fi download; explicit cellular download; cached offline reopen; concurrent duplicate loads; corrupt cache/refetch; interrupted download; retry; remove-versus-in-flight; cache capacity and shared-object removal tests.
- Widget checks for loading/explicit download/error/retry and stage changes, plus existing construction/progression tests.
- Packaging tests prove exact asset set difference, full remote validation gate, and source-image/video hash invariance.
- Static analysis and web compilation; produce a local candidate bundle size report. Store device download/install sizes and live remote delivery remain release validation, never inferred from raw asset bytes.
