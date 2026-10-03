# Dancheong App Connection Implementation Plan

**User amendment — selected border (2026-10-03):** The user asked us to judge both supplied packages and integrate the best. Brocade Flow is the default after pixel/space review. Keep color-ribbon and lotus frames as alternatives. Bundle original RGBA bytes and contain the 4:5 frame uniformly within Story output. Use measured transparent inner windows; omit unchecked modular joins. The large flower is a fixed frame ornament; earned stamps remain separately visible medallions. Add an optional whitelisted public-manifest border field; omission preserves legacy unframed output.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for Native execution, or superpowers:subagent-driven-development if the user chooses that method. Execute task-by-task; checkboxes track the work. No commit, push, merge or deployment without the user's explicit request.

**Goal:** Connect reusable collected motifs to a native DE/EN studio, persistent original artwork, image sharing and the four approved app entry points.

**Approved execution amendment (2026-10-03):** The user chose Native and instructed “일단 사랑방은 좀 빼봐…일두고택이랑 연결지어야…”. The Sarangbang artwork display, room reference model/store methods and its tests below are excluded from execution. The permanent studio stays in Hanok's IlDu estate context. Finished work is viewed in Artwork and exported/shared; no historic IlDu building paint or house geometry is changed. Existing Sarangbang learning/furnishing features are preserved. This amendment takes precedence over retained earlier room-display descriptions.

**Architecture:** A feature-owned versioned document stores drafts, immutable finished revisions, caption drafts and one room reference. Existing Storage owns the raw durable write boundary; existing stamp metadata owns the 25 saved slugs. Screens use one controller and one renderer; reward services are read-only inputs. Public snapshots and visitor pages have a separate plan and consume an explicit export package.

**Tech Stack:** Existing Flutter/Dart, shared_preferences, share_plus, AppL10n, Sori widgets, dart:ui Canvas/TextPainter. No additional Flutter dependency.

**Spec:** C:/dev/hangulsori/_codex_artifacts/dancheong-share-20261003-resumed/APP-DESIGN-SPEC.md — approved by the user's subsequent “좋아. 연결해줘.” The approved placement is also recorded in v3-placement/PLACEMENT-APPROVAL.json.

## Global Constraints

- Product UI is DE/EN; Korean is optional artwork content. UI language never changes artwork text or caption-language selection.
- Preserve the five root tabs, /dojangcheop, /sarangbang, /sarangbang/furnish, /bojagi and /path.
- Preserve all 25 stamp slugs and the 19 Dancheong / 6 living-culture distinction, including separate peony and moran.
- Ownership is read from Storage.earnedStamps. Creation, saving, display, export, sharing and visits grant no XP, coins, stamps, boxes or course progress.
- A first owned motif must support all three composition layouts. Zero owned motifs permits examples and cultural reading, with the existing learning entry to earn a material.
- Original approved image bytes are preserved. Research boards are not individual reusable layers. The crane study's baked Korean text is not editable text.
- Use the current Sori colour/type/spacing/button tokens. The approved tactile contract lives in the textured-ui-runtime-20261002 worktree; do not copy or overwrite the other session's token WIP.
- Actual export sizes are 1080 × 1350 and 1080 × 1920 PNG, with contained artwork and no UI chrome, hashtags or automatic QR overlay.
- Drafts and caption edits survive restart. Local artwork is device-local in this stage; cloud synchronization across devices is not claimed. Existing learning cloud reconciliation is unchanged.
- Local/account reset must invalidate pending writes and clear the new kl_ preference. Switching accounts must never display another account's work.
- 360/390 logical pixels, 200% system text, semantics, keyboard focus, dark mode and Reduce Motion must remain usable.
- Work only in C:/dev/hangulsori/ko_lernen_app_worktrees/dancheong-app-connect-20261003, branch session/dancheong-app-connect-20261003, baseline 2257583bd376ea7be6b8bd0d6ca102b7d242c91e. Origin/main 34f1b0ca51de4f9b69db7d499b74fc17844dd878 is an ancestor of this design baseline. Do not cherry-pick other sessions' WIP.

## Review Focus

