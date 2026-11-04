# Approved Wörter-Quiz / Matching → Flutter

2026-11-04. Base `f369fe2ce3c36475e295b2369f0e5ae83939b867`; isolated branch `session/quiz-matching-figma-20261104`.

The two existing custom-pack game routes now render the user-approved editable Figma design with real text and real controls. This changes their presentation, not their pack IDs, SRS formats, first-attempt evidence, XP rules or result services. A/B/C are reference content-length compositions, not a new CEFR filter for personal packs.

## Authority and comparison

- [Approved Figma](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb?node-id=278-580), page `271:2`.
- Quiz A/B/C: `278:14`, `278:137`, `278:260`. Matching: `278:383`, `278:580`, `278:779`.
- Shared approved header `300:766`, including the user's 2026-11-04 Matching header override.
- `APPROVAL_20261104.json`, `FIGMA_GEOMETRY_FINAL.json`, `FIGMA_COMPONENTS_FINAL.json` and `ASSET_PROVENANCE.json` preserve the source and mapping.
- Original independent PNG bytes are hash-verified. Brass ornaments and matched check are exact Figma SVG exports. MaruBuriOTF Regular/SemiBold/Bold and Lora remain live fonts; no learning text is flattened into artwork.

| Reference | Figma | Flutter, 402×874 / DE / 100% |
|---|---|---|
| Quiz A | [reference](captures/quiz-a-figma.png) | [capture](captures/quiz-a-flutter.png) |
| Quiz B | [reference](captures/quiz-b-figma.png) | [capture](captures/quiz-b-flutter.png) |
| Quiz C | [reference](captures/quiz-c-figma.png) | [capture](captures/quiz-c-flutter.png) |
| Matching A | [reference](captures/matching-a-figma.png) | [capture](captures/matching-a-flutter.png) |
| Matching B | [reference](captures/matching-b-figma.png) | [capture](captures/matching-b-flutter.png) |
| Matching C | [reference](captures/matching-c-figma.png) | [capture](captures/matching-c-flutter.png) |

These six captures execute the production presentation widgets with explicit reference fixtures. Reference line breaks exist only in the visual-review entry point. The real routes measure arbitrary text and wrap Korean at word boundaries; they contain no per-word position/break lookup. This distinction prevents a reference screenshot from masquerading as all-content runtime proof.

## Components and behavior

`ApprovedGameFrame` retains SoriStudyFrame's leave contract and the five canonical image tabs. Visiting another tab pushes its shell while retaining the game route; Games returns to that route. Quiz pauses its existing 900ms advance timer when covered/backgrounded. Both games stop their owned speech on leave. Motion completion never grades or saves.

`GameArtwork` uses the approved crop, while `ApprovedMaterial` preserves corner caps and stretches the material interior. Visible artwork bounds and 48dp touch targets are independent. Press depth is 2dp/110ms, disabled under reduced motion. Correct/wrong/selected/matched states expose non-color semantics; completed pairs remain disabled in their original slots.

Longer text and 320px/200% type reflow and may scroll; they are not uniformly scaled, truncated or moved to another game's design. Default reference sizes preserve the approved six compositions. Photos attached to a real custom word remain supported and may increase content height.

At normal type on shorter native SafeArea viewports, measured decorative gaps and unused card space compress before any scrolling. The reference 402×874 composition and font sizes stay unchanged. Six additional full-frame cases cover the connected phone's logical 392.73×872.73 size with system insets and the 82dp navigation: all four Quiz answers or six Matching pairs remain directly tappable without scrolling. Quiz retains at least 56dp answer targets and 3dp shadow plus 16dp navigation clearance; Matching retains at least 48dp targets and 16dp clearance. The optional reduced-motion Weiter action can extend the scroll area without moving the answer rows.

