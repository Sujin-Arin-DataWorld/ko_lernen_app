# Data Stability and Cloud Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make sequential-course progress durable, schema-migratable, and safely reconcilable across devices and accounts without weakening Firebase backup-deletion or platform-security guarantees.

**Architecture:** The existing CourseMasterySnapshot becomes the one canonical course-progress record. A version-2 canonical preference record is written before legacy mirrors; version-1 data is migrated once, never discarded merely because an old scalar mirror exists. CloudSync and account replacement reconciliation carry a typed course snapshot rather than generic raw JSON, merge stable evidence deterministically, revalidate it against the current curriculum graph, and write only through the existing session/CAS fences. iOS and Web Firebase configuration is split into code-side fail-closed readiness and an explicit external setup boundary: no app IDs, plist values, OAuth values, or App Check keys are invented or committed.

**Tech Stack:** Flutter 3.44 / Dart 3.12, shared_preferences, Firebase Core/Auth/Firestore/App Check, Node.js 22 Firebase Functions tests, Flutter test.

## Global Constraints

- Scope is only data stability and synchronization. Do not change home information architecture, mission UI, grammar/smalltalk progression behavior, visual assets, or localization in this plan.
- Preserve the existing separation of placement, sequential-course, and browse state. Browse-level filtering must not be embedded in CourseMasterySnapshot.
- Preserve the existing 70% course gate, stable source IDs, courseEligible behavior, 300-item bounded evidence retention, and derived correction queue. The correction queue remains derived from evidence; it must not become a second persisted record.
- Canonical course persistence must be written before any legacy scalar mirror. A failed canonical write must leave all mirrors untouched.
- Never accept an unsupported future schema, malformed snapshot, unknown current catalog reference, same-ID/different-body evidence collision, or conflicting nonempty placement level as a successful merge.
- All normal backup/restore and account-replacement writes must stay behind the existing durable-account admission, CloudWriteSession fence, reconciliation CAS, and local-generation checks.
- Account cloud deletion must erase the new backup field. The field is privacy data and cannot be left behind by the deletion callable.
- Do not add fake FirebaseOptions, GoogleService-Info.plist, OAuth client IDs, App Check keys, Apple team IDs, APNs keys, or placeholder values. Those are release-operator inputs outside source control.
- Do not commit or push. Record completed work in AGENTS.md only after implementation and verification; this planning document is not a completion record.
- Use apply_patch for every repository edit. Follow red-green-refactor: each production behavior has a failing focused test first.

---

## Current-State Findings

1. CourseMasterySnapshot already owns placement, current unit, completed/bypassed units, evidence, and scenario checkpoints, but its version-1 JSON lives only in kl_course_mastery_v1.
2. CourseMasteryService writes placement and current-unit scalar mirrors before its strict JSON write. A failed JSON write can therefore leave old mirrors ahead of the durable snapshot.
3. CloudSync root backup and AccountReconciliationSnapshot deliberately enumerate fields. Neither currently includes course mastery.
4. The account reconciliation generic field merger is unsuitable for raw course JSON: it max-merges numbers and treats unlike scalar strings as conflicts.
5. The Firebase backup-deletion Function has a root-field allowlist. A new root backup field must be added to that list and its Node test.
6. Firebase Android is configured. Web and iOS Firebase options are intentionally absent; iOS GoogleService-Info.plist is ignored and the repository’s iOS setup document explicitly requires a local authorized configuration.

## Data Contract Decisions

### Local storage keys

| Purpose | Key | Rule |
|---|---|---|
| Canonical snapshot | kl_course_mastery_v2 | Required source of truth after a successful v1 migration or any new course write |
| Legacy snapshot input | kl_course_mastery_v1 | Read-only migration input; never preferred when v2 is present |
| Compatibility mirror | kl_placement_level_v1 | Updated only after canonical v2 persistence succeeds |
| Compatibility mirror | kl_course_unit_v1 | Updated or cleared only after canonical v2 persistence succeeds |
| Independent browse state | kl_browse_level_v1 | Not copied into, restored from, or merged with course snapshot |

