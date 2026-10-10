# Living C design contract · 2026-10-10

Applies to this reward implementation and subsequent Hangul Sori app work.
The persistent workspace rules are in `C:/dev/AGENTS.md`.

## Authority and skills

Reference family: the user's October 2–10 generated images, especially
`01a11bd6-c610-7ee3-9a04-1ce616508896`. The audit contains 596 files,
555 unique hashes and 24 viewed contact sheets, plus selected full-size boards.
This establishes a visual direction, not approval of every generated asset.

Read and apply skills at their relevant stage: user-flows and information-
architecture for state/next action; layout-grid-hierarchy and mobile-app-ui for
fit; design-system-builder and ui-styling for materials and typography;
motion-foundations/advanced for feedback and lifecycle; ux-audit-critique and
accessibility-audit for actual render review. Skill names alone are not QA.

Three independent AI designer roles review materials/CTA, mobile layout/
accessibility, and movie/motion. Source checks and geometry do not approve
internal texture seams or a visibly broken surface.

## Materials, hierarchy and depth

Preserve original jade, hanji, gold coin, red seal and carved CTA PNGs.
The source, packaged and native copies must have identical SHA-256 values.
Text remains live Paperlogy text, never rasterized labels.

| Component | Rules |
|---|---|
| Main paper pane | 16dp radius, warm upper rim, 6dp bronze side and soft contact shadow |
| Goal card | 8dp radius, opaque warm hanji face, shallow inset edge and contact shadow |
| Wallet | 48dp target where interactive; 3dp side; read-only on the house route |
| Primary CTA | 54dp minimum, gold, 3dp depth, 16sp live label |
| Secondary CTA | 48dp minimum, jade, 1.5dp depth, 16sp live label |
| Touch feedback | Scoped .988 press scale, 80ms contact, 240ms damped return; surface and shadow move together |
| Typography | Title24, earned44, section18, goal15, body14, controls12 + icons18; subtle title relief only |

These are an adaptation of [Apple's official material/light/touch principles](https://developer.apple.com/videos/play/wwdc2025/219/)
to the approved C materials, not a claim that every 2026 app uses this style.

All CTA heights use the same continuous interior, even-odd outer ring and
separately clipped fixed-size cloud. Height is measured from the actual layout,
not locale or a QA CSS class. The original cap textures remain unchanged. Never stretch the narrow
strip containing an inner bevel: that produced the rejected vertical smear
and duplicate middle border. HTML uses one SVG root; Flutter one canvas.

## Fit and accessibility

Normal review is100% text in German and English. Standalone HTML has an exact
402×874 canvas, with62/34 review-only system areas; browser window size must not
change the internal phone geometry. Flutter uses actual platform SafeArea.
The reward event is220 movie +8 gap +112 earned amount. Its card has a natural
height. Related content4–8dp, groups12–16dp, CTA gap8dp; actions remain48dp or taller.
No production replay/motion row is shown. Those controls belong to Review/Playback QA,
and removal must preserve automatic playback and null-safe control references.
The reason starts4dp below the earning event.

The full original960×960 movie is contained without crop or perspective.
Large text remains real TextScaler text and is marked as accessibility QA;
vertical scrolling is allowed there to keep actions readable and reachable.
Do not shrink enlarged text to simulate a normal one-screen result.

## Movie, reward and flow

Original movie RGB is preserved. Matting changes alpha only, including soft
edges; no saturation, grayscale, white-spill RGB correction or brightness
grading. Native WebP is encoded directly from original decoded RGBA and all
121 frames are compared. Browser VP9 has ordinary YUV/codec differences.
No video or ancestor receives a disabled-button color filter. A no-store
review server prevents stale CSS/media from masking repairs.

Movie →3.583s wand cue → fixed earned amount +0 to confirmed value and wallet-local +/++ and90ms number rolls →840ms confirmed
balance progression →200ms rim settlement. The goal bar uses the same
presentation clock and actual before/after ratio; a sufficient balance does
not animate fake progress. Replay is presentation only.
Do not fly coins across the page, grant fake credit, or write wallet state
from an animation callback. Offscreen/background and reduced-motion states
stop playback and expose the same confirmed result. Native watchdog measures
a stalled decode, not total movie length, so continuing slow playback can finish.

Reward → visit house → explicit40-coin before/after confirmation → service
result → confirmed wallet and next learning action. Preserve account ownership,
in-flight locks, unknown-result behavior and other reward routes.

The house question precedes the coin scene. Its central coin and elliptical
contact shadow share one finite 520ms landing/touch response. Decorative idle
loops are removed; motion concentrates on acting, earning and pressing.

Future house forms remain secret. The Hanok catalogue is empty while canonical
assets are replaced; no Sarangchae label, fabric mystery image, stage total or
future gallery is introduced.

## Completion gate

Inspect actual100% DE/EN and real200% renders, including the inside of both
CTAs, long confirmation text, original-color playing movie, full frame,
connected flow, control targets, spacing and touch response. Rerun relevant
tests after changes. Report physical-device performance/audio/haptics and
human approval separately from browser/Flutter-widget review.
