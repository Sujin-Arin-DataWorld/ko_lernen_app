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

The final stale-local follow-up used the exact inverse ordering that the shared
lock test did not cover: the remote write was paused, a real media edit then
completed, and only afterward did reconciliation attempt its stale local
commit. Before the fix, reconciliation incorrectly returned `completed` and
could silently overwrite the newer local custom-pack state. After the fix, the
local generation CAS rejects that stale commit, the coordinator re-reads and
re-merges, and the divergent same-ID pack produces a typed conflict while both
the edited text and promoted `imagePath` remain intact.

The final data-safety review added four exact-order RED cases:

- switching UID/session while the local writer was delayed still persisted the
  old session's SRS payload before returning `stale`;
- an SRS review completed during the paused remote write, but reconciliation
  returned `completed` and restored the older review count;
- a pack-progress update completed during the paused remote write, but no
  local-generation retry occurred and the newer learned-word count was lost;
  and
- deleting a local custom pack during the paused remote write caused the retry
  to treat the now-remote-only pack as new data, return `completed`, and
  resurrect it locally.

All four failures were observed against the preceding production code before
the composite generation, effect-point session fence, and deletion-aware retry
changes.

The final safety re-review then added six exact RED cases:

- deleting a local custom pack during the first paused attempt was blocked, but
  reconstructing the coordinator from the same journal completed and
  resurrected the deleted pack because the deletion base set was only in
  memory;
- the v1 journal did not persist the reconciliation local custom-pack base ID
  set and did not reject oversized or duplicate sets;
- a stable manifest whose `pack_ids` named a missing query document was
  accepted;
- a stable manifest with an unexpected query document was accepted;
- a reconciliation CAS could replace a complete manifest with an incomplete
  target set; and
- when the merged snapshot initially equaled remote, a remote mutation after
  that read but before local persistence caused zero remote validations and
  stale local data to be written.

Each failure was observed against the prior production implementation before
the durable journal guard, exact manifest membership validation, and
always-CAS-before-local-effect changes.

The subsequent concrete-adapter re-review added the exact remaining composite
race. The root CAS committed, a ready writer then advanced the root while the
pack CAS was in flight, the pack CAS succeeded, and the adapter returned
success without revalidating root. Before the fix, the coordinator read remote
only once, returned `completed`, and persisted the older SRS review count
locally. The focused RED expected a second remote read but observed one.

## GREEN and verification

Final focused Task 8 command:

```text
flutter test test/services/account/account_reconciliation_test.dart test/services/account/account_transition_journal_test.dart test/services/cloud_sync_service_test.dart test/services/firestore_progress_service_test.dart test/services/pack_progress_service_test.dart --reporter compact
```

Result: 62/62 passed.

Relevant service and legacy commands:

```text
flutter test test/services --reporter compact
flutter test test/custom_pack_test.dart test/media_lifecycle_test.dart test/cloud_sync_test.dart test/services/account/concrete_cloud_writer_race_test.dart test/services/account/cloud_writer_fence_test.dart --reporter compact
```

Results: 145/145 service tests and 91/91 related legacy/race tests passed.

Full Flutter command:

```text
flutter test --reporter compact
```

Result: 893/893 passed, zero failures, exit 0 on the final concrete-adapter
re-review gate (about 51 seconds of Flutter test-clock time).

Static and hygiene commands:

```text
flutter analyze
dart format --set-exit-if-changed <4 concrete-adapter follow-up Dart files>
git diff --check
```

Results:

- `flutter analyze`: no issues found.
- Dart format: 4 follow-up files checked, 0 changed on the final pass.
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
  When the manifest exists, typed query reads require its exact `pack_ids` set
  to equal the queried document IDs. Reconciliation CAS carries the exact
  expected set into the transaction, revalidates it before writes, and rejects
  duplicate or incomplete targets so a complete manifest cannot be replaced
  by an incomplete set. The absent-manifest path remains deliberately
  bootstrap-compatible with legacy pack documents.
- The operation ID is the idempotency identity. Root idempotency also binds a
  canonical payload hash; pack idempotency verifies the stored progress
  payload before accepting a repeated operation.
- The v1 transition journal remains backward-compatible. Its strict serializer
  now optionally emits only bounded operation ID, checkpoint, nonnegative
  remote revision metadata, and a sorted reconciliation local custom-pack base
  ID set. That set is limited to 512 unique nonempty IDs, 256 UTF-8 bytes per
  ID, and 64 KiB total encoded size. Unknown credential/proof/token fields are
  ignored and never re-emitted.
- A concrete SharedPreferences journal store persists checkpoints. Concrete
  local reconciliation uses strict preference writes for SRS, custom packs,
  and all pack progress.
- Portable custom-pack reconciliation preserves matching local managed-media
  references instead of replacing them with remote portable data. Its complete
  read/compare/write critical section now uses the same `MediaMutationLock` as
  normal save/delete/rename/media mutations.
- The local snapshot carries opaque SHA-256 generations for SRS, custom packs,
  and pack progress. The first local effect performs a composite preflight
  inside `MediaMutationLock`; SRS and pack progress are rechecked again at
  their own effect points. A mismatch re-enters the coordinator read/merge
  loop, so a completed SRS review, media mutation, or pack-progress update is
  merged or surfaced as a typed conflict instead of being overwritten.
- The exact reconciling UID/epoch/mode is passed into the concrete local writer.
  Every ordinary restore effect and every strict reconciliation-owned write
  revalidates it immediately before mutation. A session change while the
  writer is delayed returns typed `stale` without persisting the old merge.
  No remote/network await occurs while `MediaMutationLock` is held.
- Before merge or any remote write, reconciliation durably journals the initial
  local custom-pack ID base set and unions newly observed local IDs into it.
  If a previously observed local ID disappears, reconciliation returns a
  sorted `customPackId` conflict before union merge. The guard therefore
  survives coordinator reconstruction or process restart and a remote copy
  created by an earlier attempt cannot resurrect the local deletion.
- Every path that needs a local effect first performs the existing root and
  pack remote CAS linearization, even when the initial merged snapshot equals
  remote. A conflict re-reads and re-merges before local persistence, so a
  remote mutation in that window cannot cause a stale local write. No
  remote/network await was added under `MediaMutationLock`.
- After pack CAS commits, the concrete adapter reads root again and requires
  the exact committed root revision, reconciliation operation ID, and
  canonical payload SHA-256. A ready root writer advancing between root and
  pack CAS therefore produces a typed revision conflict; the coordinator
  re-reads and re-merges the newer root before any local effect. The exact
  interleaving asserts two remote reads, two root/pack validations, and one
  final local write containing the newer SRS history.
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
- Legacy app clients that write pack documents without advancing the pack
  manifest generation can still bypass the complete-membership guard. This is
  an external rollout gate requiring client-version enforcement or a
  server/rules migration; Task 8 cannot make an unmodified legacy writer
  participate in the generation protocol.
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