### Course snapshot version 2

The version-2 JSON keeps the existing learner-facing fields so that evidence IDs and course semantics remain stable:

~~~json
{
  "version": 2,
  "placementLevel": "a1",
  "currentCourseUnitId": "a1_02_self_intro_identity",
  "completedUnitIds": ["a1_01_greetings_hangul"],
  "bypassedPrerequisiteUnitIds": [],
  "evidence": [],
  "scenarioCheckpoints": []
}
~~~

Version 1 has the same semantic fields. Its migration is an explicit decode-and-reencode into version 2 in the new canonical key. A missing version is treated only as legacy version 1. Versions greater than 2 or nonintegral/nonpositive versions fail closed. The migration must not move browseLevel into the snapshot.

### Cloud field

The root user document receives one typed field:

~~~text
course_mastery_json: JSON string containing canonical CourseMasterySnapshot v2
~~~

It remains a JSON string to preserve the existing root-document payload style and to make the exact payload part of the reconciliation CAS hash. It is never placed in AccountReconciliationSnapshot.fields, never generic-merged, and never restored directly to Storage without typed decoding and current-catalog validation.

### Deterministic merge contract

Given a local and remote typed snapshot:

1. Decode and migrate both snapshots to v2.
2. Validate each against the loaded CurriculumCatalog before merge.
3. Resolve placement:
   - null plus non-null uses the non-null placement;
   - equal non-null values are retained;
   - different non-null values are a courseMasteryPlacement conflict and stop the account replacement.
4. Union completed and bypassed IDs. Any overlap is a courseMasteryProgression conflict.
5. Union evidence and scenario checkpoints by stable ID. Identical ID plus identical canonical body deduplicates; identical ID plus a different canonical body is a courseMasteryEvidence or courseMasteryCheckpoint conflict.
6. Sort merged evidence and checkpoints by occurredAt UTC then stable ID before applying the existing bounded-retention algorithm. This makes merge order irrelevant.
7. Recompute currentCourseUnitId from the catalog: choose the earliest ordered unresolved unit whose prerequisites are completed or bypassed and whose level is not before placement. Do not choose either device’s last selected unit.
8. Validate the resulting snapshot with the same CourseMasteryService catalog validation used for local learning writes. If it is invalid, return a typed conflict and make no local or remote mutation.
9. Persist the normalized v2 snapshot. The correction queue is recomputed from its evidence after restoration; no queue JSON travels across devices.

The merge must be commutative and idempotent. A successful merge must produce the same canonical payload regardless of local/remote ordering or CAS retry count.

## File Structure

| File | Responsibility |
|---|---|
| lib/models/course_mastery.dart | Versioned snapshot codec, explicit v1-to-v2 migration, immutable canonical JSON helpers, typed merge-conflict data |
| lib/services/storage_service.dart | v2 canonical key, v1 fallback input, strict canonical write and mirror-clear helpers |
| lib/services/course_mastery_service.dart | Catalog-aware validation, deterministic normalized merge, canonical-first persistence, applying a reconciled snapshot |
| lib/services/course_progress_service.dart | Serialized public APIs for cloud restore/reconciliation; prevents UI activity writes racing a restore |
| lib/services/cloud_sync.dart | Include course_mastery_json in backup, typed normal restore, failure-without-clobber behavior |
| lib/services/account/account_reconciliation.dart | Typed snapshot member, decoder/encoder, generation fence, account-replacement merge and write |
| lib/services/account/account_transition_coordinator.dart | Carry the typed course merger through replacement reconciliation without weakening its journal/fence flow |
| lib/services/account/account_ui_operations.dart | Load the CurriculumCatalog once when constructing a replacement reconciliation flow and inject its typed merger |
| functions/gye/cloud_backup_deletion_runtime.js | Add course_mastery_json to the explicit backup-field deletion allowlist |
| lib/services/account/firebase_app_check_initializer.dart | Web App Check provider seam, injected for tests, fail closed when Web cloud options exist but site key is absent |
| docs/store/web-firebase-external-setup.md | Operator-only Web Firebase/Auth/App Check setup and test checklist |
| AGENTS.md | Session-log entry after the implemented changes have fresh verification evidence |