1. Account A → B → A while an image/save is pending must never revive a stale A result. Owned by Task 2's identity-epoch test and Task 4's controller test.
2. A corrupted or future-version draft must not be silently overwritten, and must not hide existing learning or the room. Owned by Tasks 1, 2 and 6.
3. Empty, long and multiline Hangul/German text, umlauts and emoji must be preserved and fit the exported composition. Owned by Task 3's real-font render tests and Task 4's form tests.
4. Count-only stamp receipts and stale ownership must not invent a specific motif. Owned by Task 6's receipt tests.
5. Sharing cancellation/unavailable services and interrupted caption edits must retain the user's draft and must not be reported as posted. Owned by Task 5's restart/outcome tests.

## Integration decisions

New named routes are /dancheong-studio, /dancheong-studio/edit, /dancheong-artwork and /dancheong-share. Navigation uses typed arguments; malformed arguments show the hub or a localized missing-artwork state. /dojangcheop remains the existing collection screen, with an additive studio action. The studio's Patterns tab embeds a reusable extracted collection body; its Artwork tab shows only this identity's drafts/revisions.

The Hanok studio card follows the verified learning summary and precedes the existing four collection shortcuts. Today resume follows the pending Bojagi section and is omitted when no owned draft exists. The receipt's existing Continue remains primary; the motif action is optional. Sarangbang gains a framed finished-work section immediately after the existing room scene, before study material; no house geometry or furniture placement schema changes.

Initial layouts are flower, brocade and letter. Each places the learner's actual selected motif bytes: a focal motif with repeated smaller surrounds, a repeated tile composition, or a quiet letter/seal composition. Low-resolution 512px sources never exceed their native pixel dimensions in export; larger motifs are limited to 720px. The full 05 and 08 research compositions are explicitly marked examples, rather than presented as editable individual stamps. The approved transparent flower study may replace the lotus focal layer, and the ribbon study may supply a template frame; metadata records that template art separately from owned stamp references.

## File and interface map

All new feature files are under lib/features/dancheong/:

- dancheong_models.dart: immutable data, codec and limits.
- dancheong_catalog.dart: template definitions, asset versions and exact saved-slug lookup through DancheongMotif.values.
- dancheong_store.dart: serialized read/modify/write and identity/lifetime guard.
- dancheong_controller.dart: edit/save state and observation.
- dancheong_renderer.dart: shared preview/export composition.
- dancheong_share_service.dart: file sharing result mapping.
- dancheong_routes.dart: typed route contracts and entry parsing.
- screens/dancheong_studio_screen.dart, dancheong_editor_screen.dart, dancheong_artwork_screen.dart, dancheong_share_screen.dart: focused native screens.
- widgets/dancheong_entry_card.dart, dancheong_draft_resume.dart, sarangbang_artwork_display.dart: additive entry/display widgets.

The public plan consumes DancheongExportPackage only. It never writes the motif collection or accesses local drafts.

### Task 1: Versioned artwork and catalogue

**Files:** Create the feature models/catalogue and test/dancheong/dancheong_models_test.dart; modify neither enum nor stored stamp values.

**Interfaces:**

```dart
enum DancheongTemplate { flower, brocade, letter }
enum DancheongFormat { portrait, story }
enum DancheongCaptionLocale { de, en }
enum DancheongDocumentHealth { healthy, malformed, unsupported }

// Interface declarations below define exact types; codec implementation belongs
// to Step 3. All lists/maps are defensively copied and unmodifiable.
final class DancheongComposition {
  final DancheongTemplate template;
  final DancheongFormat format;
  final List<String> motifSlugs;
  final String koreanText;
  final String translation;
  final String? translationLocale;
  final String signature;
  final int templateVersion;
  final int assetVersion;
  Map<String, Object?> toJson();
  static DancheongComposition fromJson(Object? raw);
}
final class DancheongDraft {
  final String id;
  final DancheongComposition composition;
  final DateTime updatedAt;
}
final class DancheongArtwork {
  final String id;
  final int revision;
  final DancheongComposition composition;
  final DateTime completedAt;
  Map<String, Object?> toJson();
}
final class DancheongRoomArtworkRef {
  final String artworkId;
  final int revision;
}
final class DancheongLocalDocument {
  final Map<String, DancheongOwnerDocument> owners;
  String encode();
  static DancheongDocumentRead decode(String raw);
}
final class DancheongOwnerDocument {
  final List<DancheongDraft> drafts;
  final List<DancheongArtwork> artworks;
  final Map<String, String> captions;
  final DancheongRoomArtworkRef? roomArtwork;
}
final class DancheongDocumentRead {
  final DancheongDocumentHealth health;
  final DancheongLocalDocument? document;
}
DancheongMotif? knownMotif(String slug);
Set<String> knownOwnedMotifs(Iterable<String> earnedSlugs);
String captionKey({required String artworkId, required int revision,
  required DancheongFormat format, required DancheongCaptionLocale locale});
```

