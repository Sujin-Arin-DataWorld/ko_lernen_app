# Dancheong Public Sharing Implementation Plan

**User amendment — selected border (2026-10-03):** The user asked us to judge both supplied packages and integrate the best. Brocade Flow is the default after pixel/space review. Keep color-ribbon and lotus frames as alternatives. Bundle original RGBA bytes and contain the 4:5 frame uniformly within Story output. Use measured transparent inner windows; omit unchecked modular joins. The large flower is a fixed frame ornament; earned stamps remain separately visible medallions. Add an optional whitelisted public-manifest border field; omission preserves legacy unframed output.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for Native execution, or superpowers:subagent-driven-development when chosen by the user. Work task-by-task and leave changes uncommitted unless explicitly requested.

**Goal:** Connect a voluntarily published immutable artwork to an opaque, revocable DE/EN visitor page and a separate starter composition, without transferring the creator's rewards or learning progress.

**Architecture:** Existing Firebase Functions in the Gye codebase own authenticated creation/revocation, a private PNG and a private publication/index record. The existing Cloudflare website proxies validated public reads from fixed backend endpoints, keeping image and JSON requests on its own origin. Flutter sends only an explicitly reviewed finished export package; visitor starter state is independent and cannot write learner ownership or progress.

**Tech Stack:** Existing Node 22 Firebase Admin/Functions v2, private Cloud Storage, Firestore, Cloudflare Worker, vinext/React/TypeScript, existing Flutter cloud_functions. Backend image validation uses a bounded PNG decoder added to the functions package only after plan approval.

**Spec:** C:/dev/hangulsori/_codex_artifacts/dancheong-share-20261003-resumed/APP-DESIGN-SPEC.md. Prerequisite app interface: 2026-10-03-dancheong-app-connection.md, DancheongExportPackage.

## Global Constraints

- DE/EN UI, optional Korean artwork content. Visitors do not receive the creator's UID, rewards, stamps, learning state, unpublished drafts or unselected text.
- Public creation is a separate user action after reviewing exactly the PNG and manifest that will become public. Saving/exporting an image alone never publishes a page.
- A public snapshot belongs to a specific immutable artwork revision. Editing a local original cannot change its existing public page.
- An opaque ID is not the access-control mechanism for drafts. All private drafts remain local and all backend records/objects remain client-denied.
- Withdrawal, deletion fencing, stale identity cancellation and idempotent retry are required before enabling public creation in the app.
- No automatic Instagram posting, friend tagging or reward for visits/sharing. Analytics follows existing consent and excludes artwork text, names, UID and share IDs.
- Original output PNG bytes are preserved; no lossy recompression or public Storage download tokens.
- Plan completion proves local code, emulator integration and website build; publication on hangul-sori.com, backend deployment, app-link association and device/install return remain separately verified release steps. They are not declared complete from a localhost preview.
- Use the existing website, domain, locale paths, installation/tester links and security headers. Do not create a new external project, send marketing messages or replace the site homepage.
- No commit/push/merge/deploy without the user's explicit request. Rules/index readiness precedes the relevant Functions release per functions/gye/index.js.

## Review Focus

1. Creation succeeds but its response is lost: retry must return the same share ID, not create another publication. Task 2/6 test the persisted request ID and status recovery.
2. Revocation/account deletion occurs while image reading or publishing is pending: no late operation may reactivate the page. Tasks 2/3 own these tests.
3. A forged PNG, excessive payload, unknown template, hostile text or traversal ID must not become HTML, a remote URL or an unbounded decode. Task 1/4 own these tests.
4. Visitor remix must use a starter palette and never import owner identity/ownership/course credit. Task 5 owns the isolation test.
5. Missing App Check, changed UID and server/receiver failure must preserve the user's private artwork and edited captions. Task 6 owns those tests.

## Public contract

No new canonical collection data is introduced. Publication records are under users/{uid}/dancheong_publications/{requestId}, with a private lookup in dancheong_public_index/{shareId}. Storage objects are under dancheong_public/{uid}/{shareId}/art.png. Neither client Firestore nor client Storage APIs may read/write/list these paths. Server reads check the index, the owner's current publication status and account_deletions/{uid} before returning data; public read responses never serialize the private records directly.