## Task 1: Canonical Course Snapshot V2 and Local Migration

**Files:**
- Modify: lib/models/course_mastery.dart
- Modify: lib/services/storage_service.dart
- Modify: lib/services/course_mastery_service.dart
- Modify: lib/services/course_progress_service.dart
- Test: test/course_mastery_test.dart

**Interfaces:**
- Produces CourseMasterySnapshot.currentVersion == 2.
- Produces CourseMasterySnapshot.decodeAndMigrate(Map<String, dynamic>) returning a v2 snapshot or throwing FormatException.
- Produces Storage.courseMasterySnapshotRawJson, Storage.legacyCourseMasteryRawJson, Storage.setCourseMasterySnapshotRawJson, and explicit clear helpers for stale dedicated mirrors.
- Produces CourseProgressService.applyReconciledSnapshot(CourseMasterySnapshot snapshot, {required String? expectedGeneration}).

- [ ] **Step 1: Add failing migration tests**

Add focused tests that pre-seed only kl_course_mastery_v1 with version 1 JSON, instantiate CourseMasteryService with the existing test catalog, call refresh, and expect:

~~~dart
expect(snapshot.version, 2);
expect(Storage.courseMasterySnapshotRawJson, contains('"version":2'));
expect(Storage.legacyCourseMasteryRawJson, contains('"version":1'));
~~~

Add an absent-snapshot test that pre-seeds only legacy placement/current-unit scalar keys, calls refresh, and expects a v2 canonical snapshot write. Add a future-version test that expects FormatException without overwriting either stored value.

- [ ] **Step 2: Run the migration tests and confirm RED**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/course_mastery_test.dart
~~~

Expected before implementation: the v2 key/API does not exist and the migration assertions fail for the missing behavior, not for a fixture typo.

- [ ] **Step 3: Implement the smallest codec and storage migration**

Implement a v2 canonical key alongside the v1 fallback. Decode v1/missing-version data into a v2 instance; reject unknown future versions. When v2 is absent, CourseMasteryService.refresh must validate the migrated snapshot and strict-write v2 before returning it. Do not remove the v1 key during this task.

- [ ] **Step 4: Add a failing canonical-first write test**

Use a PreferenceStringStore fixture whose v2 setString returns false. Initialize legacy scalar mirrors with known values, invoke the persistence path, and assert:

~~~dart
expect(Storage.placementLevelCode, oldPlacement);
expect(Storage.courseUnitId, oldCurrentUnit);
expect(Storage.courseMasterySnapshotRawJson, oldCanonicalJson);
~~~

Add a completed-course test with null currentCourseUnitId and assert the dedicated course-unit mirror is cleared only after the v2 snapshot exists.

- [ ] **Step 5: Implement canonical-first persistence**

Make CourseMasteryService._persist validate then strict-write v2 first. Only after that succeeds, update placement and course-unit compatibility mirrors. Clear only the dedicated course keys when a snapshot has null values; never erase unrelated browse state or legacy user-level state. Preserve the last known canonical cache if the strict write reports an uncertain or rejected platform result.

- [ ] **Step 6: Run focused local persistence tests**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/course_mastery_test.dart
~~~

Expected: all existing course tests plus new migration/ordering tests pass.

## Task 2: Catalog-Aware Typed Course Merge

**Files:**
- Modify: lib/models/course_mastery.dart
- Modify: lib/services/course_mastery_service.dart
- Modify: lib/services/course_progress_service.dart
- Create: test/course_mastery_sync_test.dart

