# Hören: canonical UI and recovery footer

User authority: 2026-11-03 attachment approval. Exact source bytes and SHA-256 are in `docs/assets/CANONICAL_UI_20261103.json`. Cloud, settings and front Yeopjeon must be imported independently, never redrawn by image generation. The cloud in the earlier Grammatik raster was an inherited generated approximation and is superseded. Existing neutral Du/Service role art stays unchanged.

## Layout contract

- Reading action: at least 48dp high. Its entire hit region ends at least 16dp before navigation begins.
- Footer actions and image-only five-tab navigation are sequential layout children, not overlapping positioned surfaces. Navigation owns its bottom safe area.
- On short screens and with large text, recovery content scrolls within its bounded region; navigation and the 16dp separator remain outside that scroll region.
- Figma audio recovery `56:152`: action/navigation auto-layout `83:66`, read action `56:194`, navigation `56:168`; measured separation 16dp.
- Figma canonical originals board `83:67`. Grammatik reference board `85:66` contains raster mockups plus the exact separate cloud PNG. These references are not editable Grammatik UI or runtime implementation.

## Motion decisions

Official guidance checked on 2026-11-03:

- [Material motion](https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md): shared semantic motion values, size/distance-appropriate transitions, distinct spatial and effect responses.
- [Apple Reduced Motion criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria): remove or adapt depth/scale/spin triggers while preserving understandable state feedback.

| Element / trigger | Applied behavior | Reduced motion / ownership |
| --- | --- | --- |
| Gold primary action / pointer down | 150ms press, 2.25dp face depth; no glyph scaling | Position stays fixed; normal action still fires once |
| Pointer release / cancel | 250ms gentle return, no repeated spring oscillation | Immediate stable face; does not delay callback |
| Dialogue / actual audio playback | Existing active surface and speaker signal; role icon rises 2px only while active | Static active cue; authored voice and source line unchanged |
| Translation / explicit disclosure | Existing 220ms reveal; no ambient text motion | Immediate disclosure; same content |
| Save pending / actual persistence | Existing progress state and disabled retry while operation owns the write | Static progress indication; no invented success or reward |
| Route departure / app background | Existing audio generation invalidation and stop | No background playback-driven role movement |

UI UX Designer microinteractions-motion supplied the trigger/feedback/reduced-motion review. The motion-foundations skill's semantic-token and accessibility principles informed the review; its React APIs are not applicable to Flutter. Existing Flutter SoriMotion/SoriPressable are reused.

Evidence: `C:/dev/hangulsori/_codex_artifacts/horen-c-states-20261103/chrome-footer-revision/` contains native widget captures, 75-test log, analysis/build results, Figma exports and the machine-readable verification snapshot. Tests cover 402×874 and 320×640 at 100%, 320×874 at 200%, 34dp bottom safe area, hit testing, unchanged reading cursor and press/reduced-motion positions. These are Flutter widget renders and tests, not iPhone 227 or deployed Android device QA.