Canonical share IDs are server-random 24-byte base64url strings (32 characters); route validation is /^[A-Za-z0-9_-]{32}$/. requestId is a client UUID persisted before upload. Reusing it with a changed canonical payload digest returns already-exists and retains the first publication.

```ts
type PublicDancheongManifest = {
  version: 1;
  template: "flower" | "brocade" | "letter";
  templateVersion: 1;
  assetVersion: 1;
  format: "portrait" | "story";
  width: 1080;
  height: 1350 | 1920;
  motifSlugs: string[];
  koreanText: string;
  translation: string;
  translationLocale: "de" | "en" | null;
  signature: string;
};
type PublicDancheongSnapshot = {
  shareId: string;
  artworkRevision: number;
  manifest: PublicDancheongManifest;
  imageSha256: string;
};
```

Private fields include ownerUid, ownerSubjectHash, requestId, local artwork ID, payloadDigest, imageObjectPath and publication status (pending/active/revoked). They never appear in public JSON or page analytics.

Callable endpoints: createDancheongShare({requestId, artworkRevision, manifest, pngBase64}), getOwnDancheongShare({requestId}), revokeDancheongShare({requestId}). Creation/recovery/revocation require Auth and enforce App Check, using europe-west3. HTTP endpoints: getDancheongShare?shareId=ID for JSON and getDancheongShareImage?shareId=ID for image/png. They expose only active opt-in snapshots, never lists or arbitrary URLs.

Website routes: /art/{shareId}?lang=de|en, /api/dancheong/art/{shareId}, /art/{shareId}/image.png and /dancheong/try?template=flower|brocade|letter&lang=de|en. The Worker proxies only the fixed europe-west3-ko-lernen-app.cloudfunctions.net endpoint names; it never forwards a user-provided target URL. Unsupported/missing locale defaults to de.

## Task 1: Strict manifest and bounded original PNG validation

**Files:** Create functions/gye/dancheong_share_contract.js, dancheong_share_contract.test.js and fixtures/dancheong_share_fixture.js; modify package.json/package-lock.json to register tests and a pinned PNG decoder after verifying its current primary documentation/security state. Create website app/dancheong/public-contract.ts with the same wire contract and tests/dancheong-contract.test.mjs.

**Interfaces:**

```js
validateShareId(value) // -> canonical string or ShareFailure('invalid-argument')
validateRequestId(value) // -> canonical UUID string or ShareFailure
validatePublicManifest(value) // -> frozen whitelisted object or ShareFailure
validateSharePng(bytes, manifest) // -> {width,height,sha256} or ShareFailure
canonicalPublicationDigest({manifest,artworkRevision,imageSha256}) // -> hex SHA-256
class ShareFailure extends Error { constructor(code) { super(code); this.code=code; } }
```

- [ ] Write tests for unknown/extra fields, invalid versions/format dimensions, 0/5 motifs, saved 25-slug whitelist, markup strings, valid Hangul/umlauts, path traversal, PNG signature without valid decode and oversized content. Add a true PNG fixture produced by the completed app renderer, not a renamed text buffer.

```js
assert.throws(() => validateShareId('../users/another-user'),
  (error) => error.code === 'invalid-argument');
assert.throws(() => validatePublicManifest({version: 99}),
  (error) => error.code === 'invalid-argument');
assert.equal(validateSharePng(validPortraitBytes, validManifest).width, 1080);
```

- [ ] Run `node --test dancheong_share_contract.test.js` in functions/gye before implementation; verify missing exports, then add them.
- [ ] Validate JSON before buffer decode; pngBase64 must be canonical base64, decoded bytes >0 and <=4 MiB, declared fixed dimensions and max 2,073,600 pixels. Validate header/chunks/CRC and successful bounded decode through the selected decoder, retaining the original byte buffer. No request can provide a bucket, object path, URL, UID or HTML. The 4MiB limit is a public service bound; a larger original remains privately exportable unchanged and gets a localized public-upload size explanation.
- [ ] Manifest strings use the same grapheme limits as the app (80/160/40) and max4 known motif slugs. Return exact selected text as data; never trust it as HTML. Canonical JSON order is explicitly version/template/templateVersion/assetVersion/format/width/height/motifSlugs/koreanText/translation/translationLocale/signature. The payload digest hashes that JSON + artworkRevision + imageSha256.
- [ ] Pass contract tests in Node and TypeScript; leave changes uncommitted.