- [ ] Add tests for 25-slug round-trip, unknown values, peony/moran distinction, unsupported document version and immutable revisions. Preserve unknown raw data in an unhealthy read result, rather than decoding to an empty healthy document.

```dart
test('unknown saved slugs do not grant ownership', () {
  expect(knownOwnedMotifs(['lotus', 'moran', 'peony', 'futureMotif']),
      {'lotus', 'moran', 'peony'});
});
test('future documents are not writable empty documents', () {
  final read = DancheongLocalDocument.decode('{"version":2,"owners":{}}');
  expect(read.health, DancheongDocumentHealth.unsupported);
  expect(read.document, isNull);
});
```

- [ ] Run `flutter test test/dancheong/dancheong_models_test.dart`; first run fails because the feature types do not exist.
- [ ] Implement a strict version-1 codec. IDs are opaque UUID strings; reject path separators, invalid timestamps/revisions, unsupported template/asset versions, duplicate (id,revision) keys and non-string text. Text limits: Korean 80 grapheme clusters, translation 160, signature 40, caption 2200; at most 4 motifs/composition, 30 drafts and 100 finished revisions per owner. Reaching a bound returns a localized limit state, never evicts a user's work silently. Caption keys use JSON encoding of the tuple, not delimiter concatenation.

```dart
DancheongMotif? knownMotif(String slug) => DancheongMotif.values
    .where((motif) => motif.name == slug).firstOrNull;
Set<String> knownOwnedMotifs(Iterable<String> earnedSlugs) => {
  for (final slug in earnedSlugs)
    if (knownMotif(slug) != null) slug,
};
String captionKey({required String artworkId, required int revision,
  required DancheongFormat format, required DancheongCaptionLocale locale}) =>
    jsonEncode([artworkId, revision, format.name, locale.name]);
```

- [ ] Run the model tests and existing `test/dancheong_stamp_test.dart`; both must pass. Review only owned changes; leave them uncommitted.

### Task 2: Durable, identity-scoped local store

**Files:** Create dancheong_store.dart and test/dancheong/dancheong_store_test.dart; modify lib/services/storage_service.dart near typedStudyBookmarksRawJson. Use existing lib/services/local_data_lifetime.dart, services/account/cloud_write_session.dart and PackCompletionStorage's write/reset admission.

**Interfaces:**

```dart
// New Storage boundary; no direct SharedPreferences writes in screens.
static const dancheongStudioPreferenceKey = 'kl_dancheong_studio_v1';
static String get dancheongStudioRawJson;
static Future<void> setDancheongStudioRawJsonStrict(String json, {
  PreferenceStringStore? preferences, void Function()? assertCurrentWrite});

final class DancheongStore {
  DancheongStore({String Function()? readRaw,
    Future<void> Function(String, void Function())? writeRaw,
    CloudWriteSessionController? sessions});
  DancheongDocumentRead read();
  DancheongOwnerDocument currentOwner();
  Future<void> saveDraft(DancheongDraft draft);
  Future<DancheongArtwork> finishDraft(String draftId);
  Future<void> saveCaption(String key, String text);
  Future<void> setRoomArtwork(DancheongRoomArtworkRef? reference);
  Future<void> deleteDraft(String draftId);
  Future<void> deleteArtwork(String artworkId, int revision);
}
```

All model constructors take the declared fields as named required parameters, except document collections default to empty and roomArtwork defaults to null. Composition version fields default to1. Document encode writes top-level `version:1`; UTC timestamps serialize with toIso8601String(). Its fromJson performs the exact validation and bound checks below, with FormatException for invalid records.

- [ ] Test real preference round-trips through a new store instance, one rejected setter reply, corrupt blobs, two queued caption updates, A → B → A and reset during a delayed setter. An injected writer must call its guard before setting the raw value.

```dart
test('restart restores independently edited caption languages', () async {
  final store = DancheongStore();
  await store.saveCaption('de-key', 'Mein eigener Text');
  await store.saveCaption('en-key', 'My own words');
  final restarted = DancheongStore();
  expect(restarted.currentOwner().captions['de-key'], 'Mein eigener Text');
  expect(restarted.currentOwner().captions['en-key'], 'My own words');
});
```