At narrower native widths, Matching B measures its actual translation-column width and may use 16dp for a long German compound so its final character is not orphaned. The 402dp reference retains its original font choices; Matching C stays at least 18dp and Korean at least 21dp. There is no per-word layout lookup or content substitution.

## Verification

- 93 tests passed across approved Quiz/Matching rendering, Quiz lifecycle, existing custom-game UI/UX and SRS recovery suites.
- Two additional real-route push/pop tests passed for all four tab destinations, retained selection/question/answer and no duplicate evidence. The tests deliberately pop before mounting the heavy tab shell; full-shell Games-button interaction is not claimed by these tests.
- After the SafeArea adaptation, the 10-test Quiz view/lifecycle and 11-test Matching view suites passed, including six new full-frame cases. This brings the unique passing behavior/layout test count to 101; the broader unchanged service suites were not redundantly rerun.
- Six captures passed with loaded artwork and real fonts. Separate design review closed the background, selection-dot, vertical-text-alignment and downsampling defects. See `VISUAL_REVIEW.md`.
- Two additional production material-rendering regression tests passed at DPR1 and2.75, for 103 unique passing tests excluding capture harnesses.
- Scoped Dart analysis passed for the changed screens, widgets, tests and review gallery.
- Native device evidence is recorded separately in `NATIVE_REVIEW.md`; widget captures are not a device/store release claim.

Known visual residuals: renderer-dependent glyph edges/weight and occasional approximately 1px text differences. The internal material grid seams found during the final 2.75-DPR review were corrected by disabling destination-rectangle antialiasing while retaining original PNG alpha and texture filtering. The six final reference captures and six SafeArea captures were visually rechecked; see `SAFE_AREA_REVIEW.md`. No whole-screen percentage or 100% pixel-identity claim is made. No iOS device, TestFlight or Play release was performed by this change.

## Reproduction

```powershell
rtk proxy python -X utf8 tool/prepare_fontshare_fonts.py
rtk proxy flutter pub get
rtk proxy flutter gen-l10n
rtk proxy flutter test test/approved_quiz_view_test.dart test/approved_matching_view_test.dart test/approved_quiz_lifecycle_test.dart test/custom_pack_games_uiux_test.dart test/custom_pack_srs_recovery_test.dart test/approved_game_navigation_test.dart
rtk proxy flutter test test/goldens/approved_game_capture_test.dart --dart-define=CAPTURE_APPROVED_GAMES=<absolute-output-directory>
rtk proxy flutter test test/goldens/approved_game_safearea_capture_test.dart --dart-define=CAPTURE_APPROVED_GAMES=<different-absolute-output-directory>
```

The review gallery is `tool/visual_review/approved_game_gallery.dart`, with `APPROVED_GAME_FIXTURE=0..5`. It is never imported by application main. Its initial screens are presentation fixtures, not seeded user progress.

## Applied design decisions and sources

Figma design-to-code and UI UX Designer component/motion skills were applied to source-to-widget mapping, measured text, independent face/hit geometry and state-owned effects. Mobile/accessibility/critique review found and corrected real defects rather than merely listing skills.

Official references checked 2026-11-04: [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps) for 48dp targets and useful semantics; [Android animation selection](https://developer.android.com/develop/ui/compose/animation/choose-api) for state-coordinated, bounded feedback; [Flutter FilterQuality](https://api.flutter.dev/flutter/dart-ui/FilterQuality.html) for strong-minification sampling. Mipmaps smooth normally scaled art; anisotropic stretch strips use bicubic sampling and explicit clip bounds to avoid sampling adjacent crop regions. Platform guidance informs behavior while preserving approved jade, hanji and brass materials.

[Flutter Paint.isAntiAlias](https://api.flutter.dev/flutter/dart-ui/Paint/isAntiAlias.html) confirms that image-edge antialiasing defaults to true. Isolated same-canvas tests distinguished this from clipping and proved that it caused the internal coverage gaps. The fix preserves all approved crop coordinates and asset bytes.