## Task 2: Idempotent, fenced publication and public reads

**Files:** Create functions/gye/dancheong_share_runtime.js, dancheong_share_adapters.js, dancheong_share_runtime.test.js and test fixtures; modify functions/gye/index.js and package.json. No unrelated Gye/account-operation code changes.

**Interfaces:**

```js
createDancheongShareRuntime({repository,objects,now,randomId}) // -> runtime
// repository methods:
// reserve({uid,requestId,payloadDigest,shareId,manifest,artworkRevision,imageSha256})
//   -> {shareId,status,imageObjectPath}; fenced transaction checks deletion marker
// activate({uid,requestId,payloadDigest,imageSha256}) -> {shareId,status}
// own({uid,requestId}) -> private record or null
// publicRecord(shareId) -> active private record or null, with deletion check
// revoke({uid,requestId}) -> {shareId,status:'revoked'}; transaction first
// objects methods:
// putOnce({path,bytes,sha256}) -> void; existing same hash is success
// read(path) -> Buffer; remove(path) -> void
// runtime methods:
// create(request), own(request), revoke(request) -> callable result
// getPublic(shareId) -> PublicDancheongSnapshot | null
// getImage(shareId) -> Buffer | null
```

- [ ] Tests inject an in-memory repository and object adapter with deferred reads/writes. Prove missing Auth/App Check failure, retry with the same request ID/hash returns the same ID, changed payload conflicts, and two racing callers publish once. Test deletion between reserve/upload/activate and revocation while an image read is awaiting storage.

```js
const first = await runtime.create(authenticatedRequest(validPayload));
const retry = await runtime.create(authenticatedRequest(validPayload));
assert.equal(retry.shareId, first.shareId);
assert.equal(repository.activeCount(), 1);
await runtime.revoke(authenticatedRequest({requestId: validPayload.requestId}));
assert.equal(await runtime.getPublic(first.shareId), null);
assert.equal(await runtime.getImage(first.shareId), null);
```

- [ ] Run the runtime tests before implementing the factory/fixtures.
- [ ] reserve checks account_deletions and a per-UID short-term rate guard in one transaction (at most5 new requests in60seconds; stable retries do not increment). A stable existing request wins. Set pending status before the object upload. Objects use ifGenerationMatch:0 and hash metadata; a matching pre-existing object succeeds without overwrite. activate checks deletion marker, request digest and pending status in a transaction. Revoked/cleanup-claimed records cannot reactivate.
- [ ] For public image reads, check active state before storage and again immediately before returning bytes. JSON responses serialize only the whitelisted PublicDancheongSnapshot. No-store/max-age=0, nosniff; missing/revoked/deleting all produce 404 without exposing account details. Public endpoints are GET/HEAD only, with no CORS write surface.
- [ ] revoke changes status transactionally before attempting physical image cleanup; cleanup failure retains a durable retry state and the page remains inaccessible. Own-recovery requires the same UID and returns only that UID's request status.
- [ ] index.js adds the three authenticated callables with enforceAppCheck and existing v2 error mapping, plus two public read functions. Use region europe-west3, create timeout60s/maxInstances5/memory256MiB; recovery/revoke/read timeout15s/maxInstances10/memory128MiB. No bearer token is logged or returned. Tests run without Firebase credentials and emulator tests verify adapters separately. Leave changes uncommitted.

## Task 3: Account deletion, rules and orphan cleanup

**Files:** Modify functions/gye/deletion_cleanup_adapters.js, deletion_cleanup_adapters.test.js, firestore.rules, firestore.indexes.json, functions/gye/firestore.rules.test.js, functions/gye/storage.rules.test.js and functions/gye/index.js; add dancheong_public_cleanup.test.js. Storage's existing catch-all denial already blocks the new private prefix; test it rather than adding public allow rules.

**Interfaces:** Existing account-deletion cleanup keeps its fenced/paginated protocol. New cleanup stage handles dancheong_public_index via ownerSubjectHash and private objects via dancheong_public/{uid}/.

