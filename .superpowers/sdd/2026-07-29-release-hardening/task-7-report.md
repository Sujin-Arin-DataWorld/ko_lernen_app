# Task 7 Report: Gye Ownership, Moderation, and Deletion Lifecycle

## Outcome

- Owners can no longer use the ordinary leave path. The service rejects before
  any write, the screen explains the restriction, and failed member leaves stay
  visible instead of being reported as success.
- Gye create/join is blocked unless the on-device birth-year self-attestation
  passes. Because month/day are deliberately not collected, the conservative
  year-only lower bound now requires a 17-year difference, preventing admission
  before the actual 16th birthday at the cost of up to one year's delay.
- Membership generations, pending departure markers, server-owned ban
  tombstones, exact count/list companion writes, account-deletion tombstones,
  and retryable cleanup functions now define one coherent lifecycle.
- Owner deletion or automatic owner suspension transfers ownership
  deterministically to the earliest active member who is neither banned nor
  deleting their account. With no eligible successor, every surviving
  `users.gyeIds` cache is cleared transactionally before recursive group
  deletion.
- Normal leave and account deletion remove reports involving the departed user,
  anonymize retained feed/sticker/MVP identity, and prevent a rapid rejoin from
  being confused with the prior membership generation.

## TDD Evidence

### RED

- `flutter test test/gye_hardening_test.dart` initially failed to compile
  because owner-leave coordination, explicit owner error handling, account
  tombstone coordination, and membership-generation APIs did not exist.
- `flutter test test/age_gate_test.dart` exposed that unknown/unplausible age
  values were not a service-level denial and later showed that a year
  difference of exactly 16 admitted users who might still be 15.
- `node --test lifecycle.test.js` initially failed with
  `MODULE_NOT_FOUND` because no pure lifecycle module existed.
- Initial Firestore emulator coverage failed the removal-without-member-delete
  attack and role/status mutation cases. Subsequent RED cases reproduced rapid
  rejoin ambiguity, deleting-account successor selection, Gye enumeration,
  suspended-member reads, pack-ID minting, client server-event spoofing,
  arbitrary/duplicate reports, and backdated/future lifecycle timestamps.

### GREEN

- Owner leave is rejected with zero writes; non-owner failures propagate and
  the screen closes only after a successful leave.
- Create/join validates the conservative self-attested age before Auth or
  Firestore work.
- New member generations use random 128-bit IDs. A leave batch writes a pending
  departure marker, deletes the exact generation, decrements the exact count,
  and removes the user's Gye cache atomically. The retryable delete trigger
  anonymizes only the matching generation before completing the marker.
- Account deletion creates its tombstone first. Cloud-backup deletion preserves
  operational membership/token fields, while full account deletion removes the
  user document and lets the retryable Admin trigger own Gye cleanup.
- An abandoned tombstone older than 24 hours is cancelled only when Auth and
  Firestore user records still exist in a transaction. Missing Auth requires a
  second 24-hour observation window. Auth-present/user-missing retains the
  marker for deletion retry.

## Firestore and Moderation Hardening

- `/gye` permits a known-code `get` but denies collection `list`, preventing
  authenticated enumeration of join codes, owner IDs, and names.
- Gye/member/user companion writes enforce a maximum of 10 members, at most
  three memberships per user, exact count changes, immutable roles/statuses,
  active lifecycle state, active membership, and server request timestamps.
- Suspended, banned, or deleting accounts cannot read private roster/feed data,
  write activity, rejoin, leave to erase a ban, receive weekly push
  notifications, or become weekly MVP/owner successor.
- Client feed writes cannot impersonate server-owned `pack_cleared` or
  `goal_achieved` events. Per-type payload schemas, canonical member
  nicknames, sticker/cheer code ranges, and eligible cheer targets are checked.
- Reports use deterministic IDs (`targetUid_reporterUid`), so one current
  membership pair can create one report and target history is bounded by group
  size. Leaving either side deletes matching deterministic and legacy reports;
  rejoining starts a fresh moderation generation.
- Destructive automatic moderation counts only distinct pending reports from
  currently active, unbanned, non-deleting members whose Firebase Auth records
  are linked, present, and enabled. The transaction re-reads evidence and the
  target's eligibility. Report review separately re-reads each document and
  never overwrites a concurrent Admin dismissal.
- Valid static pack progress is restricted to the 64 IDs shipped in
  `assets/data/korean_vocab.csv`, strict schema/ranges, server timestamps, and
  irreversible `cleared` state. Offline create-as-cleared remains supported.
  Gye contribution is explicitly self-reported gamification, bounded by one
  durable account/pack/Gye receipt rather than represented as a verified
  learning credential.

## Retry and Privacy Properties

- `on_pack_cleared`, member deletion, user deletion, reporting, weekly rollover,
  and tombstone cleanup are retry-safe. Pack and weekly feed IDs are
  deterministic, receipt/rollover keys are durable, and errors are rethrown
  where a retry is required.
- Identity transforms re-read current documents in transactions, compose across
  concurrent departing users, preserve unrelated moderation fields, and do not
  recreate deleted documents.
- Account cleanup discovers legacy/stale Gye references through collection
  group queries on members, departures, bans, and processed pack receipts.
  Required collection-group indexes were added.
- Group deletion first sets `lifecycleState=deleting`, clears surviving user
  caches atomically, and then uses Admin recursive deletion. Retry observes the
  deleting state and resumes cleanup.

## Final Verification

- `flutter analyze`
  - No issues found.
- `flutter test`
  - 661 tests passed.
- `node --check functions/gye/index.js`
  - exit 0.
- `node --check functions/gye/lifecycle.js`
  - exit 0.
- `npm test` in `functions/gye`
  - 33 tests passed.
- `npm run test:rules` in `functions/gye`
  - Firestore emulator compiled the rules; 31 tests passed.
- `git diff --check`
  - exit 0 (line-ending conversion warnings only).

## Deployment Order and External Boundaries

No production deployment was performed. The generic functions deploy script
was removed. Deployment must use this order:

1. `npm run deploy:indexes`
2. Wait in Firebase Console until every new collection-group index is `READY`.
3. `npm run deploy:rules`
4. `npm run deploy:functions`

The last command targets only `functions:gye-firebase-functions`. Activating the
cleanup triggers before their indexes are ready is unsafe.

Still requiring release-owner verification:

- Run deployed Firebase trigger/scheduler end-to-end tests against a staging
  project, including Admin Auth provider lookup and recursive deletion.
- Confirm Scheduler/Blaze/API permissions and inspect production index readiness
  before functions deployment.
- The age gate is a conservative local self-attestation, not identity or
  cryptographic age verification.
- Pack completion is bounded self-reported gamification. Client feed actions
  still have no server-side rate limiter/App Check aggregation; deterministic
  reports bound report storage/read cost, but broader abuse protection remains
  a staging/operations concern.
- Legacy auto-ID report documents are deleted when either referenced member
  leaves; no production backfill was executed.

## Files Changed

- `analysis_options.yaml`
- `firestore.indexes.json`
- `firestore.rules`
- `functions/gye/index.js`
- `functions/gye/lifecycle.js`
- `functions/gye/lifecycle.test.js`
- `functions/gye/firestore.rules.test.js`
- `functions/gye/package.json`
- `functions/gye/package-lock.json`
- `lib/models/gye.dart`
- `lib/services/gye_service.dart`
- `lib/services/auth_service.dart`
- `lib/services/age_gate_service.dart`
- `lib/screens/gye_screen.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- generated localization files and `lib/l10n/gye_error_text.dart`
- `test/gye_hardening_test.dart`
- `test/age_gate_test.dart`