- [ ] Run `flutter test test/dancheong/dancheong_store_test.dart`; verify a missing implementation failure before adding the store.
- [ ] Add Storage getter/setter through `_ssStrict`, passing assertCurrentWrite. Capture LocalDataLifetime.capture(), current UID, identityEpoch and permission mode before enqueueing. In the serial queue re-read the current document, assert the captured identity/lifetime, apply the mutation only to that owner's bucket, and assert again after the durable write. Use the `device` bucket only while the session controller has never been activated; after activation a missing/not-ready session blocks mutations. Device drafts do not automatically migrate into a newly acquired identity. Keep corrupt bytes, throw a recoverable typed read error and offer export/reset of artwork data only, never reset learning.

```dart
static Future<void> setDancheongStudioRawJsonStrict(String json, {
  PreferenceStringStore? preferences,
  void Function()? assertCurrentWrite,
}) => _ssStrict(dancheongStudioPreferenceKey, json,
    preferences: preferences, assertCurrentWrite: assertCurrentWrite);
```

- [ ] Finish creates a new immutable revision and removes only its matching draft after the single document write succeeds. Deleting the selected revision also clears its room reference in that same write. Never save optimistic state after a failed or stale write.
- [ ] Run store tests plus the existing local-reset/account-lifetime guards discovered by import-based test selection. Confirm resetAllStrict removes the new kl_ key. Leave changes uncommitted.

### Task 3: Original-art renderer and exact PNG output

**Files:** Create dancheong_renderer.dart, assets/illustrations/dancheong_studio/v1/manifest.json, tool/check_dancheong_studio_assets.py and test/dancheong/dancheong_renderer_test.dart; add the new directory to pubspec.yaml. Copy research originals only as template/example roles, with manifest provenance; do not copy the additional 10MB font because the app already has NotoSansKR.

**Interfaces:**

```dart
final class DancheongExportPackage {
  final String artworkId;
  final int revision;
  final DancheongFormat format;
  final Uint8List png;
  final int width;
  final int height;
  final DancheongComposition composition;
  final String sha256;
}
final class DancheongRenderer {
  Future<DancheongExportPackage> render(DancheongArtwork artwork,
      {required Set<String> ownedSlugs});
}
// Preview uses the same render operations at a scaled logical canvas.
class DancheongArtworkView extends StatelessWidget {
  const DancheongArtworkView({super.key,
    required DancheongComposition composition,
    required Set<String> ownedSlugs, bool example = false});
}
```

- [ ] Add real-font tests for portrait/story decoded PNG dimensions, source-asset missing failure, umlauts/Hangul/emoji/line breaks, and largest supported text. Include a read-only audit that compares source/copy bytes, PNG dimensions and hashes. Assets are original copied bytes; the output is a new rendered composition.

```dart
test('portrait output is an actual 1080 by 1350 PNG', () async {
  final composition = DancheongComposition(template: DancheongTemplate.brocade,
    format: DancheongFormat.portrait, motifSlugs: ['gwigap'],
    koreanText: '', translation: '', translationLocale: null, signature: '',
    templateVersion: 1, assetVersion: 1);
  final artwork = DancheongArtwork(id: '00000000-0000-4000-8000-000000000001',
    revision: 1, composition: composition,
    completedAt: DateTime.utc(2026, 10, 3));
  final result = await DancheongRenderer().render(artwork, ownedSlugs: {'gwigap'});
  final codec = await ui.instantiateImageCodec(result.png);
  final frame = await codec.getNextFrame();
  expect(frame.image.width, 1080);
  expect(frame.image.height, 1350);
  frame.image.dispose(); codec.dispose();
});
```

