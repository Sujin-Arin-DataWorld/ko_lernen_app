# Wortkette verification, 2026-11-04

Checkout: `quiz-matching-figma-20261104`, based on `b11c7ef838e6f18be72d7bed5404589c158d2b8f`. These results concern this change, not a store build or a physical installation.

## Final automated runs

1. `flutter test --no-pub test/approved_word_chain_lifecycle_test.dart test/approved_word_chain_view_test.dart test/timed_game_srs_recovery_test.dart test/custom_pack_kkeunmari_test.dart --concurrency=1`
   - **88 passed**, complete owner-run log: `final-regression.log`.
   - Covers 11 new lifecycle cases, 15 presentation cases and 62 existing timed-recovery/custom-selection cases. Deliberately injected storage/network errors appear in the log; the corresponding recovery assertions pass.
2. Following the final empty-input typography fix: `flutter test --no-pub test/approved_word_chain_view_test.dart test/goldens/approved_word_chain_capture_test.dart --concurrency=1 --dart-define=CAPTURE_APPROVED_WORD_CHAIN=<artifact>/flutter-capture`
   - **16 passed**. Only the empty input's text metrics changed after the 88-test run; filled B/C PNG hashes stayed identical. See `placeholder-baseline-tests.log` and `FLUTTER_VALIDATION_RECEIPT.json`.
3. Scoped `flutter analyze --no-pub` on the eight changed Dart targets: **no issues**. After the empty-input follow-up, analysis of that changed production file also found **no issues**. Logs: `flutter-analyze-final.log` and `placeholder-baseline-analyze.log`.

The presentation tests load actual fonts, assert the three reference tile rectangles and CTA rectangle, check a native-sized safe-area configuration, a real IME, keyboard focus/visibility, 320px/200% content stress, all twenty permitted input characters and fractional playback speed labels. They do not establish every possible device/font setting.

## Render comparison

Figma and Flutter captures use the same 402×874 viewport, German labels, 100% text, zero safe-area insets and A/B/C fixture values. Flutter captures render the **production presentation widget** with explicit fixture data; they do not pretend to be saved learner progress. `KkeunmariScreen` uses this same widget with its real controller, services and state.

- `captures/figma-{a,b,c}.png` and `captures/flutter-{a,b,c}.png`
- `FLUTTER_CAPTURE_MANIFEST.json`: source, view settings and hashes.
- `RENDER_COMPARISON.json`: region-level pixel differences. The figures are diagnostics, not an arbitrary approval score or evidence of pixel identity.
- `FIGMA_VISUAL_REVIEW.md`: independent static review of both reference→Figma and Figma→Flutter, with remaining typography/material differences explicitly listed.

Measured corrections include C tile occupancy, the use of the exact Figma action material for Senden, removal of duplicated button shadows, history-card minimum widths and A placeholder baseline. The last correction changed an empty TextField's metrics from Korean 46px to the actual Lora SemiBold 24px hint style; its visible ink now matches Figma y657–674. It uses no positional transform or image text.

Reference submit bounds are (28,713,346,56), leaving 23dp before navigation y792. Safe-area tests assert at least 16dp between the complete target and the dock. No functional callback is invoked by an animation completion.

## Review and preservation

`INDEPENDENT_CODE_REVIEW.json` records a separate review. Its offscreen feedback finding was fixed: dictionary/SRS/result completions can retain valid state and persistence while covered, but cannot emit their transient sound/haptics there. New tests cover that boundary. Existing XP formulas, custom pool restrictions, SRS writes, completion and retry behavior remain in the original screen/engine.

The Figma→Flutter material map uses the same six standalone asset bytes and measured slices. The optional `ApprovedArtButton.castShadow` defaults to true, so other games retain their existing behavior. Only Wortkette disables the extra shadow where its artwork already contains it.

## Explicit remaining boundaries

- Physical-device validation was deferred by the user. No APK install, device QA, store upload, push or merge occurred in this task.
- This is not a claim of 100% pixel identity with image-generated mockups. Font rasterization, generated reference letter shapes and some material-lighting differences remain documented.
- User approval of the source mockups is recorded separately from Figma/native implementation evidence.
- Next-content Silben-Rätsel work is a source-grounded research brief and fixtures, not a new approved mockup or runtime implementation.