- [ ] Test a partially completed old cleanup checkpoint upgrades and replays the new stages; tests cover >page-size publications and blobs, interrupted delete, an object outside the exact UID prefix and a stale worker fence. Assert deleted/deleting users cannot publish/read even when an orphan index/blob remains.

```js
assert.equal(await runtime.getPublic(deletingOwnerShareId), null);
assert.equal(await runtime.getImage(deletingOwnerShareId), null);
// The existing cleanup adapter's fake bucket yields this foreign-prefix object;
// its paginated cleanup operation must reject it rather than delete it.
assert.equal(foreignObjectDeleteCalls, 0);
```

- [ ] Run deletion, publication and rules tests before adding the new stages.
- [ ] Add dancheong_public_index to HASH_OWNED_PROCESSOR_COLLECTIONS. Bump PROCESSOR_CLEANUP_SCHEMA_VERSION from2 to3. Keep the private TTS stage and add a subsequent Dancheong object stage; each bounded page is re-listed after deletion and checked against the exact owner prefix. Advance done only after both private-object stages return an empty page. The existing users-subtree deletion removes publication records.
- [ ] Add `collectionName != 'dancheong_publications'` to every read/create/update/delete condition in the current broad users/{uid}/{collectionName}/{document=**} rule (~527). A narrower deny alone cannot override Firestore's additive allow behavior. Add an explicit deny for this collection and for dancheong_public_index. Test anonymous/non-owner/owner direct access all fails while existing user backup and stamp storage still work.
- [ ] Add hourly scheduled cleanup of pending publications older than24h and revoked objects whose physical cleanup failed, at20 records/page. First claim a cleanup tombstone transactionally while verifying its unchanged pending/revoked state; activation rejects a claimed record. Then delete only its exact private image path and keep a retry marker until removal succeeds. Never remove active objects. Add collection-group indexes for dancheong_publications on status ASC + createdAt ASC, and status ASC + cleanupRequired ASC; preserve all existing indexes. Active published artwork has no automatic expiry.
- [ ] Run all functions/gye tests plus Firestore/Storage emulator tests. No rules or functions deployment is performed. Leave changes uncommitted.

## Task 4: Revocable DE/EN visitor page on the existing site

**Files:** Create app/art/[shareId]/page.tsx, app/dancheong/public-contract.ts, app/dancheong/dancheong-copy.ts, app/dancheong/shared-artwork.tsx, worker/dancheong-public.ts, tests/dancheong-public.test.mjs; modify worker/index.ts and package.json test scripts. Use existing site's CSS/type/locale/navigation conventions.

**Interfaces:**

```ts
export type DancheongPublicBackend = {
  getSnapshot(shareId: string): Promise<PublicDancheongSnapshot | null>;
  getImage(shareId: string): Promise<Response>;
};
export function handleDancheongPublic(request: Request,
  backend: DancheongPublicBackend): Promise<Response | null>;
export function dancheongLocale(value: unknown): "de" | "en";
```

- [ ] Test strict IDs, unsupported locale defaults, whitelisted JSON, escaped hostile text, revoked404, same-origin image requests and no-cache headers. The backend fake uses an immutable snapshot fixture; no test requires a production publication.

```js
assert.equal(dancheongLocale('ko'), 'de');
assert.equal(dancheongLocale('en'), 'en');
assert.equal(renderedHtml.includes('<script>alert('), false);
assert.equal(response.headers.get('cache-control'), 'no-store, max-age=0');
```

- [ ] Run website contract/public tests before adding route handlers.
- [ ] Worker routes validated /api/dancheong/art/{id} and /art/{id}/image.png to fixed backend origins with a10s timeout, bounded JSON/image sizes, no redirects, no credentials forwarded and no caching. Invalid IDs yield404 without network access. Existing withSecurityHeaders applies to these responses; do not weaken CSP or introduce a remote image source.
- [ ] /art/{id} shows the contained original artwork, its short cultural context, a visible DE/EN switch, “Deine Version gestalten / Create your version” and a secondary existing app-install/testing entry. No owner UID, progress or misleading claim that a visit grants stamps. Error page: “Dieses Kunstwerk ist nicht verfügbar / This artwork is unavailable” with a starter invitation.
- [ ] Use a same-origin OG image path and text independent of user names; private drafts never generate OG pages. Pages are noindex and absent from sitemap. Revoke stops future server reads; screenshots/downloads already kept by visitors cannot be recalled, which the public-choice UI explains succinctly.
- [ ] Run website lint/typecheck/unit/build and deployment dry-run locally. Rehearse in CUA at360/390px,200% text, keyboard and reduced motion. No deployment. Leave changes uncommitted.