- [ ] Run the renderer tests and verify missing implementation failures.
- [ ] Use ui.PictureRecorder, ui.Canvas, immutable decoded images and TextPainter with the app's existing Korean font. Use a 1080-wide coordinate system; convert preview coordinates through a uniform scale. Flower uses one focal stamp (max min(nativeWidth,720)) and 8 small surrounds; brocade uses contained 240px tiles at 270px centers with alternating offset rows; letter reserves the upper 58% for the selected motif and lower 30% for optional text/signature. Text fits by decreasing the artwork font within the explicit 24–64px range, with wrapping inside 864px width; excessive text is rejected by the input limits, never ellipsized or silently cut from export. A blank-text artwork omits the text region and recenters its art.
- [ ] Validate every selected slug against ownership before asynchronous asset load and again before returning; the controller also fences identity after rendering. Asset failures produce a localized retry state and preserve drafts. Dispose images/codecs/pictures after exporting; no artificial loading delays.
- [ ] Copy flower.png/ribbon.png/pattern.png/letter.png from the recovered prototype with their original SHA-256 and role labels. Pattern/letter are examples only; fixed artwork text is labelled in example details. Do not promote phoenix/guardian or 12-study boards. The asset script checks 25 known motifs, native-size caps and source hashes.
- [ ] Run renderer/asset checks, inspect actual saved portrait/story PNGs at 100% and phone size, then retain the originals and evidence. Leave changes uncommitted.

### Task 4: Native DE/EN hub, editor and immutable artwork detail

**Files:** Create controller/routes/screens above and test/dancheong/dancheong_editor_test.dart; extract the present collection body into lib/widgets/sori/dojang_collection_body.dart; modify dojangcheop_screen.dart, main.dart and both lib/l10n/app_de.arb/app_en.arb, regenerate localization normally.

**Interfaces:**

```dart
enum DancheongStudioTab { patterns, artwork }
final class DancheongStudioArgs {
  const DancheongStudioArgs({this.tab = DancheongStudioTab.patterns,
    this.motifSlug});
  final DancheongStudioTab tab;
  final String? motifSlug;
}
final class DancheongEditorArgs {
  const DancheongEditorArgs({this.draftId, this.motifSlug, this.template});
  final String? draftId;
  final String? motifSlug;
  final DancheongTemplate? template;
}
final class DancheongArtworkArgs {
  const DancheongArtworkArgs({required this.artworkId, required this.revision});
  final String artworkId;
  final int revision;
}
final class DancheongController extends ChangeNotifier {
  DancheongController({required DancheongStore store});
  Future<void> open(DancheongEditorArgs arguments);
  void edit(DancheongComposition composition);
  Future<void> saveDraft();
  Future<DancheongArtwork> finish();
  Future<DancheongExportPackage> export(DancheongArtwork artwork);
}
```

- [ ] Widget tests load loadSoriRealFonts(), DE/EN at 360/390px and TextScaler.linear(2). Exercise zero/one/25 owned motifs, changing UI language after entering “안녕, Jürgen”, and identity change during rendering. No pumpAndSettle with idle Sori motion; use existing test/support/sori_stage_pump.dart.

```dart
testWidgets('large German labels reflow without dropping input', (tester) async {
  await tester.pumpWidget(MaterialApp(locale: const Locale('de'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
      child: child!),
    home: DancheongEditorScreen(arguments: DancheongEditorArgs(motifSlug: 'lotus'))));
  await tester.enterText(find.byKey(const ValueKey('dancheong-korean-text')), '안녕');
  expect(tester.takeException(), isNull);
  expect(find.text('안녕'), findsOneWidget);
});
```

- [ ] Run editor tests before the screens exist, then implement.
- [ ] Editor uses one scrollable Form: contained artwork preview, template choices, 4:5/9:16, owned motif choices, optional Korean text, optional translation/language and optional signature. No freehand editor, automatic AI personalization or drag-only controls. Visible labels and inline validation; save draft/finish buttons retain input while busy/error. Debounce draft writes 400ms; flush on save, navigation and lifecycle pause; call guarded store operations, not reward functions. Disable Finish until at least one owned valid motif is chosen.
- [ ] Hub labels: “Dancheong-Atelier / Dancheong Studio”, “Muster / Patterns”, “Kunstwerke / Artwork”. Detail actions: “Bearbeiten / Edit”, “Im Sarangbang zeigen / Display in Sarangbang”, “Teilen vorbereiten / Prepare to share”. Error/limit/missing-artwork/first-material labels go into both ARBs. Form max lengths are grapheme-based and preserve empty strings as a valid text-free composition.
- [ ] Extract Dojang's existing series rendering without changing its ordering, culture-help link, empty-state learning CTA or furnish CTA. Add a studio action; all old callers still use the old route. Typed new routes use SoriTransitions.page and SoriStandardFrame; preserve invalid-route/consent behavior.
- [ ] Run editor/model/store tests and Dojang regression tests. Check every copy key in both ARBs and no feature hard-coded product UI strings. Leave changes uncommitted.

