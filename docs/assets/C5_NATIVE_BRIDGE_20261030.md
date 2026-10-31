# C5 native presentation bridge

Current presentation, updated 2026-10-31: main C5 scenes now use the six
standalone originals in `C5_SCENE_ORIGINALS_20261030.json`, with native localized
text and current action/state owners. The earlier image-crop adapter below is
historical intake context, not the current main-tab scene source. Approved R16
Sarangchae uses its separate foreground/multiply-shadow catalog; no white studio
background or generic parent fade is substituted.

The latest responsive/motion batch passed 133 checks: DE/EN at 320x640,
375x667, 390x844, 393x873 and 430x932, normal/enlarged text, OS-inset states,
native launch/return behavior, wallet persistence and shared guard tests.
The dedicated six-case material-feedback tests cover rapid reversal, native
one-tap activation, unchanged input bounds, immediate confirmed balance text,
reduced motion, hidden routes and background settling. These are native widget
checks; physical iPhone/Android QA and store availability remain separate.

Selected-card rims interpolate for 180ms, CTA lighting/direction use the shared
150ms token, and confirmed wallet changes receive one 250ms neutral rim cue.
Initial wallet reads and repeated snapshots stay quiet; no count-up values,
reward claims or repeated decorative loops are introduced. All settled artwork,
text and layout remain the approved composition.

Design sources checked 2026-10-31: Flutter's
[safe areas](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery)
and [constraint-driven layout](https://docs.flutter.dev/ui/adaptive-responsive/general),
and Google's current
[expressive motion direction](https://blog.google/products-and-platforms/platforms/android/material-3-expressive-android-wearos-launch/).
The Google article was published in May 2025; these are current references
checked in 2026, not a claim that every technique originated in 2026. The
application keeps its pinned Flutter SDK and C materials.

Three intentional Today layout baselines use untouched actual Linux test
renders from CI run `41154239532`, source `83f95f8c3`; their final exact-head
pixel comparison is still mandatory. The typography in those layout goldens
is Ahem, while the 28 separate native C5/R16 presentation captures use bundled
locale fonts. Neither set is physical-device evidence.

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
remediation, the root/chrome/native-capture batch passed 24/24. That earlier
batch's 16 real-font PNGs and measurements are under
`C:/dev/hangulsori/_codex_artifacts/einleitung-device-fit-20261029/ci-c5-number-contrast/`;
the run log is `ci-root-chrome-final.log` in the parent directory. These cover
DE/EN, 320x640 and 393x873, 100/200 percent text, and 24dp top/bottom OS
insets. All eight normal configurations have zero scroll extent and an 8dp
gap before navigation. Fully painted 48dp Details controls, keyboard reflow,
All/close/back restoration and existing activity IDs remain verified.

The selected first-step marker uses the existing deep-jade face, paper
bold numeral and brass edge. Its earlier text-contrast check passes
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
in the intake JSON. The earlier pre-spacing changed-Dart analysis scope and output
are `ci-source-freeze-analyze.json` and `ci-source-freeze-analyze.log` under
the same artifact parent directory. All 44 changed Dart files analyzed with
no issues; their SHA-256 values were unchanged during analysis. This metadata
refresh does not edit
product source or execute Flutter tests.

The latest spacing revision replaces fixed-height tile filler and expanding
hero space with natural content heights and a loose artwork bound. Related
art/text uses 4dp; normal groups use 8/12dp, with compact adaptations to preserve
the fold. The overview is at most 480dp wide, while artwork keeps its 3:2 ratio
and a 180dp normal / 150dp enlarged upper bound. At 393dp, Lernen's board is
506dp rather than 561dp, category faces are 80dp rather than 104dp, inner
top/bottom space is 5dp rather than 14dp, and the adjacent primary/All gap is
9dp rather than 17dp. Spare room remains outside the content instead of
stretching cards or text. Current activity IDs, state and action owners remain.

The latest catalog batch passed 25/25 checks, with 24 actual-font PNGs under
`C:/dev/hangulsori/_codex_artifacts/einleitung-device-fit-20261029/spacing-catalog-after/`.
It covers DE/EN, 320x640, 393x873 and 1280x900, 100/200 percent text and 24dp
top/bottom OS insets, plus keyboard reflow. All 12 normal configurations have
zero scroll extent. Native 48dp targets, fully painted Details, current
course/game launches and All/close/back offset restoration remain checked.
The log is `spacing-catalog-aa-after.log` in the parent artifact directory.

The AA screen matrix passed 45/45 checks and its paint-verification regressions
passed 8/8 in `aa-native-threshold-proof.log`. The helper runs Flutter's native
guideline first. A reported failure is mapped to its actual RenderParagraph;
the required ratio is `max(nativeReported, SDKstyleTarget)`, retaining the same
4.5 normal / 3.0 large criteria and never lowering a reported 4.5 to 3.0.
Proof requires actual opaque ink cores and the material directly under painted
glyphs, with no frame/time advance and byte-identical restored RGBA. Unknown,
unsupported, mixed, translucent, missing-paint or restoration failures retain
the original failure. The same 18dp test text has measured contrast 3.5668:
reported 3.0 passes and reported 4.5 fails. The three locally adjudicated labels
have minimum ratios 14.5528, 13.8138 and 5.2052 at unchanged 4.5 requirements;
individual PNGs, resolved styles and per-node proof JSONs are under
`aa-native-threshold-proof/`. Consent/Gye's native checks pass locally; their
earlier Linux-only histogram failures remain for exact-head CI verification.

The final Gye capture fixture uses the actual `cafe_order` definition,
schema version 1, target 3 and saved progress 3 (four members). The capture's
schema unit checks the canonical ID/target and bounded progress. Viewing this
explicit saved snapshot does not earn a light or write reward state. The
23-check docs capture/schema run passed in `spacing-roots-evidence-final.log`;
the DE/EN Gye PNGs in `docs/screenshots/` show this three-light state.
The separate partial-progress matrix uses saved progress 1 of that same actual
target 3. Its schema/viewport/OS-inset checks passed 17/17 in
`C:/dev/hangulsori/_codex_artifacts/native-design-review-20261030/spacing-0eaaf0cce/real-promise-run.log`;
DE/EN, 320/393dp and 100/200 percent partial-state PNGs are under that run's
`after-root-real/`. These are additional 1/3 checks; the final docs gallery
uses the distinct 3/3 saved state.

The final post-format WIP analysis covers 23 Dart files, including all four
untracked Dart files. `spacing-final-wip-dart-analyze.json` and `.log` record
no issues and identical before/after SHA-256 values, file scope and HEAD
`0eaaf0cce102598606c5d9db03a1c779ea5c937f`. Before the accepted snapshot, root
requested only `dart format test/c_today_spacing_test.dart`; it changed
formatting in one file. This refresh otherwise changes metadata only and runs
no Flutter tests. `spacing-aa-final-report.json` links the final scope, capture
and contrast evidence. Whole-PR CI, exact-APK/device checks and release remain
separate evidence.
