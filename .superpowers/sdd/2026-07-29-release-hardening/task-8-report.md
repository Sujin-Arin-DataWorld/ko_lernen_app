# Task 8 Report: Managed Media Lifecycle and Picker Recovery

## Outcome

- Book thumbnails and custom-word photos now live below one app-owned managed
  media root. Persisted models contain typed opaque references (`book:*` or
  `word:*`), never absolute paths or `file://` URIs.
- Pending workflow leases are separate from committed files. Capture, crop,
  OCR, preview, result, custom-word edit, picker recovery, cancel, retake,
  back, reselect, remove-photo, and failed strict writes have explicit
  ownership and cleanup boundaries.
- Promotion copies pending media before the strict model write. A failed write
  rolls back only the new committed copy and preserves or releases the pending
  lease according to the workflow owner. Once the strict write succeeds,
  final pending cleanup is best-effort and cannot turn a committed save into a
  duplicate-producing retry.
- Committed-file deletion is reference-aware across bookshelf thumbnails,
  bookshelf words, and every custom-pack word. Any malformed collection,
  nested entry, reference, or kind mismatch disables committed-file GC.
- Android picker/crop activity loss is marked before launch and awaited once
  through injectable gateways. Because both native recovery APIs destructively
  clear their caches, recovery is never abandoned through a non-canceling Dart
  timeout. SHA-256 workflow/attempt journals are copied through contained
  `.part` files and atomically renamed, so a failed strict preference write
  reconnects the exact pending lease on the next process launch. iOS skips
  Android native markers but still persists picked ownership before crop/editor
  handoff. Recovered word drafts remain keyed by the stable editor identity,
  capped at eight, and pruned at the same two-day TTL as pending files.
- Local and portable serialization are separate. Firestore, shared packs, and
  cloud backup/restore strip or ignore local media references while retaining
  the underlying page and word data.
- Explicit account cleanup removes the complete managed root and both legacy
  media roots with independent failure aggregation. Ordinary reset remains
  best-effort.

## TDD Evidence

### RED

- The first focused tests failed to compile because managed references,
  pending leases, strict promotion workflows, reference snapshots, and picker
  recovery coordination did not exist.
- Subsequent RED cases reproduced traversal and absolute-path acceptance,
  symlink aliases, external-source deletion risk, malformed-snapshot GC,
  persistence rollback leaks, preview/result ownership transfer, double taps,
  post-persist finalize errors, strict marker-clear failures, and late picker
  completion.
- Review-driven RED cases covered root/kind/pending/legacy aliases, wrong-kind
  references, stale iOS container spellings, migration partial failure,
  strict second-write rollback, keyed recovery overwrite/eviction/expiry,
  homograph identity, shifted indexes, missing targets, and account-cleanup
  aggregation.
- Android recovery review added stale native-cache draining, crop phase
  separation, trusted-cache validation, deterministic crop and picker
  journals, strict-write restart reconnection, marker-clear idempotency,
  unique attempt IDs, cross-marker transaction guards, and full awaiting of
  destructive native recovery calls.
- The first complete regression run reached 709 tests and exposed three legacy
  compatibility failures: an obsolete absolute-path fixture and two no-op
  delete paths that unnecessarily initialized the path-provider plugin.

### GREEN

- `ManagedMediaRef` and `PendingMediaLease` strictly validate type, basename,
  extension, and separator rules. Resolution/deletion verifies exact expected
  canonical directories and rejects symlink/junction aliases.
- `ManagedMediaStore` stages by copy, promotes by copy, cleans partial
  destinations, finalizes only after persistence, reconciles expired pending
  files, and deletes unreferenced commits only from a complete snapshot.
- Trusted migration accepts only current app-owned legacy directories, stale
  iOS paths mapped back to a validated current basename, or current app cache
  for recoverable book images. Migration-owned leases and commits are cleaned
  on failure, and original legacy sources survive.
- `BookPreviewMediaOwner` is an explicit owned/transferred/released state
  machine. Transfer is exactly once, release is idempotent, failed navigation
  can reclaim, and released ownership cannot be resurrected.
- Custom-word updates compare the complete original local word snapshot under
  the global mutation lock before promotion. Missing, shifted, or changed
  targets discard only the incoming pending lease and surface a handled
  conflict.
- Recovered word records use strict serialized read-modify-write, timestamps,
  a two-day TTL, an eight-record cap, and post-write displaced-lease cleanup.
  Existing-word workflow IDs hash the full canonical local word; each pack has
  one explicit resumable `new` draft.
- UI reads fail closed on malformed nested data, while mutation reads remain
  strict and preserve corrupt raw preferences instead of overwriting them.

## Main Files

- `lib/services/book_image_service.dart`: managed store, opaque references,
  migration, reference snapshots, reconciliation, and initialization.
- `lib/services/media_mutation_lock.dart`: process-wide serialization for
  media/model mutations.
- `lib/services/media_workflow.dart`: book and word promotion workflows.
- `lib/services/picker_recovery_service.dart`: fully awaited exactly-once
  Android lost-data coordination plus deterministic book/word picker journals.
- `lib/services/crop_recovery_service.dart`: crop launch ordering, durable
  accepted-result recording, phase-aware startup recovery, and deterministic
  crop journals.
- `lib/services/storage_service.dart`: checked preference writes, atomic picker
  marker/claims, and keyed recovered-word records.
- `lib/services/bookshelf_service.dart` and
  `lib/services/custom_pack_service.dart`: strict transactional persistence,
  expected-target checks, and reference-aware GC.
- Book capture/preview/result and custom-pack edit/play/quiz screens: lifecycle
  ownership, retry/error handling, managed-image display, and cleanup.
- Model/cloud/shared-pack files: local versus portable serialization.