## Task 5: Independent visitor starter and real-learning handoff

**Files:** Create app/dancheong/try/page.tsx, app/dancheong/visitor-studio.tsx, app/dancheong/visitor-renderer.ts, tests/dancheong-visitor.test.mjs and public/dancheong/v1 assets/manifest copied with source hashes; modify Flutter dancheong_routes.dart/main.dart with an additive /dancheong-entry handler and first-run continuation, tests/dancheong/dancheong_visitor_entry_test.dart.

**Interfaces:**

```ts
type VisitorDancheongDraft = {
  version: 1; template: "flower" | "brocade" | "letter";
  koreanText: string; signature: string;
};
export function starterFromPublic(snapshot: PublicDancheongSnapshot):
  VisitorDancheongDraft;
// Only the template crosses the boundary; text/signature start empty.
```

```dart
final class DancheongVisitorEntry {
  const DancheongVisitorEntry({required this.template, this.shareId});
  final DancheongTemplate template;
  final String? shareId;
  static DancheongVisitorEntry? parse(Uri uri);
}
```

- [ ] Test two visitors and one owner are isolated; changing a starter never mutates the fetched snapshot. Owner Korean text/signature/motif list/IDs/revision and course progress are not imported. Invalid route parameters fail closed, while onboarding must remain in front of the entry for first-run users.

```js
assert.deepEqual(starterFromPublic(snapshotWithPersonalText), {
  version: 1, template: snapshotWithPersonalText.manifest.template,
  koreanText: '', signature: '',
});
```

- [ ] Run visitor tests before implementing the page and route parser.
- [ ] Visitor experience uses a small separately labelled starter set and the three layout algorithms with original copied assets; it has no owner-stamp collection UI, authentication writes or reward API. Provide simple canvas composition, optional Korean text/signature and direct image save. A fixed “안녕 — Hallo / Hello” cultural micro-lesson explains informal use; any quiz is explicitly practice and never sends course completion.
- [ ] Real learning CTA opens the existing Lernpfad route through the app's first-run/consent guard. Select content only through the current curriculum catalogue and CoursePracticeContext.fromLink; do not invent a courseUnitId or inject a passed assessment. The pending Dancheong entry contains template/shareId only and is separate from course eligibility.
- [ ] Website installation uses app/store-links.ts and the current tester flow, including iOS's existing invitation requirement. Universal links/deferred installation return are enabled only after domain association and signed-build/device proof; until that proof, the page provides the existing install path and a clear “Open Hanok → Dancheong Studio” continuation. Do not present automatic install return as working in the local review.
- [ ] CUA verifies original→starter→micro-lesson→own image without owner transfer. Flutter tests prove entry/learning navigation leaves wallet/stamps/course state unchanged until actual existing learning validation succeeds. Leave changes uncommitted.

## Task 6: Flutter opt-in publication, recovery and withdrawal

**Files:** Create lib/features/dancheong/dancheong_public_service.dart, dancheong_publication_store.dart, test/dancheong/dancheong_public_service_test.dart; extend the share screen and DE/EN ARBs; add a new Storage strict raw boundary kl_dancheong_publications_v1. Do not change the local artwork document's version1 schema.

**Interfaces:**

```dart
enum DancheongPublicationStatus { pending, active, revoked }
final class DancheongPublicationAttempt {
  final String requestId;
  final String artworkId;
  final int revision;
  final String payloadDigest;
  final DancheongPublicationStatus status;
  final String? shareId;
}
final class DancheongPublicService {
  Future<DancheongPublicationAttempt> publish(DancheongExportPackage package);
  Future<DancheongPublicationAttempt> recover(String requestId);
  Future<void> revoke(String requestId);
}
final class DancheongPublicationStore {
  Future<void> save(DancheongPublicationAttempt attempt);
  DancheongPublicationAttempt? forRevision(String artworkId, int revision);
}
```

