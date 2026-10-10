# C reward implementation: verified scope
2026-10-10. Worktree: `session/yeopjeon-c-mockups-20261009`, unchanged base HEAD `44727c1921b4b7f40748ac0d210d0ca62a094028`. Changes remain local and uncommitted.

## Current native and browser evidence
The app source connects confirmed receipts, content-lesson completion and wallet navigation to native Flutter reward and house routes. The browser at port 8795 renders those same widgets with synthetic wallets and an in-memory purchase callback. Its balances are review data, not account balances.

| Check | Current result |
|---|---|
| Static analysis | 21 changed/new Dart items: no issues; see review-proof/final-native-analysis.log |
| Focused Flutter suite | 60 tests passed; see review-proof/final-native-tests.log |
| Native layout | DE/EN with real fonts at 402×874, 62/34 logical safe areas: normal 100% copy, full220×220 left movie, fixed112-wide earned slot and actions fit without scrolling |
| Production / QA controls | Production has no playback/motion row; QA-only three DE/EN controls have48-high targets. Automatic playback remains active without control nodes |
| CTA interaction | Held/cancelled/released gestures and 200% real text; no cancelled activation, one released activation, press depth and restoration verified |
| Skip/replay | Confirmed amount remains stable; final live-region label is on the nonzero amount area, replay does not repeat credit |
| Actual earning trace | HTML0,1,…,20; wallet70,72,76,79,83,86,89,90;850ms,52 frames,max gap17ms in one foreground run. See final-earning-row-motion.json; this is not physical-device FPS |
| Exact phone preview | Standalone402×874 canvas, no scale/zoom, no viewport-height collapse; window resizing does not change the internal movie size |
| Shared credit clock | Build-time settling is deferred once after the frame; the wallet and sibling goal do not trigger a setState-during-build error |
| HTML state matrix | DE/EN × first/second/support/pending/cap/short/locked: body/main/horizontal overflow 0, target height ≥48, CTA gap 8, bottom safe gap ≥19 |
| 200% review | Real enlarged text, explicitly marked QA mode, readable actions through scroll fallback; normal app text is never silently shrunk |
| Construction flow | Browser preview confirms 90→50 for cost40; next learning gate remains locked and future forms remain hidden |
| Material continuity | One source CTA face with even-odd perimeter/cloud composition at normal, held and expanded heights; no middle seams |
| Movie color | Whole-frame containment, no saturation/grayscale filter on any playing ancestor; original subject RGB preserved in the native lossless derivative |

The 60-test suite covers native receipt safety, layout, actual codec behavior, invalidated media lifetime, CTA touch behavior, shared pressable keyboard behavior and tactile interactions. Earlier 68-test reward, 75-test learning/audio and 37-test content-lesson runs are business-integration history; the suites overlap and must not be added together or treated as current visual approval.

Current reward screenshots are `review-proof/proof-final-native-de.jpg`, `proof-final-native-en.jpg`, `proof-final-html-de.jpg` and `proof-final-html-en.jpg`, each402×874. `proof-final-html-200-en.jpg` is402×1241 and explicitly represents large-text QA. Native CTA normal/pressed/expanded captures and normal house-flow captures remain valid for unchanged components. Older playing/vertical-layout, proof-native, proof-iphone and pair captures are history. Native safe=1 reserves blank system space; no fake OS controls are drawn.

The user reopened the previously disconnected HTML tab. Live DOM and render now confirm viewport402×874, phone402×874, page overflow0, phone overflow0, movie source960×960 withcontain, and only wallet/character/two CTA buttons inside the product canvas. The external Review panel remains available for QA.

## Media provenance
Original MP4 remains unchanged. Alpha processing changes the background alpha only, without color grading or edge RGB correction. The complete original960×960 frame is preserved. Physical-device performance remains unverified.

- 121 frames, 24fps, approximately5.042 seconds.
- Native lossless WebP: 14,719,366 bytes, 5,041ms.
- All 121 native decoded visible RGB frames compared with the original MP4: maximum channel delta0.
- Alpha corners0 in every frame; minimum transparent-pixel share76.543%.
- VP9 WebM uses YUV compression: the pre-encode RGB is unchanged, but exact encoded RGB equality is not claimed.
- Optional native audio is muted initially. Device decode cost and audio synchronization require physical-device checks.

See `media-review/video-alpha-report.json`, `media-review/flutter-media-report.json` and `C_STYLE_CONTRACT.md`.

## Design review and remaining boundary
Three independent AI reviewers completed a final read-only review of current captures and source: app/material design, mobile layout/flow, and motion/media. All found no remaining P0/P1 within the inspected scope. The two visual reviewers checked native DE/EN402×874 and separate HTML200% captures for internal CTA art/text collisions. The motion reviewer checked absent-control guards, the3.583s cue, shared count clock, initial-hidden settlement and media lifetime against source and the saved actual HTML trace; that reviewer did not independently rerun the test suite. Small native/HTML text-rasterization and goal-row height differences remain, so pixel-perfect equivalence is not claimed. This review is separate from executed tests and is not a human usability study. Earlier findings were corrected: mixed materials, joined CTA seams, floating enlarged status dot, duplicate cost, overpromised new house artwork, and a shadow darkening while the coin rises.

Physical iPhone16Pro installation, real safe-area behavior, frame pacing, memory, optional audio synchronization, haptics and VoiceOver/TalkBack remain unverified. Real account/cloud concurrency checks are distinct from the in-memory browser preview. No merge, deployment, release or human approval is claimed. The empty future-Hanok catalogue waits for approved replacement art.