**Interfaces:**
- Produces CourseMasteryMergeConflictKind with placement, version, evidence, checkpoint, and progression cases.
- Produces CourseMasteryMergeResult with either normalized snapshot or sorted conflicts.
- Produces CourseMasteryService.mergeForReconciliation({required CourseMasterySnapshot? local, required CourseMasterySnapshot? remote}).
- Produces:

~~~dart
typedef CourseMasteryReconciliationMerger =
    CourseMasteryMergeResult Function({
      required CourseMasterySnapshot? local,
      required CourseMasterySnapshot? remote,
    });
~~~

- Produces CourseProgressService.mergeCloudSnapshotJson(
  String raw, {required String? expectedGeneration}
  ) for normal restore; it decodes, validates, merges, and delegates the final write to applyReconciledSnapshot.

- [ ] **Step 1: Write failing merge-property tests**

Create two valid snapshots with disjoint evidence/checkpoints and assert:

~~~dart
expect(
  merge(local: first, remote: second).snapshot!.toJson(),
  merge(local: second, remote: first).snapshot!.toJson(),
);
expect(
  merge(local: first, remote: first).snapshot!.toJson(),
  firstNormalized.toJson(),
);
~~~

Add separate tests for duplicate stable IDs with changed bodies, nonempty a1/a2 placement mismatch, completed/bypassed overlap, invalid catalog IDs, and a merge where the deterministic current unit must be derived from resolved prerequisites instead of either input current unit.

- [ ] **Step 2: Run the merge test file and confirm RED**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/course_mastery_sync_test.dart
~~~

Expected before implementation: compile failure for the merge API or behavior failures for non-deterministic/unsupported merging.

- [ ] **Step 3: Implement merge normalization**

Extract only the existing catalog validation and bounded-retention primitives needed by the merger. Keep evidence sorted by occurredAt then ID before bounded retention. Validate local and remote snapshots before combining them, use typed conflicts rather than generic JSON differences, and recompute the earliest valid unresolved current unit after combining resolved IDs.

- [ ] **Step 4: Add a failing serialized-apply generation test**

Queue a local course write after capturing its canonical JSON generation. Attempt applyReconciledSnapshot with the stale expected generation and assert a LocalReconciliationGenerationConflict while leaving the later local evidence untouched.

- [ ] **Step 5: Implement serialized reconciled apply**

Expose CourseProgressService.applyReconciledSnapshot and route it through the existing serialized tail. The service must compare the expected canonical JSON generation before replacing local state, validate the incoming normalized snapshot, persist v2 canonical-first, and throw the existing reconciliation generation conflict type on a race.

- [ ] **Step 6: Run local merge tests**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/course_mastery_test.dart test/course_mastery_sync_test.dart
~~~

Expected: merge commutativity, idempotence, conflict, generation-fence, and existing progression tests all pass.

## Task 3: Normal Durable-Account Cloud Backup and Restore

**Files:**
- Modify: lib/services/cloud_sync.dart
- Modify: lib/services/course_progress_service.dart
- Modify: lib/services/course_mastery_service.dart
- Modify: test/cloud_sync_test.dart
- Modify: test/services/account/cloud_writer_fence_test.dart

**Interfaces:**
- CloudSync.buildBackupPayload emits course_mastery_json only when a structurally valid canonical snapshot exists.
- CloudSync.applyRestorePayload routes course_mastery_json through CourseProgressService.mergeCloudSnapshotJson.
- Invalid cloud course JSON returns the existing invalid/blocked restore outcome and never mutates local course state.

- [ ] **Step 1: Add failing backup-payload and fresh-device restore tests**

Extend the payload enumeration fixture with a valid v2 snapshot and expect:

~~~dart
expect(payload['course_mastery_json'], isA<String>());
expect(jsonDecode(payload['course_mastery_json'] as String)['version'], 2);
~~~

