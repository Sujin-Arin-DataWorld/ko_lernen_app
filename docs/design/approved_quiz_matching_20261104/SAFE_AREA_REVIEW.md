# SafeArea widget-render QA — 2026-11-04

Production ApprovedGameFrame and Quiz/Matching view widgets, rendered at 1080x2400 pixels, density 2.75 (392.727x872.727dp), German, text 100%. System-inset reservations: top 27dp / bottom 54dp; app navigation 82dp. Body available 709.727dp.

These are Flutter widget-render captures with actual production frame/navigation, not screenshots of Android system UI. Gallery input strings retain approved Figma line-break overrides. Gameplay, SRS and persistence are tested separately.

## Result

All six captures passed zero-scroll, minimum 48dp target, and minimum 16dp final-target-to-navigation assertions. Visual inspection found no clipped or overlapping learning text or controls after the text-width fix. Quiz C topic/score spacing is tight but text remains distinct. The internal material slice grid was corrected with Paint.isAntiAlias=false and clipRect(doAntiAlias:false); final captures show clean paper, counters, jade controls and selected tiles.

| Fixture | Minimum target height (dp) | Final target to nav (dp) | Scroll (dp) |
|---|---:|---:|---:|
| quiz-a-safe-area-flutter.png | 56.932 | 19.000 | 0.000 |
| quiz-b-safe-area-flutter.png | 59.992 | 19.000 | 0.000 |
| quiz-c-safe-area-flutter.png | 58.682 | 19.000 | 0.000 |
| matching-a-safe-area-flutter.png | 52.885 | 64.885 | 0.000 |
| matching-b-safe-area-flutter.png | 60.474 | 53.371 | 0.000 |
| matching-c-safe-area-flutter.png | 60.457 | 46.000 | 0.000 |

## Matching width correction

At 392.727dp, the previous reference-width font measurement orphaned the final t of Eigentümergemeinschaft. Font selection now measures the smaller of actual/reference column widths; only narrower B columns can use the 16dp fallback. The 402dp reference composition and fonts remain unchanged. The rendered word is now one line; a new native-width test checks complete compound glyph boxes occupy one line.

matching-b-before-width-fix.png preserves the defect. The six *-safe-area-flutter.png files and CAPTURE_MANIFEST.json are the post-fix results.

Validation: all 11 approved_matching_view_test.dart tests passed, including 402dp reference positions and 320dp/200% reflow. Scoped dart analyze and git diff --check passed. The six-frame capture test passed after the correction.

## Material seam follow-up

The clip flag alone left internal lines visible. After Paint.isAntiAlias=false was also applied, all six captures passed the same fit/target/navigation-clearance assertions. Quiz C and Matching B were inspected at original 1080x2400 resolution, and the remaining four captures were visually checked. The straight internal grid lines are gone; no text/control clipping or overlap was found. Material-seam review passed for these captured conditions.

Before any seam fix: before-seam-fix/. After clip fix but before paint fix: after-clip-fix-before-paint-fix/. Root-directory PNGs and CAPTURE_MANIFEST.json are the final post-paint-fix evidence.

## Source hashes at QA completion

- lib/widgets/sori/approved_games/approved_matching_view.dart: d81cd46a5398d285158bb4c3aee47f7d009abdb9b396072b7458bcba872d064b
- lib/widgets/sori/approved_games/approved_quiz_view.dart: f881a159ac351a68203cf850eab1c57e5ffb6fc54bb0b81c5041b81a44e30ea5
- lib/widgets/sori/approved_games/approved_game_material.dart: 4c1a04fc45383c3cd9739a0f44acf80e9b2fd3e87fa19fb6b855ab45cddfd4fd
- tool/visual_review/approved_game_gallery.dart: 1e973658bf989c7dae7e760ee218d217316c194e097fea371f3d4d2104dfbaf0

## Capture hashes

- quiz-a-safe-area-flutter.png: 77ed91228018501e87825464b66cbf2b7e06dce17ef173096e0451459a064e15
- quiz-b-safe-area-flutter.png: 720d632c00522569984f637d2dcfdbee29d1d1742515f15c12dc26b55eb60289
- quiz-c-safe-area-flutter.png: f0f5c4ba1faf9b626c33b120b64ee7862155a092992ce5fdff63af76407344d8
- matching-a-safe-area-flutter.png: 4787f45009443122f4c56d8f3f010389ccec906b8baf8d72a3b471c66ed3ec7b
- matching-b-safe-area-flutter.png: dff5e8340a78f0f56d32a7cbc10eadcc28bd61dbec56f0b5fd1e8bfdfc388606
- matching-c-safe-area-flutter.png: dcf0ae3ae095f9cf32508389d216a911595b9cfb6df7390e5d323fed99d727d8