### Task 5: Share package with durable captions and honest outcomes

**Files:** Create dancheong_share_service.dart and dancheong_share_screen.dart; test/dancheong/dancheong_share_test.dart. Existing ContentShareService is unchanged.

**Interfaces:**

```dart
enum DancheongShareOutcome { handedOff, dismissed, unavailable, failed }
DancheongShareOutcome mapDancheongShareStatus(ShareResultStatus status) =>
    switch (status) {
      ShareResultStatus.success => DancheongShareOutcome.handedOff,
      ShareResultStatus.dismissed => DancheongShareOutcome.dismissed,
      ShareResultStatus.unavailable => DancheongShareOutcome.unavailable,
    };
final class DancheongShareService {
  Future<DancheongShareOutcome> shareImage(DancheongExportPackage package,
      {required Rect sharePositionOrigin});
}
```

- [ ] Test caption restart, empty edited caption preservation, independent DE/EN captions, and all ShareResultStatus mappings. A share-sheet success means handed off, not an Instagram post. No reward or analytics achievement is generated for sharing.

```dart
expect(mapDancheongShareStatus(ShareResultStatus.dismissed),
    DancheongShareOutcome.dismissed);
expect(mapDancheongShareStatus(ShareResultStatus.unavailable),
    DancheongShareOutcome.unavailable);
expect(mapDancheongShareStatus(ShareResultStatus.success),
    DancheongShareOutcome.handedOff);
```

- [ ] Run share tests before implementation.
- [ ] Save captions by captionKey(artworkId, revision, format, locale); default generation runs only when the key is absent, including an intentionally saved empty string. Changing UI locale does not select caption locale. Provide separate image action and caption Copy; existing sharing evidence shows bundling image and caption can become text-only in receiver apps.

```dart
final result = await SharePlus.instance.share(ShareParams(
  files: [XFile.fromData(package.png, mimeType: 'image/png',
      name: 'hangul-sori-dancheong-${package.artworkId}-${package.revision}.png')],
  sharePositionOrigin: sharePositionOrigin,
));
```

- [ ] Map dismissed/unavailable/failed explicitly; on unavailable keep a file-save/download fallback supported by share_plus and caption Copy. Use unique revision-aware filenames and no dart:io/path_provider path on web. Never include localhost in copied captions. Public-page action is installed by Plan 2 only after its API exists and remains optional.
- [ ] Run share/store tests, verify actual received file dimensions, Korean glyphs and cancellation/return on Android/iOS when available. Browser verification does not substitute for native receiver evidence. Leave changes uncommitted.

### Task 6: Four approved app connections

**Files:** Create the three entry/display widgets; modify sori_stage_hanok_screen.dart (~collection shortcuts), sori_stage_today_screen.dart (~pending Bojagi section), sori_stage_reward_receipt_sheet.dart (~Continue button), sarangbang_screen.dart (~room scene) and test/dancheong/dancheong_connections_test.dart. Do not change reward receipt generation.

**Interfaces:**

```dart
String? confirmedOwnedReceiptMotif(RewardReceipt receipt, Set<String> owned);
// Looks only at SoriRewardKind.stamp items with a known owned identity.
// If multiple valid identities exist, show a picker or general studio entry.
```

Widget constructor contracts: DancheongEntryCard({Key? key, required DancheongStore store, required VoidCallback onOpen}); DancheongDraftResume({Key? key, required DancheongStore store, required ValueChanged<DancheongEditorArgs> onOpen}); SarangbangArtworkDisplay({Key? key, required DancheongStore store, required ValueChanged<DancheongArtworkArgs> onOpen}). Each reads only currentOwner(), contains its own localized load/missing-data state and navigates through the supplied callback. Screen constructors take `arguments` matching their route type; store/controller inputs are optionally injectable for tests.

- [ ] Integration tests snapshot XP/wallet/earned stamps/pending boxes/course state before and after opening studio, finishing work, room selection, export and share cancellation. Expect exact equality. Test count-only receipt and unowned identity return null; Today resume absent with zero drafts; corrupt room reference hides artwork and keeps study/furnish controls.