On an empty device, restore this payload and verify placement/current unit/evidence survive a fresh CourseMasteryService.refresh.

- [ ] **Step 2: Run the targeted CloudSync tests and confirm RED**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/cloud_sync_test.dart test/services/account/cloud_writer_fence_test.dart
~~~

Expected before implementation: payload does not contain course_mastery_json and no typed restore occurs.

- [ ] **Step 3: Implement typed backup and restore**

Add course_mastery_json to CloudSync’s explicit restorable field set and payload builder. Decode it through the course codec, then call the serialized, catalog-aware merge API; do not call Storage.setCourseMasterySnapshotRawJson directly from CloudSync. Keep existing durable-account deletion admission and session checks around the complete restore.

- [ ] **Step 4: Add failure-no-clobber and stale-session tests**

Provide malformed cloud JSON and an invalid catalog reference, then assert the local canonical JSON remains byte-for-byte unchanged. Exercise a stale CloudWriteSession and assert the course writer is not invoked.

- [ ] **Step 5: Implement fail-closed restore handling**

Map malformed, future-version, catalog-invalid, and typed-merge conflict data to existing invalid/blocked outcomes before any course persistence. Ensure a stale session stops before course state is read or written.

- [ ] **Step 6: Run targeted cloud tests**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/cloud_sync_test.dart test/services/account/cloud_writer_fence_test.dart test/course_mastery_sync_test.dart
~~~

Expected: ordinary backup/restore remains additive, and course restoration has explicit non-clobber behavior.

## Task 4: Account-Replacement Reconciliation and Backup Deletion

**Files:**
- Modify: lib/services/account/account_reconciliation.dart
- Modify: lib/services/account/account_transition_coordinator.dart
- Modify: lib/services/account/account_ui_operations.dart
- Modify: functions/gye/cloud_backup_deletion_runtime.js
- Modify: functions/gye/cloud_backup_deletion_runtime.test.js
- Test: test/services/account/account_reconciliation_test.dart
- Test: test/services/account/cloud_sync_service_test.dart

**Interfaces:**
- AccountReconciliationSnapshot gets CourseMasterySnapshot? courseMastery and String? localCourseMasteryGeneration.
- AccountReconciliationConflictKind gets courseMasteryPlacement, courseMasteryVersion, courseMasteryEvidence, courseMasteryCheckpoint, and courseMasteryProgression cases.
- AccountReconciliationMerger.merge gets an optional CourseMasteryReconciliationMerger? courseMasteryMerger. If both account snapshots have no courseMastery, it remains optional for existing non-course test fixtures; if either has courseMastery and no merger is supplied, reconciliation returns a typed version conflict rather than falling back to raw JSON.
- LocalAccountReconciliationStore.write applies a reconciled course snapshot through CourseProgressService with the captured generation.

- [ ] **Step 1: Add failing account reconciliation tests**

Add tests that decode course_mastery_json into the typed member rather than fields, merge two devices with disjoint evidence successfully, block a placement mismatch with a typed conflict, and prove a raw course JSON string never passes through _mergeFields.

Add a coordinator test where a local course write happens after loadLocal but before writeLocal. Expect the reconciliation to retry through LocalReconciliationGenerationConflict and never overwrite the newer local attempt.

- [ ] **Step 2: Run the focused account tests and confirm RED**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/services/account/account_reconciliation_test.dart test/services/account/cloud_sync_service_test.dart
~~~

Expected before implementation: course_mastery_json is either absent or would be treated as an ordinary field.

- [ ] **Step 3: Implement typed account snapshot plumbing**

Decode course_mastery_json separately in AccountReconciliationSnapshot.decodeCloudDocument and omit it from _ordinaryFields. Include only a canonical serialized typed snapshot in toCloudDocument. Add its canonical generation to local snapshot capture and equality/hash behavior. Do not relax existing SRS/custom-pack/pack-progress conflict rules.

- [ ] **Step 4: Inject the current curriculum merger**

