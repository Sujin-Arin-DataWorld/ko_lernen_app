# Task 8 report: typed remote reads and deterministic reconciliation

## Status

DONE

## Files changed

### Created

- `lib/services/account/cloud_read_result.dart`
- `lib/services/account/account_reconciliation.dart`
- `lib/services/cloud_sync_service.dart`
- `test/services/account/account_reconciliation_test.dart`
- `test/services/cloud_sync_service_test.dart`
- `test/services/firestore_progress_service_test.dart`
- `test/services/pack_progress_service_test.dart`

### Modified

- `lib/services/account/account_transition_journal.dart`
- `lib/services/cloud_sync.dart`
- `lib/services/firestore_progress_service.dart`
- `lib/services/pack_progress_service.dart`
- `lib/services/custom_pack_service.dart`
- `lib/services/storage_service.dart`
- `test/services/account/account_transition_journal_test.dart`

No plan, ledger, Functions, rules, UI, public documentation, bookshelf
generation, deployment, push, or merge file was modified.

## RED evidence

The initial focused command was:

```text
flutter test test/services/account/account_reconciliation_test.dart test/services/cloud_sync_service_test.dart test/services/firestore_progress_service_test.dart test/services/pack_progress_service_test.dart test/services/account/account_transition_journal_test.dart
```

It exited 1 after 16.9 seconds. The compiler could not find
`cloud_read_result.dart`, `account_reconciliation.dart`, or
`cloud_sync_service.dart`, and reported all requested typed read, merge, CAS,
checkpoint, and journal metadata symbols as missing.

Subsequent behavior-first self-review RED runs proved:

- a real Firestore `Timestamp` was incorrectly classified as invalid;
- an `inProgress` pack with clearing accuracy was accepted;
- a fractional attempt counter was silently truncated;
- no typed single-pack read distinguished unavailable from absent;
- no concrete SharedPreferences reconciliation journal or local store existed;
- malformed local custom-pack JSON collapsed to an empty snapshot; and
- writing portable reconciled custom packs could not preserve matching local
  managed-media references.

Each regression failed for the named behavior before its production fix.

Independent-review follow-up RED runs additionally proved:

- a concurrently created pack could bypass the per-document pack CAS because
  the reconciliation transaction had no complete collection generation;
- a pack query crossing two membership generations was accepted;
- portable reconciliation could race a regular custom-pack save and erase its
  newly committed `imagePath`;
- semantically equal `1`/`1.0`, equal instants with different offsets, and
  mixed-type list values produced argument-order-dependent serialized output;
  and
- the concrete adapter had no per-call seam to reproduce root success followed
  by a pack-generation conflict.

The focused failures were observed before each production change. The new
media test also demonstrates that the normal mutation remains queued until the
reconciliation critical section releases the shared lock.

## GREEN and verification

Final focused Task 8 command:

```text
flutter test test/services/account/account_reconciliation_test.dart test/services/account/account_transition_journal_test.dart test/services/cloud_sync_service_test.dart test/services/firestore_progress_service_test.dart test/services/pack_progress_service_test.dart --reporter compact
```

Result: 49/49 passed.

Relevant service and legacy commands:

```text
flutter test test/services --reporter compact
flutter test test/custom_pack_test.dart test/media_lifecycle_test.dart test/cloud_sync_test.dart test/services/account/concrete_cloud_writer_race_test.dart test/services/account/cloud_writer_fence_test.dart --reporter compact
```

Results: 132/132 service tests and 91/91 related legacy/race tests passed.

Full Flutter command:

```text
flutter test --reporter compact
```

Result: 880/880 passed, zero failures, exit 0 in 51.5 seconds on the
independent-review follow-up gate.

Static and hygiene commands:

```text
flutter analyze
dart format --set-exit-if-changed <5 follow-up Dart files>
git diff --check
```

Results:

- `flutter analyze`: no issues found.
- Dart format: 5 follow-up files checked, 0 changed.
- `git diff --check`: clean; only informational LF-to-CRLF worktree warnings
  were emitted.

## Implementation and self-review

- `CloudReadResult<T>` preserves present, absent, unavailable, invalid, and
  too-large states. Only an explicit missing document/query is absent.
- Root and pack typed readers have bounded byte validation, strict revision and
  field decoding, Firestore `Timestamp` support, and ordinary per-call
  reader/writer injection seams with production defaults.
