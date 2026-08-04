# Sarangbang Reward Claim Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the first pending Sarangbang reward box into exactly one owned interior decoration without loss or duplication across an interrupted local write.

**Architecture:** `DecorationRewardService` owns deterministic quest offers, validation, serialized mutation, and journal recovery. `Storage` remains a thin SharedPreferences boundary for the pending-box list and one versioned raw journal. The future UI receives typed offer/result states and never composes ownership plus queue writes itself.

**Tech Stack:** Flutter 3.x / Dart 3.x, `shared_preferences`, `flutter_test`.

## Global Constraints

- Scope is only reward service, storage boundary, tests, and required SSoT documentation; do not edit UI, ARB, assets, CloudSync, or the decoration whitelist.
- Use `kQuestById`, `kDecorCategory`, and a versioned append-only interior reward pool; never use Dart `hashCode` for persisted offer selection.
- Pending boxes remain local `List<String>` FIFO values and are not cloud-synced.
- Write journal before ownership and queue mutation; journal recovery must preserve later appended boxes and fail closed on malformed/conflicting data.
- New UI must call `DecorationRewardService`, never raw `Storage.addOwnedDecor` plus `Storage.consumePendingBox`.
- Use apply_patch for every repository edit. Follow red-green-refactor; every production behavior has a focused test that failed first.
- Do not push. Commit only the files authored in this phase and update `AGENTS.md` in the same or immediate follow-up commit.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `lib/services/storage_service.dart` | Raw pending-list replacement and raw versioned journal read/write/clear boundary. |
| `lib/services/decoration_reward_service.dart` | Candidate pool, typed offer/result APIs, serialized claim, journal codec, and recovery. |
| `test/decoration_reward_service_test.dart` | Focused behavior tests against real SharedPreferences mock storage. |
| `docs/superpowers/specs/2026-08-04-sarangbang-reward-claim-design.md` | Approved persistence and UI integration contract. |
| `AGENTS.md` | Completion log/checklist after verified implementation. |

### Task 1: Deterministic offer domain and storage boundary

**Files:**
- Create: `lib/services/decoration_reward_service.dart`
- Modify: `lib/services/storage_service.dart:830-856`
- Create: `test/decoration_reward_service_test.dart`

**Interfaces:**
- Produces `const List<String> kDecorationRewardPool`.
- Produces `DecorationRewardOfferState { ready, noPendingBox, unknownQuest, noEligibleCandidates, recoveryConflict }`.
- Produces `DecorationRewardOffer` with `state`, nullable `sourceQuestId`, and immutable `candidates`.
- Produces `DecorationRewardService.candidatesForQuest(String questId, {Iterable<String>? owned})`.
- Produces `DecorationRewardService.loadNextOffer()`.
- Produces `Storage.setPendingBoxes(List<String>)`, `Storage.decorationRewardClaimJournalRawJson`, `Storage.setDecorationRewardClaimJournalRawJson(String)`, and `Storage.clearDecorationRewardClaimJournal()`.

- [x] **Step 1: Write the failing offer tests**

Create the test setup with `Storage.resetForTesting()`, mock preferences, and `Storage.init()`. Add the wished-for API assertions:

```dart
expect(
  DecorationRewardService.candidatesForQuest('q_punggyeong'),
  const [
    'decoration_sagunja_guk',
    'decoration_sagunja_juk',
    'decoration_chaekgado',
  ],
);

expect(
  DecorationRewardService.candidatesForQuest(
    'q_punggyeong',
    owned: const ['decoration_sagunja_juk'],
  ),
  const ['decoration_sagunja_guk', 'decoration_chaekgado'],
);
```

Add asynchronous tests asserting that an empty queue returns `noPendingBox`, a queue beginning with `unknown_source` returns `unknownQuest`, and a known queue whose three candidates are owned returns `noEligibleCandidates` without mutating the list.

- [x] **Step 2: Run the offer tests and confirm RED**

Run:

```text
flutter test test/decoration_reward_service_test.dart
```

Expected before implementation: compile failure because `DecorationRewardService`, typed offer state, and the new storage boundary do not exist.

- [x] **Step 3: Implement the smallest offer and storage API**

Add the four narrow `Storage` methods at the existing reward section. In the new service, define the exact append-only pool from the design, calculate the start index with:

```dart
static int _stableStartIndex(String questId) {
  var hash = 0;
  for (final codeUnit in questId.codeUnits) {
    hash = (hash * 31 + codeUnit) % kDecorationRewardPool.length;
  }
  return hash;
}
```

Return the next three circular items after filtering the supplied/current ownership set. Reject source IDs not present in `kQuestById`. `loadNextOffer()` may return `recoveryConflict` while journal recovery is not implemented, but must not mutate any stored value.

- [x] **Step 4: Run the offer tests and confirm GREEN**

Run:

```text
flutter test test/decoration_reward_service_test.dart
```

Expected: deterministic-order, filtering, and no-write state tests pass.

### Task 2: Durable claim and recovery

**Files:**
- Modify: `lib/services/decoration_reward_service.dart`
- Modify: `test/decoration_reward_service_test.dart`

**Interfaces:**
- Produces `DecorationRewardClaimResult { claimed, noPendingBox, unknownQuest, noEligibleCandidates, notOffered, recoveryConflict }`.
- Produces `DecorationRewardRecoveryResult { none, resumed, conflict }`.
- Produces `DecorationRewardService.claimNextBox(String slug)` and `DecorationRewardService.resumePendingClaim()`.

- [x] **Step 1: Write the failing claim and recovery tests**

Add a valid claim test that enqueues `q_punggyeong`, calls:

