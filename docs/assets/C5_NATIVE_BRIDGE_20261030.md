# C5 native presentation bridge

Source: the existing dirty `c-app-integration-20261012` checkout at
`2d68784d3b642a14fe174de26d55b0c82209a694`. It was read without modification.
Per-file and asset hashes are in [the intake record](C5_KERNEL_INTAKE_20261030.json).
The source's business services and extra routes were not imported.

The five shared presentation files are:

- `lib/widgets/sori/approved_figma_scene.dart`
- `lib/screens/sori_stage/c_stage_chrome.dart`
- `lib/widgets/sori/c_gallery/c_materials.dart`
- `lib/widgets/sori/c_gallery/c_objects.dart`
- `lib/widgets/sori/c_gallery/c_palette.dart`

`ApprovedFigmaScene` retains `scene`, `top`, `bottom`, `text`, `hidden`,
`replacements`, `actions` and `includeBackground`. Use the five existing scene
JSON files under `assets/illustrations/concept_c/approved_20261018/`. Bind
localized text and real state explicitly. Crop out the original header/nav
regions when the current native header/nav already supplies them. A scene does
not create or save progression, rewards, wallet amounts or activity ownership.

Native text keeps its semantic size (at least 16) and uses the current locale
fonts; measured extra height moves subsequent rows. `maxHeight` is an optional
normal-size viewport budget that compresses artwork and spacing, preserving
native text and 48dp action faces. Leave it unset for accessibility scaling so
the scene can scroll naturally. Check the actual capture: the height budget
cannot make intrinsically oversized native content disappear.

The catalog uses `C5CatalogOverview`, a native reflow of the original three
steps/book/four categories and game hero/six objects/own-words composition.
`ApprovedFigmaArt` reads the exact image crop from the original JSON for the
learning objects. Native layout budgets compress decorative art rather than
squashing the complete scene. Body labels remain 16sp, primary/category/All
actions retain 48dp targets, and enlarged text changes to full-width rows.
The actual current unit title is native text, and the original Silben hero
opens the existing `syllable_cross` activity. The existing personalized recent
recommendation remains in the complete catalog.

`FigmaSceneAction(Rect, label, callback, {key})` connects an existing action;
artwork and labels stay inside its common `CImageTap` pressure owner. Callbacks
are immediate. Do not create a second navigation or reward handler.

`CStageBackground`, `CPaperPanel`, `CMaterialAction`, `CTexture`, `CAtlasArt`,
`CReferenceArt` and `CGameReferenceArt` are presentation widgets. Text helpers
are `cStageTitle(context)`, `cStageCardTitle(context)`, `cStageBody(context)` and
`cMaterialText(style, context: context, heading: optionalRole)`.

Keep the current `SoriRootHeader`/Today header and native shell navigator.
`CStageHeader`, when used in an isolated presentation, delegates to the current
`SoriTopChrome`; its legacy integer `balance` argument never constructs or
overrides a wallet. Current confirmed `SoriWalletScope` state remains the owner.
The optional wallet-return callback preserves the existing screen refresh.

`CObject` cloud/coin/settings/book and the scene image map use the latest
`ApprovedChromeAssets`. `CLantern(lit: ...)` uses the approved lit/off originals,
not a simulated color filter. English uses Chubbo/Supreme, German uses
Belgrano/Encode Sans Condensed, and Korean keeps Noto Sans KR fallback.

Shared `SoriStandardFrame/Page`, `SoriCard`, `SoriButton` and `DojangcheopScreen`
gain optional C material inputs; their defaults and existing action/state owners
remain. Fontshare preparation is documented in [the font guide](../../assets/fonts/README.md).

Lernen/Spiele open the full existing catalog through localized native All
buttons. Closing or system back restores the overview and its scroll offset.
Inactive tabs do not intercept system back. Full catalog start/details, lock,
book choice, recommendation, CEFR and no-extra-reward contracts remain current.

The adaptive rail uses Flutter's `scrollable` option with its own primary
scroll scope, keeping all five destinations reachable in short landscape
without attaching the rail to the catalog controller. This follows
[the official NavigationRail API](https://api.flutter.dev/flutter/material/NavigationRail/scrollable.html),
checked 2026-10-30. The source/layout comparison and captures use real bundled
DE/EN fonts; PNG evidence and viewport measurements live under
`C:/dev/hangulsori/_codex_artifacts/c5-native-integration-20261030/catalog/`.

Native widget captures, live Figma edits, device/APK checks and release evidence
are separate checks. This intake does not claim global pixel parity or release
completion.

The initial kernel/catalog integration passed 73/73 checks. After full-CI
remediation, the final root/chrome/native-capture batch passed 24/24. Its
current 16 real-font PNGs and measurements are under
`C:/dev/hangulsori/_codex_artifacts/einleitung-device-fit-20261029/ci-c5-number-contrast/`;
the run log is `ci-root-chrome-final.log` in the parent directory. These cover
DE/EN, 320x640 and 393x873, 100/200 percent text, and 24dp top/bottom OS
insets. All eight normal configurations have zero scroll extent and an 8dp
gap before navigation. Fully painted 48dp Details controls, keyboard reflow,
All/close/back restoration and existing activity IDs remain verified.

The selected first-step marker now uses the existing deep-jade face, paper
bold numeral and brass edge. The unchanged text-contrast guideline passes
with actual fonts. Six UI-measurement hosts load the bundled locale fonts
instead of Ahem; their overflow, 48dp target, labels and contrast assertions
remain. Current Gye schema checks validate translated server-derived counts
and exact lit/target lantern state.

Shared-card paint values remain unchanged. `SoriCard.resolvedBorder` supplies
the same border to painting and fixed-grid measurement. Persona text layout
subtracts its actual horizontal dimensions and includes the vertical
dimensions, retaining the 180dp portrait, font roles and touch targets.
The existing 12-case Persona light/dark viewport matrix and five adjacent
selection/interaction checks passed without test changes.

Current adapter SHA-256 values and individual verification logs are recorded
in the intake JSON. The final changed-Dart analysis scope and complete output
are `ci-source-freeze-analyze.json` and `ci-source-freeze-analyze.log` under
the same artifact parent directory. All 44 changed Dart files analyzed with
no issues; their SHA-256 values were unchanged during analysis. This metadata
refresh does not edit
product source or execute Flutter tests. Whole-PR CI, exact-APK/device checks
and release remain separate evidence.