DancheongPublicationAttempt takes the declared fields as required named arguments, with shareId optional. PublicationStore's version1 JSON contains owner-scoped lists of those records and validates UUID, positive revision, 64-character hex digest and optional32-character shareId. Its strict Storage getter/setter are named dancheongPublicationsRawJson and setDancheongPublicationsRawJsonStrict(String json, {PreferenceStringStore? preferences, void Function()? assertCurrentWrite}). Use the same current identity/lifetime capture rules as DancheongStore; this is independent of reward/cloud backup payloads.

- [ ] Test persisted pending request before callable execution, lost response followed by status recovery, same request/hash retry, stale UID after rendering, App Check unavailable, API404/timeout and revoke while local original is edited. Private artwork and DE/EN caption drafts must be unchanged after every failure.

```dart
expect(await fakeApi.callsAfterLostReplyAndRecovery(),
    ['createDancheongShare', 'getOwnDancheongShare']);
expect(publicationStore.forRevision(artwork.id, artwork.revision)!.shareId,
    originalShareId);
expect(Storage.earnedStamps, beforeEarnedStamps);
```

- [ ] Run public-service tests before implementing the service.
- [ ] Add a distinct optional “Öffentliche Seite erstellen / Create public page” action. Its review sheet shows the exact PNG and visible fields, explains anyone with the link can view, and offers Cancel/Publish. Copying/sharing an image does not automatically trigger this action. On successful publication expose https://hangul-sori.com/art/{id}?lang=de|en; never compose a localhost public URL.
- [ ] PublicationStore uses the same serialized identity/lifetime/strict-write rules as the app store. Persist the request ID and digest before upload; recover own status after unknown response before retry. Do not generate a new request ID just because the network timed out. CloudWriteFence guards preparation, callable invocation and result attachment. A stale result is not attached to another user's work.
- [ ] “Seite zurückziehen / Withdraw page” calls revoke, preserves the private original and then disables the public link. On failed/unknown revoke keep a visible retry/recovery state rather than pretending removal succeeded. The app never logs body text, names or share IDs to analytics. Existing analytics opt-in governs bounded event names only.
- [ ] Run app feature/identity/reset tests and emulator end-to-end publish→fetch→revoke. Local emulators must be explicitly configured; production endpoint unavailability never falls back to a fake successful public page. Leave changes uncommitted.

## Task 7: Final rehearsal, release boundary and review

**Files:** Owned changes only. No manual SESSION_LOG/handoff or unrelated generated updates.

- [ ] Run Functions tests/rules emulators, website lint/typecheck/build/dry-run, Flutter analysis/features/full suite as required by changed assets/localization. Use contract fixtures generated from an actual Flutter export package across runtimes.
- [ ] CUA rehearses DE/EN original page, revoked page, starter, save and app-learning handoff. Check actual received PNG bytes and SHA-256 against the submitted export. Screenshots/prototype videos cannot prove a deployed public endpoint or native share receiver.
- [ ] Native/Subagent-driven review follows the user-selected method. Include privacy, retry, deletion-race and original-byte preservation checks; fix findings and rerun affected tests.
- [ ] Update Graphify in the isolated worktree. Deliver local implementation and evidence with precise remaining deployment/device/domain-association gates. Before any production release, prepare exact release commands/selected Functions, rules/index readiness, rollback and live verification for the user's final approval. Do not publish or send campaign messages as part of this plan review.

## Self-review and coverage

Explicit immutable public snapshot → Tasks1/2/6. Revocation/account deletion → Tasks2/3/4/6. Visitor independence and no fabricated progress → Task5. DE/EN/current website/token reuse → Tasks4/5. Actual PNG/original bytes → Tasks1/2/7 and app Plan Task3. Retry/identity/lifetime → Task6. Native sharing remains app Plan Task5. Automatic installation return requires release association/device evidence; it is deliberately not claimed before those checks. No product implementation, public service or website deployment was performed in the planning stage.

Recommend **Native** alongside the app plan, because image metadata, immutable revisions, pending-operation storage and deletion guards must remain consistent across Flutter and the public API. A final fresh review is required under that execution workflow.