## Focused Regression Coverage

- Path/ref rejection, root/pending/kind/file/legacy symlink aliases, outside
  sentinels, stage/discard, promotion/rollback, TTL, orphan reconciliation,
  malformed and wrong-kind snapshots, shared references, and trusted migration.
- Book persistence retry, post-persist finalize semantics, preview ownership,
  idempotent release, double transfer, strict recovered-book claim, and
  migration rollback.
- Word cancel/dismiss/reselect/remove, failed writes, expected-target conflicts,
  full-field preservation, picker clear failure, workflow hashing, keyed
  recovery isolation, replacement, ninth-record eviction, and expiry.
- Android picker/crop destructive-cache awaiting, stale-cache pre-drain,
  trusted-path/symlink rejection, strict-write two-launch reconnection,
  marker-clear retry without duplication, distinct-attempt byte isolation,
  picked-versus-cropped resume routing, native-error journal fallback, and
  non-Android marker exclusion with durable local ownership.
- Local/portable/Firestore/cloud serialization and hostile remote path
  stripping, plus tolerant UI reads and strict preference failures.

## Final Verification

- `flutter analyze`
  - No issues found.
- Focused Task 8 suite:
  - `flutter test test/book_media_route_ownership_test.dart
    test/managed_media_store_test.dart test/media_serialization_test.dart
    test/media_lifecycle_test.dart test/picker_lost_data_recovery_test.dart
    test/crop_recovery_test.dart --reporter expanded`
  - 75 tests passed.
- Compatibility precheck:
  - `flutter test test/book_page_test.dart --reporter expanded`
  - 8 tests passed.
- Complete regression suite:
  - `flutter test --reporter compact`
  - 736 tests passed.
- `git diff --check`
  - exit 0; Git reported only expected Windows line-ending conversion warnings.

## Safety and External Boundaries

- No local image is uploaded. Portable payloads deliberately omit local
  photos, so a cross-device restore retains words/pages with image fallback.
- No deployment, push, merge, or remote-service mutation was performed.
- Live Android process-death recovery, camera/gallery permissions, cropper/OCR
  handoff, device filesystem behavior, and account deletion should still be
  exercised on staging devices before release.
- Stale pending files and displaced recovery drafts are reclaimed
  asynchronously; a process crash after a strict record write but before the
  best-effort discard may retain a file until the two-day reconciliation pass.
- Filesystem and preference writes are not one atomic transaction. The design
  therefore uses contained copy-before-write, atomic journal rename, strict
  durable records, marker/journal retry, reference validation, idempotent
  cleanup, rollback before persistence, and startup reconciliation.

## Review-Fix Addendum — 2026-07-29

### Fixed Review Findings

- Strict SharedPreferences writes and removals now model the legacy cache
  behavior explicitly. A `false` result or thrown platform future triggers
  `reload()` and a durable-state comparison:
  - the requested state is treated as a committed success;
  - the exact prior state is restored in cache and reported as a confirmed
    `PreferenceWriteException`;
  - a third state, wrong value type, or failed reload raises the distinct
    `PreferenceOutcomeUnknownException`.
- Keys with an unknown outcome cannot be mutated again until a successful
  refresh or process restart. Media callers distinguish the typed unknown
  result and preserve every possibly referenced old, promoted, and pending
  file. Claims return ownership only after removal is confirmed.
- `CustomPackService.deleteWord` now requires the complete original local word
  snapshot and compares it under `MediaMutationLock`. Missing, shifted, or
  changed targets are conflicts. The edit screen serializes delete prompts,
  and all post-commit custom-pack media GC is best effort so cleanup failure
  cannot invite a destructive retry of a committed mutation.
- Startup migration carries a reference-snapshot completeness flag. Any
  malformed, wrong-kind, missing, or untrusted non-empty reference that is
  sanitized disables committed-file GC for that startup; valid managed and
  trusted legacy migrations remain complete.
- Recovered-book OCR now compare-claims and releases its durable record and
  pending lease for no-Korean, engine, and timeout results. Confirmed claim
  failures and unknown outcomes preserve ownership safely for a later startup.

### TDD Evidence

- The focused RED run failed for the expected missing typed unknown-outcome
  exception, expected-original delete contract, and recovered OCR ownership
  helper before production changes were made.
- Production-shaped preference doubles mutate cache before their futures
  return and maintain a separate durable map. They cover false and thrown
  effective commits, false and thrown confirmed rejection with cache restore,
  third-state/reload-failure unknown outcomes, refresh-before-retry, and
  confirmed versus unconfirmed record claims.
- Added regression coverage for unknown media-write preservation, shifted and
  concurrent word deletion, post-commit GC failure plus stale retry, corrupt
  startup reference GC suppression, and all resumed OCR terminal failures.

### Fix-Round Verification

- `flutter analyze`
  - exit 0; no issues found.
- Focused Task 8 and compatibility suite:
  - `flutter test test/book_media_route_ownership_test.dart
    test/managed_media_store_test.dart test/media_serialization_test.dart
    test/media_lifecycle_test.dart test/picker_lost_data_recovery_test.dart
    test/crop_recovery_test.dart test/book_page_test.dart
    test/account_cleanup_test.dart --reporter expanded`
  - 100 tests passed.
- Complete regression suite:
  - `flutter test --reporter compact`
  - 748 tests passed.
- `git diff --check`
  - exit 0; only expected Windows LF-to-CRLF conversion notices were printed
    while displaying diffs.
- Changed-file allowlist and secret-pattern scan:
  - passed before this report-only addendum; no unrelated production files or
    credential-like additions were found.

### Boundaries

- No push, merge, deployment, remote mutation, or device-only claim was made.
- The Task 8 plan and progress-ledger completion state were not edited.