When account UI constructs its replacement coordinator, load CurriculumCatalog alongside the existing pack catalog and pass CourseMasteryService’s catalog-aware merger through the replacement reconciliation boundary. Tests may inject a small test catalog and merger; production must not construct a fallback “first unit” catalog.

- [ ] **Step 5: Implement session-fenced local course write**

After remote CAS succeeds, write the reconciled course snapshot through CourseProgressService.applyReconciledSnapshot with its captured generation. Preserve the existing remote-first/local-second checkpoint sequence, CAS retry behavior, and session fence. A local course-generation conflict must retry the reconciliation instead of clobbering a learner action.

- [ ] **Step 6: Add failing backup-deletion allowlist test**

Extend the Node runtime test’s root user fixture with course_mastery_json and assert the deletion result removes it while preserving operational profile fields.

- [ ] **Step 7: Implement deletion-field removal and run both ecosystems**

Add course_mastery_json to BACKUP_FIELDS, then run:

~~~text
flutter test --no-pub --concurrency=1 test/services/account/account_reconciliation_test.dart test/services/account/cloud_sync_service_test.dart
node --test functions/gye/cloud_backup_deletion_runtime.test.js
~~~

Expected: account replacement uses typed data and cloud-data deletion erases course progress.

## Task 5: iOS/Web Firebase Readiness Without Invented Credentials

**Files:**
- Modify: lib/services/account/firebase_app_check_initializer.dart
- Create: test/services/account/firebase_app_check_initializer_test.dart
- Create: docs/store/web-firebase-external-setup.md
- Modify: docs/store/ios-external-setup.md
- Modify: AGENTS.md after verified implementation

**Interfaces:**
- FirebaseAppCheckActivator accepts:

~~~dart
Future<void> Function({
  WebProvider? webProvider,
  required AndroidProvider androidProvider,
  required AppleProvider appleProvider,
}) activate;
~~~

- FirebaseAppCheckInitializer accepts injectable isWeb and webAppCheckSiteKey values for tests.
- Production reads only String.fromEnvironment('FIREBASE_WEB_APP_CHECK_SITE_KEY'); a missing key on an otherwise configured Web app fails closed before protected cloud calls begin.

- [ ] **Step 1: Add failing App Check selection tests**

Add tests asserting:

~~~dart
expect(captured.webProvider, isA<ReCaptchaV3Provider>());
expect((captured.webProvider as ReCaptchaV3Provider).siteKey, 'test-site-key');
~~~

for Web plus a configured key, and an explicit configuration exception for Web plus an empty key. Confirm Android and Apple provider choices remain unchanged.

- [ ] **Step 2: Run the focused test and confirm RED**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/services/account/firebase_app_check_initializer_test.dart
~~~

Expected before implementation: the activator cannot receive a WebProvider and missing-key Web behavior is undefined.

- [ ] **Step 3: Implement the credential-free Web provider seam**

Pass ReCaptchaV3Provider only on Web when a nonempty build-time site key exists. Do not place the key in a tracked Dart file or a document example. Keep Android debug/Play Integrity and Apple debug/App Attest with DeviceCheck fallback exactly as now.

- [ ] **Step 4: Write operator runbooks, not fake configuration**

Document the exact authorized steps:

1. Register the Web app in Firebase project ko-lernen-app.
2. Run FlutterFire configure with the actual Android/iOS/Web app selections; review generated firebase_options.dart and firebase.json instead of hand-editing app IDs.
3. Configure authorized Auth domains and the Google/Apple provider redirect requirements.
4. Create the Firebase App Check Web reCAPTCHA v3 provider and pass its public site key only through the build environment.
5. For iOS, download GoogleService-Info.plist locally, add it to Runner target membership, register the URL scheme, and verify on macOS/Xcode using the existing iOS external setup gate.
6. Verify Web authentication, Firestore backup/restore, App Check-protected callable access, iOS sign-in, APNs, and physical-device archive behavior after the operator configuration.