```dart
final result = await DecorationRewardService.claimNextBox(
  'decoration_sagunja_guk',
);
expect(result, DecorationRewardClaimResult.claimed);
expect(Storage.ownedDecor, const ['decoration_sagunja_guk']);
expect(Storage.pendingBoxes, isEmpty);
expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
```

Add `notOffered` and empty-queue tests asserting all three storage values remain unchanged. Seed the exact v1 raw journal JSON in three separate tests:

```json
{"version":1,"stage":"prepared","sourceQuestId":"q_punggyeong","decorationSlug":"decoration_sagunja_guk","pendingBefore":["q_punggyeong"],"pendingAfter":[]}
```

Test recovery when (a) a `prepared` journal has queue `pendingBefore` and ownership is absent, (b) a `queue_commit_started` journal has queue `pendingAfter` and ownership already exists, and (c) a `prepared` journal has an unrelated queue. Expect `resumed`, `resumed`, and `conflict` respectively. In the conflict case assert journal, queue, and ownership are byte-for-byte/collection unchanged. Add later-appended-box cases before the queue write and after the queue write, asserting only the original first source is removed and every suffix remains.

- [x] **Step 2: Run the claim tests and confirm RED**

Run:

```text
flutter test test/decoration_reward_service_test.dart
```

Expected before implementation: missing claim/recovery APIs or behavior failures; not a fixture parse error.

- [x] **Step 3: Implement journal-first claim and prefix-safe recovery**

Define a private v1 journal codec that accepts only integer version `1`, stage `prepared` or `queue_commit_started`, nonempty source/slug strings, a nonempty `pendingBefore`, `pendingAfter == pendingBefore.skip(1)`, and `sourceQuestId == pendingBefore.first`. Decode failure returns `conflict` without writes.

For a valid claim, recover first, validate the first current box plus selected slug, write the raw `prepared` journal, add the owned decoration, change the journal to `queue_commit_started`, then remove exactly the recorded first queue entry while retaining any suffix appended after the journal snapshot. Finally clear the journal.

Use prefix logic in recovery:

```dart
if (journal.stage == _RewardClaimStage.prepared &&
    !_startsWith(current, journal.pendingBefore)) {
  return DecorationRewardRecoveryResult.conflict;
}
if (_startsWith(current, journal.pendingBefore)) {
  final suffix = current.sublist(journal.pendingBefore.length);
  await Storage.addOwnedDecor(journal.decorationSlug);
  await Storage.setDecorationRewardClaimJournalRawJson(
    journal.withQueueCommitStarted().toRawJson(),
  );
  await Storage.setPendingBoxes([...journal.pendingAfter, ...suffix]);
  await Storage.clearDecorationRewardClaimJournal();
  return DecorationRewardRecoveryResult.resumed;
}
if (_startsWith(current, journal.pendingAfter)) {
  await Storage.addOwnedDecor(journal.decorationSlug);
  await Storage.clearDecorationRewardClaimJournal();
  return DecorationRewardRecoveryResult.resumed;
}
return DecorationRewardRecoveryResult.conflict;
```

Serialize public service mutations with one future chain so rapid double taps cannot interleave two claims.

- [x] **Step 4: Run focused claim tests and confirm GREEN**

Run:

```text
flutter test test/decoration_reward_service_test.dart
```

Expected: all success, no-op, recovery, suffix-preservation, and conflict assertions pass.

### Task 3: Integration-proof verification and handoff record

**Files:**
- Modify: `AGENTS.md`

**Interfaces:**
- UI integration is restricted to `loadNextOffer`, `claimNextBox`, and `resumePendingClaim`.

- [x] **Step 1: Run the focused regression suite**

Run:

```text
flutter test test/decoration_reward_service_test.dart test/quest_tracker_test.dart test/room_placement_service_test.dart test/room_placement_storage_test.dart test/room_layer_test.dart test/sarangbang_picker_test.dart test/decoration_slot_test.dart
```

Expected: all reward, quest-producer, storage, placement, and rendered-slot regressions pass.

- [x] **Step 2: Run static and diff checks**

Run:

```text
dart analyze lib/services/decoration_reward_service.dart lib/services/storage_service.dart
git diff --check
```

Expected: no analyzer issues and no whitespace errors.

- [ ] **Step 3: Update the SSoT log and checklist**

Record the journal ordering, prefix/suffix preservation, focused test count, analyzer result, and commit hash in the current Sarangbang work section of `AGENTS.md`. Mark the service layer complete but leave reward-opening UI/assets pending for Claude.

- [ ] **Step 4: Commit only this phase**

Stage exactly:

```text
AGENTS.md
docs/superpowers/specs/2026-08-04-sarangbang-reward-claim-design.md
docs/superpowers/plans/2026-08-04-sarangbang-reward-claim.md
lib/services/storage_service.dart
lib/services/decoration_reward_service.dart
test/decoration_reward_service_test.dart
```

Create a local commit with a scoped `feat(sarangbang): durable reward claims` message. Do not push and do not stage Claude-owned UI/asset files.

## Self-Review

- Spec coverage: Task 1 covers the deterministic three-candidate rule, ownership filtering, unknown-source fail-closed state, and local storage boundary. Task 2 covers journal-first mutation, every interrupted-write recovery point, later queue append preservation, malformed/conflicting journal failure, and serialized public mutation. Task 3 covers the consumer/producer regression boundary, static checks, SSoT log, and scoped handoff.
- Placeholder scan: no task uses TBD/TODO or generic error-handling language; each behavior names its exact outcome and storage assertion.
- Type consistency: Task 1 defines `DecorationRewardOffer`, `DecorationRewardOfferState`, storage journal APIs, and pure candidates. Task 2 defines `DecorationRewardClaimResult`, `DecorationRewardRecoveryResult`, `claimNextBox`, and `resumePendingClaim`; Task 3 uses those same exact names.
