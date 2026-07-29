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
- Account tombstones now require a server-only cleanup completion receipt.
  Auth-missing observation and the final 24-hour deletion window cannot begin
  until every Gye, shared-pack, processed-pack, and notification-outbox cleanup
  step succeeds.
- Weekly goal delivery now uses deterministic per-recipient outbox documents
  written atomically with rollover. A retryable create trigger plus a bounded
  15-minute sweeper claims work with a five-minute lease, retries only
  unsettled recipients, and retains terminal receipts for 30 days.

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
- The review-fix RED run had 33 passes and seven failures: incomplete account
  cleanup incorrectly started the Auth-missing clock, cleanup completion had
  no ordered receipt boundary, deleting users could not be exercised through a
  pure MVP selector, legacy lifecycle delivery had no contract, and durable
  outbox creation/multicast classification did not exist. Follow-up RED tests
  caught raw-token deletion for `messaging/invalid-argument`, absent settled
  token hashing, expired-lease starvation, and missing leave cleanup.

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
- `on_user_deleted` writes `cleanupComplete=true` only after all cleanup steps
  return successfully and erases any stale `authMissingSince`. The scheduler
  retains incomplete markers and starts a fresh post-completion Auth-missing
  window. Account-deleting users remain excluded from successor and MVP
  selection while the marker is retained.
- Goal rollover creates one deterministic, UID-hiding outbox ID per eligible
  member inside the rollover transaction. Delivery rechecks legacy-active Gye,
  membership, ban, account marker, and user state. Only invalid or unregistered
  token errors remove raw FCM tokens; message/config and transient failures
  remain retryable.

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
  outbox delivery/maintenance, and tombstone cleanup are retry-safe. Pack,
  weekly feed, and per-recipient outbox IDs are deterministic; receipt/rollover
  keys are durable; errors are rethrown where a retry is required.
- Identity transforms re-read current documents in transactions, compose across
  concurrent departing users, preserve unrelated moderation fields, and do not
  recreate deleted documents.
- Account cleanup discovers legacy/stale Gye references through collection
  group queries on members, departures, bans, processed pack receipts, and
  notification outboxes. Required collection and collection-group indexes were
  added. Normal leave and account deletion immediately remove matching outbox
  documents.
- Group deletion first sets `lifecycleState=deleting`, clears surviving user
  caches atomically, and then uses Admin recursive deletion. Retry observes the
  deleting state and resumes cleanup.
- Outboxes store no raw FCM token. Successful and permanently invalid
  recipients are tracked by SHA-256 token hashes so a partial retry sends only
  unsettled current tokens. Terminal `sent`/`skipped` receipts, UID, and hashes
  expire after 30 days; pending work is preserved and expired delivery leases
  are reclaimed.

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
  - 46 tests passed.
- `npm run test:rules` in `functions/gye`
  - Firestore emulator compiled the rules; 32 tests passed.
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
cleanup and outbox triggers before their indexes are ready is unsafe.

Still requiring release-owner verification:

- Run deployed Firebase trigger/scheduler end-to-end tests against a staging
  project, including Admin Auth provider lookup, recursive deletion, FCM
  partial delivery, lease recovery, and retention cleanup.
- Confirm Scheduler/Blaze/API permissions and inspect production index readiness
  before functions deployment.
- Delivery is accepted at-least-once. The lease prevents overlapping
  trigger/sweeper sends, and settled token hashes prevent ordinary partial
  retries. A process crash after FCM accepts a send but before Firestore writes
  its receipt can still redeliver; deterministic Android `collapseKey`, APNs
  `apns-collapse-id`, and the data `eventKey` mitigate but cannot mathematically
  eliminate that provider boundary. Live APNs/FCM delivery still requires
  staging credentials and device verification.
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
