# Mother-of-pearl reward chest preview

A standalone Flutter reward-motion study, not a production reward route.
The existing app's reward service, reward ownership and XP writes are unchanged.
No Dokkaebi image, pose sequence or video is loaded by this preview.

## Preview

Run `tool/reward_chest_preview/main.dart` instead of `lib/main.dart`.
The background is light-only and the UI uses the app's DE/EN ARBs and NotoSansKR.

- `lang=de` / `lang=en`: preview language.
- `at=0.76`: freeze a native animation frame.
- `blue=0`: retained pearl/gold-only comparison. By default, blue light is on.
- The legacy `guide=1` URL no longer adds a mascot.

The original chest PNGs remain unchanged. A short asymmetric blue light accent
uses the same reveal clock and blends toward silver/gold behind the chest.
The reward follows one flight above the lid; the chest exits at 1.60–2.08s.
The raised-paper receipt and gold action then reveal the item and current XP.
XP/level numbers in the standalone demo are illustrative (1,280 / 13 / 20),
not a new award. Placement only displays a preview confirmation.

The cultural action uses the approved paired wording:
`Die Geschichte dahinter` / `The story behind it`.
It opens the app's existing localized cultural-help sheet.

## Responsive and motion policy

The receipt has a landscape two-column layout and compact height modes.
Normal tested mobile/tablet sizes fit without scrolling. Extreme system text
sizes retain an accessible scroll fallback rather than clip words.
Reduced motion bypasses the reveal and presents the final item receipt.
Native alpha-bound-aware item fitting is not yet implemented.

`design/index.html` is a separate receipt design proposal, not the Flutter
implementation. It measures visible PNG bounds and offers a raised-paper popup.
Its editorial Georgia title is a system-font placeholder; `type=app` uses the
existing app font. Serve the repository root to use the local assets/ARB/catalog.

## Verify and build

```powershell
flutter gen-l10n
flutter test --no-pub test/reward_chest_preview_test.dart test/arb_l10n_guard_test.dart test/l10n_parity_test.dart test/cultural_glossary_catalog_test.dart
flutter build web --no-pub --target tool/reward_chest_preview/main.dart --output build/reward_chest_blue_web --no-wasm-dry-run
python -m http.server 8222 --bind 127.0.0.1 --directory build/reward_chest_blue_web
```

`test/reward_chest_preview_test.dart` registers the standalone preview tests in
normal app CI. To capture fresh mascot-free evidence, pass
`--dart-define=CAPTURE_GUIDE_FRAMES=true`; outputs use `frames/blue_*` names.
Tested sizes include 320×568, 375×667, 430×900, 568×320, 844×390 and 768×1024.
Real Android/iOS frame-time profiling, real reward-data integration, and a
Dokkaebi video introduction require separate implementation and approval.