- [ ] **Step 5: Run source-side Firebase checks**

Run:

~~~text
flutter test --no-pub --concurrency=1 test/services/account/firebase_app_check_initializer_test.dart test/ios_firebase_configuration_test.dart
flutter build web --release
~~~

Expected: code compiles and fails closed when credentials are absent. These commands do not prove an authorized iOS/Web Firebase deployment.

## Task 6: End-to-End Verification and Documentation

**Files:**
- Modify: AGENTS.md
- Verify: all files listed above

- [ ] **Step 1: Format and inspect scope**

Run:

~~~text
dart format lib/models/course_mastery.dart lib/services/storage_service.dart lib/services/course_mastery_service.dart lib/services/course_progress_service.dart lib/services/cloud_sync.dart lib/services/account/account_reconciliation.dart lib/services/account/account_transition_coordinator.dart lib/services/account/account_ui_operations.dart lib/services/account/firebase_app_check_initializer.dart test/course_mastery_test.dart test/course_mastery_sync_test.dart test/cloud_sync_test.dart test/services/account/account_reconciliation_test.dart test/services/account/cloud_sync_service_test.dart test/services/account/firebase_app_check_initializer_test.dart
git diff --check
git status --short
~~~

- [ ] **Step 2: Run complete local verification**

Run:

~~~text
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test --no-pub --concurrency=1
flutter build web --release
node --test functions/gye/cloud_backup_deletion_runtime.test.js
~~~

If Android signing credentials are available locally, additionally run flutter build apk --debug. Do not claim iOS archive, device sign-in, APNs, or live Web Firebase verification from Windows.

- [ ] **Step 3: Perform manual state probes**

Use isolated SharedPreferences fixtures or the app’s debug path to demonstrate:

1. v1 snapshot migrates once and stays recoverable from v2.
2. A second device’s valid course evidence survives restore and does not retroactively unlock future browsing.
3. Conflicting placement or corrupt remote JSON leaves the local course untouched.
4. A deletion test payload removes course_mastery_json.
5. Unconfigured Web and iOS remain local-only rather than partially starting cloud services.

- [ ] **Step 4: Record measured results**

Append a Korean session-log entry to AGENTS.md listing changed contracts, commands, actual passing counts, and the explicit external boundary: Firebase Console/Apple registrations, real FlutterFire outputs, and macOS/device validation remain operator work until evidence exists.

## Acceptance Criteria

- A valid v1 local course snapshot migrates to canonical v2 without losing stable evidence, checkpoint, placement, completed/bypassed unit, or current-unit state.
- Canonical v2 persistence precedes all compatibility mirror updates; a rejected canonical write does not advance mirrors.
- Course state remains separate from browse state.
- Normal durable-account backup/restore includes course_mastery_json and uses catalog-aware typed merge, never generic raw JSON merge.
- Two-device merges are deterministic, idempotent, bounded, and conflict explicitly on incompatible placement/schema/IDs/progression.
- Account replacement has the same typed merge, root CAS coverage, session fence, and local-generation safety as other reconciled data.
- Cloud backup deletion removes course_mastery_json.
- Web App Check can be configured through a build environment key and fails closed when that required key is absent.
- iOS/Web Firebase application configuration is documented as an external operator step; no placeholder or secret enters source control.
- Fresh analyzer, targeted tests, full test suite, Web build, Node deletion test, and git diff --check evidence are captured before completion.

## Explicit External Boundary

This plan can make the source code ready for real iOS/Web Firebase configuration. It cannot itself create a Firebase iOS/Web app, produce GoogleService-Info.plist, generate real FirebaseOptions, enable Auth providers, configure authorized domains, create an App Check reCAPTCHA key, upload APNs credentials, configure Apple signing, or perform macOS/physical-device validation. Those actions require access to Firebase Console and Apple Developer resources owned by the release operator.