```dart
test('a count-only stamp receipt does not select lotus', () {
  final receipt = RewardReceipt(activityId: 'test', receiptId: 'receipt', items: [
    RewardReceiptItem(kind: SoriRewardKind.stamp, amount: 1,
      label: const SoriLocalizedCopy(de: 'Dojang', en: 'Dojang')),
  ]);
  expect(confirmedOwnedReceiptMotif(receipt, {'lotus'}), isNull);
});
```

- [ ] Run connection tests before adding UI hooks.
- [ ] Add a large contained-art card at Hanok's collection section with an actual saved-art preview if available, otherwise an explicitly labelled example. Returning to the existing IndexedStack tab refreshes artwork data without losing scroll position. Keep all four existing collection shortcuts and construction wallet.
- [ ] Add Today resume only for the newest current-owner saved draft, within the existing healthy-today branch after Bojagi. It is smaller than learning CTA; store errors hide only this secondary card.
- [ ] Receipt: known single owned identity opens editor with typed motif argument; unknown/count-only identity opens Patterns when tapped, never a fabricated selected motif. Close the sheet and then navigate through the owning Navigator, avoiding a disposed sheet context.
- [ ] Sarangbang: add one quiet framed section below the existing room scene. Its tap opens the exact saved immutable revision. Display selection does not create RoomLayoutItem, consume furnishing slots or alter room geometry; selection is persisted in the feature document. Deletion or failed artwork load yields a recoverable empty display and preserves room/study functionality.
- [ ] Run connection tests, existing Hanok/Today/receipt/Sarangbang route and reward regressions. Capture changed Today/Hanok roots through the repository's CAPTURE_SORI_STAGE_EVIDENCE workflow without replacing Linux goldens. Leave changes uncommitted.

### Task 7: Complete verification and integration review

**Files:** Current feature changes, relevant existing tests, generated root screenshots and asset manifest. No SESSION_LOG or manual handoff file.

**Interfaces:** Working DE/EN native routes and DancheongExportPackage are the output consumed by the public-sharing plan.

- [ ] Run `dart format` on owned Dart changes, `flutter gen-l10n`, targeted `flutter analyze` and all feature tests. Use `.github/scripts/select_flutter_tests.py` for affected existing tests; because localization/pubspec/assets changed, the repository's full Flutter suite is also required for final integration.
- [ ] Run `flutter build web` in this isolated worktree. Use a dedicated local port; preserve the recovered prototype server at 53756 and the texture session's processes.
- [ ] Use CUA to rehearse actual Flutter flows in DE/EN: Hanok → studio → one-motif composition → save → restart/resume → finish → room display → share → cancel/return. Inspect real artwork files and small-screen/200% text/reduced-motion/keyboard states. Do not run the old demo.cjs or claim prototype screenshots are Flutter evidence.
- [ ] Native receiver/share checks require an available device; report Android/iOS separately. No deployment or publication is part of this local review.
- [ ] Once Native or Subagent-driven execution has been selected, apply its required review workflow. Fix findings, rerun only affected checks, then update Graphify in this worktree. User must explicitly request commit/push/merge/deploy before those operations.

## Self-review and coverage

App placement → Task 6. Ownership/two series → Tasks 1/4/6. Three layouts and optional Hangul → Tasks 3/4. Restart/captions/room → Tasks 2/5/6. Actual PNG/share outcomes → Tasks 3/5/7. Identity/reset/corruption → Tasks 1/2/4/6. Public snapshot/visitor/withdrawal → separate 2026-10-03-dancheong-public-sharing.md plan. No product code or runtime asset has been changed by writing this plan.

The UI/UX Pro Max generic creative-page recommendation returned a Swiss/pink system that does not fit the approved Korean tactile app; it is not adopted or persisted. Its Flutter Form/Sliver/TextScaler and focus guidance do fit and are reflected in Tasks 4/7. No gallery-specific database match was found; gallery hierarchy follows the existing approved placement and Sori primitives. ui-styling applies to the visitor website, rather than imposing a web component library on Flutter. ui-demo's Discover/Rehearse discipline applies to review, but this environment provides no authorized video-recording browser API; screenshots and actual flow evidence remain distinct from a recording.

## Plan review

Recommend **Native**: the tasks share the same durable document, renderer and route interfaces, and another live session owns adjacent UI files. One implementing session reduces edit collisions; its final independent review still checks the complete result. Plan approval and execution-method selection are required by the explicitly invoked brainstorming/writing-plans skills before product implementation.