- Legacy ready-session restore now consumes the typed root reader. Legacy
  public compatibility wrappers remain, while production pack restore uses the
  typed query path and cannot turn a failed query into an upload decision.
- Reconciliation requires the exact current `CloudWriteSession` in
  `reconciling` mode before journal, remote, and local migration writes.
- The deterministic merger unions independent SRS cards and custom-pack IDs,
  but returns typed blocking conflicts for divergent histories under the same
  ID. It never picks or overwrites a conflicting side.
- Pack progress is catalog-bound and validates ID, level, word totals, status,
  accuracy, attempts, and cleared timestamps. Valid counters merge
  monotonically and commutatively.
- CAS conflicts re-read and re-merge. Root and pack writes use Firestore
  transactions when revisions exist, and ordinary ready writes atomically
  increment those revisions so concurrent device activity is visible.
- Pack collection membership has its own manifest generation under
  `users/{uid}/sync_metadata/pack_progress`. Typed reads bracket the pack query
  with the same generation; reconciliation CAS reads that generation, and
  every regular single/batch pack writer updates the affected packs and
  generation in one transaction. A generation conflict re-reads and re-merges,
  including a newly created pack, before another write.
- The manifest generation is the authoritative complete-membership guard.
  Its sorted `pack_ids` list supports operation idempotency and becomes complete
  on reconciliation; it is deliberately not used to reject legacy pack
  documents before that bootstrap.
- The operation ID is the idempotency identity. Root idempotency also binds a
  canonical payload hash; pack idempotency verifies the stored progress
  payload before accepting a repeated operation.
- The v1 transition journal remains backward-compatible. Its strict serializer
  now optionally emits only bounded operation ID, checkpoint, and nonnegative
  remote revision metadata. Unknown credential/proof/token fields are ignored
  and never re-emitted.
- A concrete SharedPreferences journal store persists checkpoints. Concrete
  local reconciliation uses strict preference writes for SRS, custom packs,
  and all pack progress.
- Portable custom-pack reconciliation preserves matching local managed-media
  references instead of replacing them with remote portable data. Its complete
  read/compare/write critical section now uses the same `MediaMutationLock` as
  normal save/delete/rename/media mutations.
- Ordinary field values are canonicalized before merge/hash/write: integral
  doubles become integers, ISO instants become UTC, nested map insertion order
  is stable, and mixed-type list unions use a type-tagged total ordering.
- The concrete root-success/pack-conflict adapter path now has regular per-call
  writer seams and is covered as a typed revision conflict. Local durable
  recovery is also tested across a `Storage` reset and reinitialization.
- Interrupted remote-write response loss retries the same operation, re-reads
  the committed remote snapshot, and completes without a second blind write.
- Bookshelf generation logic and media-generation cleanup remain untouched for
  Task 9.

## Commit

Requested subject:

```text
feat(sync): reconcile remote account data deterministically
```

The resulting commit hash is reported in the Task 8 handoff because a commit
cannot contain its own final hash.

## Concerns and external gates

- No Firebase emulator or live project transaction was run. Firestore SDK
  transactions are covered through the concrete typed/CAS boundaries,
  injected per-call seams, race tests, and static analysis; live contention,
  permissions, offline retries, and transaction replay remain staging gates.
- The new `users/{uid}/sync_metadata/pack_progress` document requires the
  deployed security rules to permit the authenticated owner read and
  transactional write. The checked-in generic owner subcollection rule appears
  to cover it, but rules were explicitly out of Task 8 scope and no emulator
  rules run was performed, so deployed-rules verification remains a release
  integration gate.
- Legacy pack records have only aggregate attempt counts and no stable
  per-attempt IDs. The deterministic idempotent policy therefore uses max
  rather than sum; it cannot reconstruct two independently created attempt
  events. Divergent SRS-card histories and same-ID custom packs block instead
  of accepting such loss.
- Pre-revision legacy documents are read with a null revision. The first
  successful reconciliation establishes revision 1; all updated ready writers
  now increment revisions afterward.
- Task 10 still must obtain the operation ID from its server-owned transition
  journal, build the catalog, enter `reconciling`, and invoke the concrete
  adapter. This task intentionally does not add collision UI or activation
  coordination.
