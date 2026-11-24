# Meine Wörter / Karten — approved five-tab footer

2026-11-04. The Karten mockups titled Meine Wörter map to `CustomPackPlayScreen`, route `/custom_pack/play`. The separate `/my_words` search/shelf/difficult-words hub is unchanged.

The production card screen now uses the same `ApprovedGameNavigation` as Wörter-Quiz. Source: [Figma footer 278:112](https://www.figma.com/design/7IHizFZMk5G3ahsuVKiYwb?node-id=278-112), inside approved Quiz A `278:14`. No new Figma layout or mockup image was generated for this change. The card body remains its existing implementation; this is not a claim that the complete Karten image mockup has been implemented.

The user's four newly supplied navigation PNGs in `공통UI정본` are byte-identical to the existing approved calendar, games, Hanok and people assets. The approved open-book PNG remains the fifth icon. Original sources, SHA-256 values, Figma geometry and comparison results are in [PROVENANCE.json](PROVENANCE.json).

At 402×874, the footer is 402×82 at y=792. The entire RGB footer region of both [front](captures/karten-front-footer.png) and [back](captures/karten-back-footer.png) production-widget captures is identical to the approved Quiz A Flutter footer. The latter's Figma comparison is recorded in `../approved_quiz_matching_20261104/`. This verifies the footer, not whole-screen parity.

The shared tab visit preserves the existing card route. Flip, romanization and grading state survive return. New input from a covered card is rejected, while an already accepted save completes once. Current Games selection does not restart the card. Owned TTS is stopped by the existing shared visit behavior.

Validation: four new navigation/geometry/state/race tests and fourteen existing play-recovery tests passed in the final run. Five existing flip-gate and two Quiz/Matching navigation tests also passed. Scoped static analysis passed. The 320×640/200% test verifies SafeArea and at least 48dp tab targets. Route tests push and pop before building unrelated tab-root loaders, so they are not full-shell end-to-end evidence.

Physical-device verification was deferred at the user's request; no device installation, store upload or release was performed.

Reproduce: `flutter test test/custom_pack_navigation_test.dart`; optional capture define: `--dart-define=CAPTURE_KARTEN_NAVIGATION=<absolute output directory>`.
